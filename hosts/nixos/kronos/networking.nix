{
  inputs,
  lib,
  ...
}: let
  lan = {
    matchConfig = {
      Name = "enp2s0";
      PermanentMACAddress = "44:8a:5b:92:2a:02";
    };
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  guests = import ./guests.nix;
  guestConfig = name: inputs.self.nixosConfigurations.${name}.config;
  guestAddress = name: "10.100.${toString guests.${name}.id}.2";

  # Guest → guest paths, read from each destination's own firewall list so the
  # two never disagree. Kronos's traffic never crosses the forward chain, and
  # LAN sources arrive through DNAT below.
  guestPaths = lib.concatLists (lib.mapAttrsToList (dest: _:
    map (path: path // {inherit dest;})
    (lib.filter (path: guests ? ${path.source} && path.source != dest) (guestConfig dest).my.permittedPaths))
  guests);

  # expose = "lan": 192.168.2.62:<backend> is forwarded to the guest.
  lanPorts = lib.concatLists (lib.mapAttrsToList (dest: _:
    lib.concatMap (svc:
      map (proto: {
        inherit dest proto;
        port = svc.backend;
      })
      svc.proto)
    (lib.filter (svc: svc.expose == "lan") (lib.attrValues (guestConfig dest).my.services)))
  guests);

  # Ports Kronos itself answers on the LAN.
  hostPorts = [
    {
      proto = "tcp";
      port = 69;
    }
    {
      proto = "udp";
      port = 5353;
    }
    {
      proto = "udp";
      port = 41641;
    }
  ];
  portKey = p: "${p.proto}/${toString p.port}";

  forwardRule = path: ''
    iifname "vm-${path.source}" oifname "vm-${path.dest}" ip saddr ${path.address} ip daddr ${guestAddress path.dest} ${path.proto} dport ${toString path.port} accept
  '';
  dnatRule = p: ''
    iifname "enp2s0" oifname "vm-${p.dest}" ip saddr 192.168.2.0/24 ip daddr ${guestAddress p.dest} ${p.proto} dport ${toString p.port} ct status dnat accept
  '';
in {
  assertions = [
    {
      assertion = let
        keys = map portKey (lanPorts ++ hostPorts);
      in
        lib.length keys == lib.length (lib.unique keys);
      message = "Two expose = \"lan\" services, or one and Kronos itself, claim the same port on 192.168.2.62.";
    }
  ];

  boot.initrd.systemd.network = {
    enable = true;
    networks."10-lan" = lan;
  };

  networking = {
    hostName = "kronos";
    useDHCP = false;
    useNetworkd = true;

    hosts = lib.mapAttrs' (name: _: lib.nameValuePair (guestAddress name) ["${name}.internal"]) guests;

    nat = {
      enable = true;
      externalInterface = "enp2s0";
      internalIPs = ["10.100.0.0/16"];
      forwardPorts =
        map (p: {
          inherit (p) proto;
          sourcePort = p.port;
          destination = "${guestAddress p.dest}:${toString p.port}";
        })
        lanPorts;
    };

    nftables = {
      enable = true;
      tables.kronos-guests = {
        family = "inet";
        content = ''
          # A packet from a tap addressed to Kronos never reaches the forward
          # chain; only replies to Kronos's own connections may come back.
          chain input {
            type filter hook input priority filter - 10; policy accept;
            iifname "vm-*" ct state established,related accept
            iifname "vm-*" drop
          }

          chain forward {
            type filter hook forward priority filter; policy drop;
            ct state established,related accept
            ct state invalid drop

            ${lib.concatMapStrings forwardRule guestPaths}
            ${lib.concatMapStrings dnatRule lanPorts}
            # Guests reach the internet only: not the parents' LAN, nor any
            # other private network their router can route to.
            iifname "vm-*" ip daddr { 10.0.0.0/8, 100.64.0.0/10, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16 } drop
            iifname "vm-*" oifname "enp2s0" accept
          }
        '';
      };
    };

    firewall = {
      enable = true;
      # Strict reverse-path filtering: a tap only carries its guest's address.
      checkReversePath = "strict";
      # Every host port is scoped to an interface, so none applies on a tap.
      extraInputRules = ''
        iifname "enp2s0" ip saddr 192.168.2.0/24 tcp dport 69 accept
        iifname "enp2s0" ip saddr 192.168.2.0/24 udp dport 60000-61000 accept
        iifname "enp2s0" ip saddr 192.168.2.0/24 udp dport 5353 accept
        iifname "enp2s0" udp dport 41641 accept
      '';
      interfaces.tailscale0 = {
        allowedTCPPorts = [69];
        allowedUDPPortRanges = [
          {
            from = 60000;
            to = 61000;
          }
        ];
      };
    };
  };

  systemd.network.networks =
    {
      "10-lan" = lan;
    }
    // lib.mapAttrs' (name: guest:
      lib.nameValuePair "30-vm-${name}" {
        matchConfig.Name = "vm-${name}";
        address = ["10.100.${toString guest.id}.1/24"];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "no";
      })
    guests;

  services = {
    openssh = {
      enable = true;
      openFirewall = false;
      ports = [69];
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        AllowUsers = ["mkn"];
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Enrolment as tag:host is manual; Kronos uses .internal names and a public
    # resolver, never the tailnet's DNS.
    tailscale = {
      enable = true;
      openFirewall = false;
      extraSetFlags = ["--accept-dns=false"];
    };

    avahi = {
      enable = true;
      openFirewall = false;
      allowInterfaces = ["enp2s0"];
      publish = {
        enable = true;
        addresses = true;
      };
    };
  };
}

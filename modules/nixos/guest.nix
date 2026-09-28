# Shared base for Kronos's microvm guests. Each guest boots from a tmpfs root,
# shares Kronos's /nix/store read-only and keeps state only under /persist:
# a virtiofs share of its state subvolume, or a block volume on Zeus.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  guests = import ../../hosts/nixos/kronos/guests.nix;
  name = config.networking.hostName;
  self = guests.${name};
  cfg = config.my.guest;
  address = host: "10.100.${toString self.id}.${toString host}";
  mac = "02:00:00:00:00:${lib.fixedWidthString 2 "0" (lib.toHexString self.id)}";
  quad9 = [
    "9.9.9.9"
    "149.112.112.112"
  ];
in {
  imports = [
    ./base.nix
    ./secrets.nix
    ./services.nix
    inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.microvm.nixosModules.microvm
  ];

  options.my.guest = {
    ssh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "SSH and mosh for Max over the tailnet.";
    };
    tailscale = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    certificate = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "ts.knerrich.com"
        "zeus.ts.knerrich.com"
      ]);
      default = null;
      description = "Kronos's wildcard certificate shared read-only to /run/certs.";
    };
    nixLd = lib.mkEnableOption "nix-ld for prebuilt Linux binaries (Vite+'s Node, T3 Code)";
  };

  config = lib.mkMerge [
    {
      microvm = {
        hypervisor = "qemu";
        inherit (self) mem vcpu;
        # Idle guests hand free pages back to Kronos.
        balloon = true;
        interfaces = [
          {
            type = "tap";
            id = "vm-${name}";
            inherit mac;
          }
        ];
        shares =
          [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              proto = "virtiofs";
              # virtiofsd's own bind mount would otherwise let a guest write Kronos's store.
              readOnly = true;
            }
          ]
          ++ lib.optional (self ? state) {
            tag = "state";
            source = self.state;
            mountPoint = "/persist";
            proto = "virtiofs";
          }
          ++ lib.optional (cfg.certificate != null) {
            tag = "certs";
            source = "/var/lib/acme/${cfg.certificate}";
            mountPoint = "/run/certs";
            proto = "virtiofs";
            readOnly = true;
          };
        volumes = lib.mapAttrsToList (volume: v: {
          inherit (v) image size mountPoint;
          label = "${name}-${volume}";
        }) (self.volumes or {});
      };

      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/home"
          "/var/lib"
          "/var/log"
        ];
      };

      networking = {
        useNetworkd = true;
        useDHCP = false;
        enableIPv6 = false;
        nameservers = quad9;
        nftables.enable = true;
        firewall.enable = true;
        # Other guests are reached over the routed segment, never the tailnet.
        hosts = lib.mapAttrs' (guest: g: lib.nameValuePair "10.100.${toString g.id}.2" ["${guest}.internal"]) guests;
      };

      systemd.network.networks."10-segment" = {
        matchConfig.MACAddress = mac;
        address = ["${address 2}/24"];
        gateway = [(address 1)];
        dns = quad9;
        networkConfig.LinkLocalAddressing = "no";
      };

      services.openssh = lib.mkIf cfg.ssh {
        enable = true;
        openFirewall = false;
        ports = [22];
        hostKeys = [
          {
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
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

      programs.mosh = lib.mkIf cfg.ssh {
        enable = true;
        openFirewall = false;
      };

      networking.firewall.interfaces.tailscale0 = lib.mkIf cfg.ssh {
        allowedTCPPorts = [22];
        allowedUDPPortRanges = [
          {
            from = 60000;
            to = 61000;
          }
        ];
      };

      # Enrolment is manual (`tailscale up --advertise-tags=tag:guest`); state
      # persists in /var/lib/tailscale. Guests never resolve names via the tailnet.
      services.tailscale = lib.mkIf cfg.tailscale {
        enable = true;
        openFirewall = false;
        extraSetFlags = ["--accept-dns=false"];
      };

      programs.nix-ld = lib.mkIf cfg.nixLd {
        enable = true;
        # Executor's keyring module links libdbus.
        libraries = [pkgs.dbus];
      };

      # The store belongs to Kronos; nothing to optimise here.
      nix.optimise.automatic = lib.mkForce false;

      assertions = [
        {
          assertion = config.services.caddy.enable -> cfg.certificate != null;
          message = "${name}: Caddy needs a certificate shared from Kronos (my.guest.certificate).";
        }
      ];

      services.caddy.globalConfig = ''
        auto_https off
      '';

      system.stateVersion = "26.05";
    }

    (lib.mkIf config.services.caddy.enable {
      users.users.caddy.extraGroups = ["certs"];

      systemd.services.caddy.unitConfig.RequiresMountsFor = ["/run/certs"];

      # virtiofs forwards no inotify events, so pick up renewed certificates
      # daily. The module's reload runs `caddy reload --force`.
      systemd.services.caddy-reload = {
        description = "Reload Caddy to pick up renewed certificates";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.systemd.package}/bin/systemctl reload caddy.service";
        };
      };
      systemd.timers.caddy-reload = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    })
  ];
}

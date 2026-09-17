{...}: let
  lan = {
    matchConfig = {
      Name = "enp2s0";
      PermanentMACAddress = "44:8a:5b:92:2a:02";
    };
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };
in {
  boot.initrd.systemd.network = {
    enable = true;
    networks."10-lan" = lan;
  };

  networking = {
    hostName = "kronos";
    useDHCP = false;
    useNetworkd = true;

    nftables.enable = true;
    firewall = {
      enable = true;
      extraInputRules = ''
        iifname "enp2s0" ip saddr 192.168.2.0/24 tcp dport 69 accept
        iifname "enp2s0" ip saddr 192.168.2.0/24 udp dport 60000-61000 accept
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

  systemd.network.networks."10-lan" = lan;

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
    tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}

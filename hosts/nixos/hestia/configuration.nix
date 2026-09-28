# Hestia: shared services. CLIProxyAPI and Executor for every agent client,
# private DNS for Max's devices, and Caddy in front of them.
{
  config,
  inputs,
  lib,
  ...
}: let
  guests = import ../kronos/guests.nix;
  guestConfig = name: inputs.self.nixosConfigurations.${name}.config;
  tailnet = guest: guests.${guest}.tailnet;
  known = guest: tailnet guest != null;

  # Names default to Hestia; other guests' domains and Zeus's dev domains point
  # at those guests. A guest's records appear once its tailnet address is known.
  records =
    lib.optional (known "hestia") "/ts.knerrich.com/${tailnet "hestia"}"
    ++ lib.optional (known "zeus") "/zeus.ts.knerrich.com/${tailnet "zeus"}"
    ++ lib.concatLists (lib.mapAttrsToList (guest: _:
      lib.optionals (guest != "hestia" && known guest)
      (map (svc: "/${svc.domain}/${tailnet guest}")
        (lib.filter (svc: svc.domain != null) (lib.attrValues (guestConfig guest).my.services))))
    guests);
in {
  imports = [
    ../../../modules/nixos/guest.nix
    ../../../modules/nixos/home.nix
    ./cliproxyapi.nix
    ./executor.nix
  ];

  networking.hostName = "hestia";

  my.guest = {
    certificate = "ts.knerrich.com";
    nixLd = true;
  };

  microvm.shares = [
    {
      tag = "bulk";
      source = "/srv/storage/hestia";
      mountPoint = "/srv/bulk";
      proto = "virtiofs";
    }
  ];

  # Executor runs in mkn's user manager, which must start at boot.
  users.users.${config.my.username}.linger = true;

  # Tailscale split DNS sends ts.knerrich.com here from Max's devices. Guests
  # never query it; they use Quad9 and .internal host entries.
  my.services.dns = {
    backend = 53;
    proto = [
      "udp"
      "tcp"
    ];
    expose = "tailnet";
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      # Authoritative for the private zone only; nothing is forwarded upstream.
      local = "/ts.knerrich.com/";
      address = records;
      no-resolv = true;
      no-hosts = true;
      # systemd-resolved owns 127.0.0.53; listen on every other interface as it appears.
      bind-dynamic = true;
      except-interface = "lo";
    };
  };
}

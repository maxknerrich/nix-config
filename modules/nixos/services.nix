# One declaration per guest service. The guest firewall and Caddy sites are
# derived here; Kronos's forwarding and DNAT, Hestia's DNS records and Hades's
# Gatus checks read the same declarations through the flake, so every consumer
# works from one list of who may reach what.
{
  config,
  lib,
  ...
}: let
  inherit (lib) types;
  guests = import ../../hosts/nixos/kronos/guests.nix;
  segment = id: host: "10.100.${toString id}.${toString host}";
  self = guests.${config.networking.hostName};
  services = config.my.services;

  # lan includes tailnet: DNAT'd services are also reachable from Max's devices.
  reachesTailnet = svc: svc.expose == "tailnet" || svc.expose == "lan";

  # Permitted sources for a backend: the guests it names, Hades for monitoring,
  # Kronos's end of this guest's tap, and the LAN for DNAT'd services (DNAT
  # keeps the original source address).
  sources = svc:
    map (guest: {
      source = guest;
      address = segment guests.${guest}.id 2;
    }) (lib.unique (svc.allowGuests ++ ["hades"]))
    ++ [
      {
        source = "kronos";
        address = segment self.id 1;
      }
    ]
    ++ lib.optional (svc.expose == "lan") {
      source = "lan";
      address = "192.168.2.0/24";
    };

  servicePaths = lib.concatMap (svc:
    lib.concatMap (proto:
      map (src:
        src
        // {
          inherit proto;
          port = svc.backend;
        }) (sources svc))
    svc.proto) (lib.attrValues services);

  # Gatus on Hades checks SSH and HTTPS over the segment; Kronos may open SSH.
  monitoringPaths =
    lib.optionals config.services.openssh.enable (map (src:
      src
      // {
        port = 22;
        proto = "tcp";
      }) [
      {
        source = "hades";
        address = segment guests.hades.id 2;
      }
      {
        source = "kronos";
        address = segment self.id 1;
      }
    ])
    ++ lib.optional config.services.caddy.enable {
      source = "hades";
      address = segment guests.hades.id 2;
      port = 443;
      proto = "tcp";
    };

  tailnetServices = lib.filter reachesTailnet (lib.attrValues services);
  withDomain = lib.filter (svc: svc.domain != null) (lib.attrValues services);
in {
  options.my = {
    services = lib.mkOption {
      default = {};
      description = "Services this guest runs, and who may reach them.";
      type = types.attrsOf (types.submodule ({config, ...}: {
        options = {
          backend = lib.mkOption {
            type = types.port;
            description = "Port the service listens on, on localhost and the segment address.";
          };
          domain = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional HTTPS name; Caddy on :443 serves it to Max's devices.";
          };
          expose = lib.mkOption {
            type = types.enum ["internal" "tailnet" "lan" "public"];
            default = "internal";
            description = "Who outside Kronos may reach the service.";
          };
          allowGuests = lib.mkOption {
            type = types.listOf (types.enum (lib.attrNames guests));
            default = [];
            description = "Guests that may reach the backend over the routed segment.";
          };
          proto = lib.mkOption {
            type = types.listOf (types.enum ["tcp" "udp"]);
            default = ["tcp"];
          };
          caddy = lib.mkOption {
            type = types.lines;
            default = "reverse_proxy localhost:${toString config.backend}";
            description = "Caddy directives for the site, after its certificate.";
          };
        };
      }));
    };

    permittedPaths = lib.mkOption {
      type = types.listOf types.attrs;
      readOnly = true;
      description = ''
        Every source → port this guest accepts on its segment NIC. Kronos
        derives its forward rules from this same list.
      '';
    };
  };

  config = {
    assertions = map (svc: {
      assertion = svc.expose != "public";
      message = "expose = \"public\" needs a Cloudflare Tunnel, which does not exist yet.";
    }) (lib.attrValues services);

    my.permittedPaths = servicePaths ++ monitoringPaths;

    # Segment sources are matched by address: only Kronos routes 10.100.0.0/16
    # and 192.168.2.0/24 to a guest, and WireGuard drops spoofed tailnet sources.
    networking.firewall = {
      extraInputRules =
        lib.concatMapStrings (path: ''
          ip saddr ${path.address} ${path.proto} dport ${toString path.port} accept
        '')
        config.my.permittedPaths;

      interfaces.tailscale0 = {
        allowedTCPPorts =
          lib.optional (lib.any (svc: svc.domain != null) tailnetServices) 443
          ++ map (svc: svc.backend) (lib.filter (svc: svc.domain == null && lib.elem "tcp" svc.proto) tailnetServices);
        allowedUDPPorts = map (svc: svc.backend) (lib.filter (svc: svc.domain == null && lib.elem "udp" svc.proto) tailnetServices);
      };
    };

    services.caddy = lib.mkIf (withDomain != []) {
      enable = true;
      virtualHosts = lib.listToAttrs (map (svc: {
          name = "https://${svc.domain}";
          value.extraConfig = ''
            tls /run/certs/fullchain.pem /run/certs/key.pem
            ${svc.caddy}
          '';
        })
        withDomain);
    };
  };
}

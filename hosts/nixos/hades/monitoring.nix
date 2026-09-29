# Gatus checks every declared service of every guest over the segment, plus
# each guest's SSH and the backup jobs' heartbeats; ntfy carries the alerts.
{
  config,
  inputs,
  lib,
  ...
}: let
  guests = import ../kronos/guests.nix;
  guestConfig = name: inputs.self.nixosConfigurations.${name}.config;
  guestAddress = name: "10.100.${toString guests.${name}.id}.2";

  ntfyPort = config.my.services.ntfy.backend;
  gatusPort = config.my.services.status.backend;

  # Hades publishes and pushes heartbeats with credentials it creates itself;
  # they never leave this guest.
  local = "/var/lib/hades-local";

  alerts = [{type = "ntfy";}];

  serviceChecks = lib.concatLists (lib.mapAttrsToList (guest: _:
    lib.mapAttrsToList (name: svc:
      {
        inherit name alerts;
        group = guest;
        interval = "5m";
      }
      // (
        if svc.domain != null
        then {
          # Resolved through the host entries below, so the real certificate
          # is validated without leaving the segment.
          url = "https://${svc.domain}";
          conditions = [
            "[STATUS] < 500"
            "[CERTIFICATE_EXPIRATION] > 240h"
          ];
        }
        else {
          url = "tcp://${guest}.internal:${toString svc.backend}";
          conditions = ["[CONNECTED] == true"];
        }
      ))
    (guestConfig guest).my.services)
  guests);

  # Zeus's dev-domain wildcard has no declared service; any name under it gets
  # Caddy's 404, which is enough to watch the certificate's expiry.
  zeusCertificate = "certificate.dev.knerrich.tech";
  certificateChecks = [
    {
      inherit alerts;
      name = "dev-certificate";
      group = "zeus";
      url = "https://${zeusCertificate}";
      interval = "1h";
      conditions = [
        "[STATUS] < 500"
        "[CERTIFICATE_EXPIRATION] > 240h"
      ];
    }
  ];

  sshChecks = lib.mapAttrsToList (guest: _: {
    inherit alerts;
    name = "ssh";
    group = guest;
    url = "tcp://${guest}.internal:22";
    interval = "5m";
    conditions = ["[CONNECTED] == true"];
  }) (lib.filterAttrs (guest: _: (guestConfig guest).services.openssh.enable) guests);
in {
  my.services = {
    status = {
      backend = 8080;
      domain = "status.home.knerrich.tech";
      expose = "tailnet";
    };
    ntfy = {
      backend = 2586;
      domain = "ntfy.home.knerrich.tech";
      expose = "tailnet";
    };
  };

  # Every declared domain resolves to its guest's segment address, for Gatus.
  networking.hosts =
    lib.foldlAttrs (hosts: guest: _:
      hosts
      // {
        ${guestAddress guest} =
          lib.mapAttrsToList (_: svc: svc.domain)
          (lib.filterAttrs (_: svc: svc.domain != null) (guestConfig guest).my.services);
      }) {}
    guests
    // {${guestAddress "zeus"} = [zeusCertificate];};

  services.ntfy-sh = {
    enable = true;
    environmentFile = "${local}/ntfy.env";
    settings = {
      base-url = "https://ntfy.home.knerrich.tech";
      listen-http = ":${toString ntfyPort}";
      behind-proxy = true;
      # Max's user and Kronos's write-only publisher are created by hand.
      auth-default-access = "deny-all";
      # Wakes the iPhone through ntfy.sh; message bodies stay on Hades.
      upstream-base-url = "https://ntfy.sh";
    };
  };

  # Hades's own write-only `hades` publisher (for Gatus and the OnFailure
  # hooks) is provisioned declaratively, together with the token for Gatus's
  # heartbeat pushes. Generated before ntfy starts, never leaves Hades.
  systemd.services.hades-local-tokens = {
    description = "Create Hades's local ntfy publisher and heartbeat token";
    before = [
      "ntfy-sh.service"
      "gatus.service"
    ];
    requiredBy = [
      "ntfy-sh.service"
      "gatus.service"
    ];
    path = [config.services.ntfy-sh.package];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      mkdir -p ${local}
      cd ${local}

      test -s ntfy-token || ntfy token generate > ntfy-token
      if ! test -s ntfy-hash; then
        password=$(head -c 32 /dev/urandom | base64)
        printf '%s\n%s\n' "$password" "$password" | ntfy user hash > ntfy-hash
      fi
      test -s gatus-push-token || head -c 32 /dev/urandom | base64 | tr -d '/+=' > gatus-push-token

      printf "NTFY_AUTH_USERS='hades:%s:user'\nNTFY_AUTH_ACCESS='hades:alerts:wo'\nNTFY_AUTH_TOKENS='hades:%s:local'\n" \
        "$(cat ntfy-hash)" "$(cat ntfy-token)" > ntfy.env
      printf 'NTFY_TOKEN=%s\nGATUS_PUSH_TOKEN=%s\n' "$(cat ntfy-token)" "$(cat gatus-push-token)" > gatus.env
    '';
  };

  services.gatus = {
    enable = true;
    environmentFile = "${local}/gatus.env";
    settings = {
      web.port = gatusPort;
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };
      alerting.ntfy = {
        url = "http://127.0.0.1:${toString ntfyPort}";
        topic = "alerts";
        token = "\${NTFY_TOKEN}";
        priority = 4;
        default-alert = {
          send-on-resolved = true;
          failure-threshold = 2;
          success-threshold = 2;
        };
      };
      endpoints = serviceChecks ++ certificateChecks ++ sshChecks;
      # Backup jobs push success; silence past the interval alerts.
      external-endpoints =
        map (job: {
          inherit alerts;
          inherit (job) name;
          group = "backup";
          token = "\${GATUS_PUSH_TOKEN}";
          heartbeat.interval = job.interval;
        }) [
          {
            name = "proton-mirror";
            interval = "3h";
          }
          {
            name = "offsite";
            interval = "26h";
          }
        ];
    };
  };

  my.notify = {
    url = "http://127.0.0.1:${toString ntfyPort}/alerts";
    tokenFile = "${local}/ntfy-token";
  };
}

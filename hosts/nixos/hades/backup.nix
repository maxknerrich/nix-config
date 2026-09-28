# Backup by origin: Fawkes writes to the home repository through the Kopia
# server; Proton Drive is mirrored hourly; Kronos-only guest state goes to the
# offsite repository on IDrive e2 once a day.
{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.my.secrets.hades-kopia-home;
  offsite = config.my.secrets.hades-offsite;

  kopiaEnv = {
    HOME = "/var/lib/kopia";
    KOPIA_CHECK_FOR_UPDATES = "false";
    KOPIA_LOG_DIR = "/var/log/kopia";
  };
  tls = "/var/lib/kopia-tls";

  # Kopia against the offsite repository with credentials from agenix. The
  # connection lives in /run only, so e2 credentials exist nowhere else.
  # `kopia-offsite create` makes the repository once; other arguments go to kopia.
  kopiaOffsite = pkgs.writeShellApplication {
    name = "kopia-offsite";
    runtimeInputs = [pkgs.kopia];
    text = ''
      set -a
      # shellcheck source=/dev/null
      source ${offsite.path}
      set +a
      export HOME=/root KOPIA_CHECK_FOR_UPDATES=false KOPIA_LOG_DIR=/var/log/kopia
      export KOPIA_CONFIG_PATH=/run/kopia-offsite/repository.config
      export KOPIA_CACHE_DIRECTORY=/srv/kopia-home/cache/offsite
      export KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=false
      mkdir -p -m 0700 /run/kopia-offsite

      case "''${1:-}" in
        create | connect)
          exec kopia repository "$1" s3 --bucket="$KOPIA_S3_BUCKET" --endpoint="$KOPIA_S3_ENDPOINT" "''${@:2}"
          ;;
        *) exec kopia "$@" ;;
      esac
    '';
  };

  # Report a job's success to its Gatus heartbeat.
  heartbeat = name:
    "-+"
    + pkgs.writeShellScript "heartbeat-${name}" ''
      ${lib.getExe pkgs.curl} -fsS --max-time 30 -X POST \
        -H "Authorization: Bearer $(cat /var/lib/hades-local/gatus-push-token)" \
        "http://127.0.0.1:${toString config.my.services.status.backend}/api/v1/endpoints/backup_${name}/external?success=true"
    '';
in {
  my.secrets = {
    # KOPIA_PASSWORD (home repository) and KOPIA_SERVER_USER_PASSWORD (mkn@fawkes).
    hades-kopia-home = {};
    # KOPIA_PASSWORD (offsite), AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
    # KOPIA_S3_BUCKET, KOPIA_S3_ENDPOINT.
    hades-offsite = {};
  };

  my.services.kopia = {
    backend = 51515;
    domain = "kopia.ts.knerrich.com";
    expose = "tailnet";
    # Kopia's client protocol is gRPC, so HTTP/2 end to end. Kopia 0.23 serves
    # HTTP/2 only over TLS, so Caddy speaks TLS to it and pins its certificate.
    caddy = ''
      reverse_proxy https://127.0.0.1:51515 {
        transport http {
          versions 2
          tls_trust_pool file ${tls}/cert.pem
        }
      }
    '';
  };

  users = {
    users.kopia = {
      isSystemUser = true;
      group = "kopia";
      home = "/var/lib/kopia";
    };
    groups.kopia = {};
    users.rclone = {
      isSystemUser = true;
      group = "rclone";
      home = "/var/lib/rclone";
    };
    groups.rclone = {};
  };

  environment.systemPackages = [
    pkgs.kopia
    pkgs.rclone
    kopiaOffsite
  ];

  # Repository and caches share the kopia-home subvolume: snapshotted on Kronos
  # for seven days, never sent offsite.
  systemd.tmpfiles.rules = [
    "d /var/lib/kopia 0750 kopia kopia"
    "d ${tls} 0755 kopia kopia"
    "d /var/log/kopia 0750 kopia kopia"
    "d /srv/kopia-home/repository 0750 kopia kopia"
    "d /srv/kopia-home/cache 0755 root root"
    "d /srv/kopia-home/cache/home 0750 kopia kopia"
    "d /var/lib/rclone 0700 rclone rclone"
    "d /srv/proton 0750 rclone rclone"
  ];

  # Starts once Max has created the repository (see the rollout notes).
  systemd.services.kopia-server = {
    description = "Kopia server for Fawkes's home repository";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = [
      "/var/lib/kopia/home.config"
      home.path
    ];
    path = [
      pkgs.kopia
      pkgs.openssl
    ];
    environment = kopiaEnv // {KOPIA_CONFIG_PATH = "/var/lib/kopia/home.config";};
    serviceConfig = {
      User = "kopia";
      Group = "kopia";
      EnvironmentFile = home.path;
      Restart = "on-failure";
    };
    preStart = ''
      # Retention, schedule and compression are repository policies; KopiaUI
      # on Fawkes follows them.
      kopia policy set --global --compression=zstd --snapshot-interval=1h \
        --keep-latest=10 --keep-hourly=0 --keep-daily=30 --keep-weekly=0 --keep-monthly=12 --keep-annual=0

      if kopia server user info mkn@fawkes >/dev/null 2>&1; then
        kopia server user set mkn@fawkes --user-password="$KOPIA_SERVER_USER_PASSWORD"
      else
        kopia server user add mkn@fawkes --user-password="$KOPIA_SERVER_USER_PASSWORD"
      fi

      # Loopback certificate for Caddy's HTTP/2 upstream; Caddy trusts exactly it.
      if ! test -e ${tls}/cert.pem; then
        (umask 077 && openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
          -days 3650 -subj /CN=127.0.0.1 -addext subjectAltName=IP:127.0.0.1 \
          -keyout ${tls}/key.pem -out ${tls}/cert.pem)
        chmod 0644 ${tls}/cert.pem
      fi
    '';
    script = ''
      exec kopia server start --address=127.0.0.1:${toString config.my.services.kopia.backend} \
        --tls-cert-file=${tls}/cert.pem --tls-key-file=${tls}/key.pem
    '';
  };

  # Newest btrbk snapshot of each guest-state subvolume, refused if stale, under
  # a stable source identity.
  systemd.services.kopia-offsite = {
    description = "Snapshot Kronos-only guest state to the offsite repository";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = offsite.path;
    path = [
      kopiaOffsite
      pkgs.coreutils
      pkgs.findutils
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPost = heartbeat "offsite";
    };
    script = ''
      now=$(date +%s)
      kopia-offsite connect
      trap 'kopia-offsite repository disconnect || true' EXIT
      kopia-offsite policy set --global --compression=zstd \
        --keep-latest=1 --keep-hourly=0 --keep-daily=14 --keep-weekly=0 --keep-monthly=6 --keep-annual=0

      for series in hestia-state hades-state hermes-state; do
        latest=$(find /snapshots/$series -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | tail -n 1)
        if test -z "$latest"; then
          echo "no snapshot of $series" >&2
          exit 1
        fi
        # btrbk long-iso names end in .YYYYMMDDTHHMMSS+ZZZZ, optionally _N.
        stamp=''${latest##*.}
        stamp=''${stamp%%_*}
        taken=$(date -d "''${stamp:0:4}-''${stamp:4:2}-''${stamp:6:2} ''${stamp:9:2}:''${stamp:11:2}:''${stamp:13:2} ''${stamp:15}" +%s)
        if test $((now - taken)) -gt $((36 * 3600)); then
          echo "newest $series snapshot $latest is older than 36 h" >&2
          exit 1
        fi
        kopia-offsite snapshot create "/snapshots/$series/$latest" --override-source="root@kronos:/$series"
      done
    '';
  };

  systemd.timers.kopia-offsite = {
    wantedBy = ["timers.target"];
    timerConfig = {
      # After Kronos's btrbk run at 01:30.
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
  };

  # rclone writes each file under a temporary name and renames it, so a failed
  # run leaves whole files; btrbk's daily snapshot of @proton is the history.
  systemd.services.proton-mirror = {
    description = "Mirror Proton Drive";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    # rclone.conf holds the Proton session and is rewritten by rclone.
    unitConfig.ConditionPathExists = "/var/lib/rclone/rclone.conf";
    serviceConfig = {
      Type = "oneshot";
      User = "rclone";
      Group = "rclone";
      ExecStart = "${lib.getExe pkgs.rclone} sync proton: /srv/proton --config=/var/lib/rclone/rclone.conf";
      ExecStartPost = heartbeat "proton-mirror";
    };
  };

  systemd.timers.proton-mirror = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  my.notify.units = [
    "kopia-offsite"
    "proton-mirror"
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.snapraid-btrfs;
in {
  # disable the default snapraid module if snapraid-btrfs is enabled
  disabledModules = ["services/backup/snapraid.nix"];
  imports = [
    # Should have never been on the top-level.
    (lib.mkRenamedOptionModule ["snapraid-btrfs"] ["services" "snapraid-btrfs"])
  ];

  options.services.snapraid-btrfs = with lib.types; {
    enable = lib.mkEnableOption "SnapRAID";
    dataDisks = lib.mkOption {
      default = {};
      example = {
        d1 = "/mnt/disk1/";
        d2 = "/mnt/disk2/";
        d3 = "/mnt/disk3/";
      };
      description = "SnapRAID data disks.";
      type = attrsOf str;
    };
    parityFiles = lib.mkOption {
      default = [];
      example = [
        "/mnt/diskp/snapraid.parity"
        "/mnt/diskq/snapraid.2-parity"
        "/mnt/diskr/snapraid.3-parity"
        "/mnt/disks/snapraid.4-parity"
        "/mnt/diskt/snapraid.5-parity"
        "/mnt/disku/snapraid.6-parity"
      ];
      description = "SnapRAID parity files.";
      type = listOf str;
    };
    contentFiles = lib.mkOption {
      default = [];
      example = [
        "/var/snapraid.content"
        "/mnt/disk1/snapraid.content"
        "/mnt/disk2/snapraid.content"
      ];
      description = "SnapRAID content list files.";
      type = listOf str;
    };
    exclude = lib.mkOption {
      default = [];
      example = [
        "*.unrecoverable"
        "/tmp/"
        "/lost+found/"
      ];
      description = "SnapRAID exclude directives.";
      type = listOf str;
    };
    touchBeforeSync = lib.mkOption {
      default = true;
      example = false;
      description = "Whether {command}`snapraid-btrfs touch` should be run before {command}`snapraid-btrfs sync`.";
      type = bool;
    };
    sync.interval = lib.mkOption {
      default = "01:00";
      example = "daily";
      description = "How often to run {command}`snapraid-btrfs sync`.";
      type = str;
    };
    scrub = {
      interval = lib.mkOption {
        default = "Mon *-*-* 02:00:00";
        example = "weekly";
        description = "How often to run {command}`snapraid-btrfs scrub`.";
        type = str;
      };
      plan = lib.mkOption {
        default = 8;
        example = 5;
        description = "Percent of the array that should be checked by {command}`snapraid-btrfs scrub`.";
        type = int;
      };
      olderThan = lib.mkOption {
        default = 10;
        example = 20;
        description = "Number of days since data was last scrubbed before it can be scrubbed again.";
        type = int;
      };
    };
    extraConfig = lib.mkOption {
      default = "";
      example = ''
        nohidden
        blocksize 256
        hashsize 16
        autosave 500
        pool /pool
      '';
      description = "Extra config options for SnapRAID-BTRFS.";
      type = lines;
    };
    scrubAfterSync = lib.mkOption {
      default = true;
      example = false;
      description = "Whether to run {command}`snapraid-btrfs scrub` after {command}`snapraid-btrfs sync`.";
      type = bool;
    };
    diff = {
      enabled = lib.mkOption {
        default = true;
        example = true;
        description = "Whether to diff before sync.";
        type = bool;
      };
      threshold = lib.mkOption {
        default = 250;
        example = 10;
        description = "abort operation if there are more deletes than this.";
        type = int;
      };
    };
  };

  config = let
    nParity = builtins.length cfg.parityFiles;
    mkPrepend = pre: s: pre + s;
    contentDirs = map (path: builtins.dirOf path) cfg.contentFiles;
  in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = nParity <= 6;
          message = "You can have no more than six SnapRAID parity files.";
        }
        {
          assertion = builtins.length cfg.contentFiles >= nParity + 1;
          message = "There must be at least one SnapRAID content file for each SnapRAID parity file plus one.";
        }
      ];

      environment = {
        systemPackages = with pkgs; [snapraid snapraid-btrfs];

        etc."snapraid.conf" = {
          text = with cfg; let
            prependData = mkPrepend "data ";
            prependContent = mkPrepend "content ";
            prependExclude = mkPrepend "exclude ";
          in
            lib.concatStringsSep "\n" (
              map prependData ((lib.mapAttrsToList (name: value: name + " " + value)) dataDisks)
              ++ lib.zipListsWith (a: b: a + b) (
                ["parity "] ++ map (i: toString i + "-parity ") (lib.range 2 6)
              )
              parityFiles
              ++ map prependContent contentFiles
              ++ map prependExclude exclude
            )
            + "\n"
            + extraConfig;
        };
      };

      systemd.services = with cfg; {
        snapraid-btrfs-scrub = {
          description = "Scrub the SnapRAID array";
          onSuccess = ["tg-notify@%i.service"];
          onFailure = ["tg-notify@%i.service"];
          startAt = scrub.interval;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.snapraid-btrfs}/bin/snapraid-btrfs scrub -p ${toString scrub.plan} -o ${toString scrub.olderThan}";
            Nice = 19;
            IOSchedulingPriority = 7;
            CPUSchedulingPolicy = "batch";

            PrivateTmp = true;
            PrivateDevices = true;
            ProtectSystem = true;
            RestrictNamespaces = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            CapabilityBoundingSet = "CAP_DAC_OVERRIDE CAP_FOWNER CAP_SYS_ADMIN";
            ReadWritePaths = ["/run" "/tmp"] ++ (lib.attrValues cfg.dataDisks ++ contentDirs ++ cfg.parityFiles);
            RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
          };
        };
        snapraid-btrfs-cleanup = {
          description = "Remove all snapshots except the one used for the last sync";
          onFailure = ["tg-notify@%i.service"];
          onSuccess =
            ["tg-notify@%i.service"]
            ++ (lib.optional scrubAfterSync "snapraid-btrfs-scrub.service");
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.snapraid-btrfs}/bin/snapraid-btrfs cleanup";
            Nice = 19;
            IOSchedulingPriority = 7;
            CPUSchedulingPolicy = "batch";

            PrivateTmp = true;
            PrivateDevices = true;
            ProtectSystem = true;
            RestrictNamespaces = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            CapabilityBoundingSet = "CAP_DAC_OVERRIDE CAP_FOWNER CAP_SYS_ADMIN";
            ReadWritePaths = ["/run" "/tmp"] ++ (lib.attrValues cfg.dataDisks ++ contentDirs ++ cfg.parityFiles);
            RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            SuccessExitStatus = ["0"];
          };
        };

        snapraid-btrfs-sync = {
          description = "Synchronize the state of the SnapRAID array";
          startAt = sync.interval;
          # run scrub after sync if enabled
          onFailure = ["tg-notify@%i.service"];
          onSuccess = ["tg-notify@%i.service" "snapraid-btrfs-cleanup.service"];
          wants = lib.optional cfg.diff.enabled "snapraid-btrfs-diff.service";
          after = lib.optional cfg.diff.enabled "snapraid-btrfs-diff.service";
          serviceConfig =
            {
              Type = "oneshot";
              Nice = 19;
              # ExecStart =
              #   lib.mkIf cfg.diff.enabled (
              ExecStart = pkgs.writeShellScript "snapraid-btrfs-sync-with-diff" ''
                set -e
                echo "Running diff before sync..."

                # Capture the diff output to analyze it
                DIFF_OUTPUT=$(${pkgs.snapraid-btrfs}/bin/snapraid-btrfs diff)
                DIFF_STATUS=$?

                echo "$DIFF_OUTPUT"

                # Check if sync is needed (status code 2)
                if [ $DIFF_STATUS -eq 2 ]; then
                  # Count removals from diff output
                  REMOVED_COUNT=$(echo "$DIFF_OUTPUT" | grep -oP '\s+\d+\s+removed' | awk '{print $1}')

                  if [ -n "$REMOVED_COUNT" ] && [ "$REMOVED_COUNT" -gt ${toString cfg.diff.threshold} ]; then
                    echo "ERROR: $REMOVED_COUNT files would be deleted, exceeding threshold of ${toString cfg.diff.threshold}"
                    exit 1
                  fi

                  echo "Diff indicates changes (status $DIFF_STATUS), proceeding with sync..."
                  ${pkgs.snapraid-btrfs}/bin/snapraid-btrfs sync
                elif [ $DIFF_STATUS -eq 0 ]; then
                  echo "No differences detected, no sync required"
                else
                  echo "Diff command failed with status $DIFF_STATUS, aborting"
                  exit 1
                fi
              '';
              # )
              # // lib.mkIf (!cfg.diff.enabled) "${pkgs.snapraid-btrfs}/bin/snapraid-btrfs sync";
              IOSchedulingPriority = 7;
              CPUSchedulingPolicy = "batch";

              PrivateTmp = true;
              PrivateDevices = true;
              ProtectSystem = true;
              RestrictNamespaces = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              CapabilityBoundingSet = "CAP_DAC_OVERRIDE CAP_FOWNER CAP_SYS_ADMIN";
              ReadWritePaths = ["/run" "/tmp"] ++ (lib.attrValues cfg.dataDisks ++ contentDirs ++ cfg.parityFiles);
              RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              NoNewPrivileges = true;
              SuccessExitStatus = ["0"];
            }
            // lib.optionalAttrs touchBeforeSync {
              ExecStartPre = "${pkgs.snapraid-btrfs}/bin/snapraid-btrfs touch";
            };
        };
      };
    };
}

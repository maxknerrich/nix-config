{
  vars,
  lib,
  pkgs,
  ...
}: let
  # Generate the dataDisks set
  dataDisks = builtins.listToAttrs (builtins.map (i: {
    name = "d${toString i}";
    value = "/mnt/data${toString i}";
  }) (builtins.genList (x: x + 1) vars.dataDisks));

  contentFiles = builtins.map (
    i: "/mnt/snapraid-content/data${toString i}/snapraid.content"
  ) (builtins.genList (x: x + 1) vars.dataDisks);

  parityFiles = builtins.map (
    i: "/mnt/parity${toString i}/snapraid.parity"
  ) (builtins.genList (x: x + 1) vars.parityDisks);

  snapperConfigs = builtins.listToAttrs (builtins.map (d: {
      name = "${d.name}";
      value = {
        SUBVOLUME = d.value;
        ALLOW_GROUPS = ["wheel"];
        SYNC_ACL = true;
      };
    })
    (builtins.attrValues (builtins.mapAttrs (name: value: {inherit name value;}) dataDisks)));
in {
  environment.systemPackages = with pkgs; [
    snapraid-btrfs
    snapraid-btrfs-runner
  ];

  services.snapraid = {
    enable = true;
    inherit contentFiles parityFiles dataDisks;
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "downloads/"
      "appdata/"
      "*.!sync"
      "/.snapshots/"
    ];
  };
  services.snapper = {
    configs = snapperConfigs;
  };
  systemd.services.snapraid-btrfs-sync = {
    description = "Run the snapraid-btrfs sync with the runner";
    startAt = ["15:00" "19:25"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
      ExecStart = "+${pkgs.snapraid-btrfs-runner}/bin/snapraid-btrfs-runner";
      Nice = 19;
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "batch";

      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_UNIX";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = "@system-service";
      SystemCallErrorNumber = "EPERM";
      CapabilityBoundingSet = "";
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadOnlyPaths = ["/etc/snapraid.conf" "/etc/snapper"];
      ReadWritePaths =
        # sync requires access to directories containing content files
        # to remove them if they are stale
        let
          contentDirs = builtins.map builtins.dirOf contentFiles;
        in
          lib.unique (
            builtins.attrValues dataDisks ++ parityFiles ++ contentDirs
          );
    };
  };
}

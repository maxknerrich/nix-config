{
  vars,
  lib,
  config,
  pkgs,
  ...
}: let
  # Generate the dataDisks set
  dataDisks = builtins.listToAttrs (builtins.map (i: {
    name = "d${toString i}";
    value = "/mnt/data${toString i}";
  }) (builtins.genList (x: x + 1) vars.dataDisks));

  contentFiles =
    [
      "/var/snapraid/snapraid.content"
    ]
    ++ builtins.map (
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
  systemd.tmpfiles.rules = [
    "f /var/snapraid/snapraid.content 0750 mkn users -" #The - disables automatic cleanup, so the file wont be removed after a period
    "f /var/snapraid/snapraid.content.lock 0750 mkn users -" #The - disables automatic cleanup, so the file wont be removed after a period
  ];
  services.snapraid-btrfs = {
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
    # Configure the sync and scrub schedules here
    sync.interval = "01:00"; # Run sync daily
  };

  services.snapper = {
    configs = snapperConfigs;
  };

  # Configure snapraid-btrfs to override the standard snapraid commands
  # services.snapraid-btrfs = {
  #   enable = true;
  #   # Generate the snapperConfigs list from your dataDisks
  #   snapperConfigs = builtins.attrNames dataDisks;
  #   cleanup = true;
  # };
}

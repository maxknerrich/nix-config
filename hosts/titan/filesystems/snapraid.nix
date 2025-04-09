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

  # TODO: Snapraid BTRFS
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
    # Configure the sync and scrub schedules here
    sync.interval = "00:00"; # Run sync daily
    scrub = {
      plan = 22;
      olderThan = 8;
      interval = "01:00"; # Run scrub daily
    };
  };

  systemd.services = lib.attrsets.optionalAttrs (config.services.snapraid.enable) {
    snapraid-sync = {
      onFailure = lib.lists.optionals (config ? tg-notify && config.tg-notify.enable) [
        "tg-notify@%i.service"
      ];
      serviceConfig = {
        RestrictNamespaces = lib.mkForce false;
        RestrictAddressFamilies = lib.mkForce "";
      };
    };
    snapraid-scrub = {
      onFailure = lib.lists.optionals (config ? tg-notify && config.tg-notify.enable) [
        "tg-notify@%i.service"
      ];
      serviceConfig = {
        RestrictNamespaces = lib.mkForce false;
        RestrictAddressFamilies = lib.mkForce "";
      };
    };
  };

  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -n standby,q";
    extraOptions = [
      "--interval 3600" # Check every hour
    ];
    notifications = {
      wall = {
        enable = true;
      };
      mail = {
        enable = true;
        sender = "titan.local@knerrich.tech";
        recipient = "knerrichmax@gmail.com";
      };
    };
  };

  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      host = "smtp.gmail.com";
      port = 587;
      from = "titan.local@knerrich.tech";
      user = "knerrichmax@gmail.com";
      tls = true;
      passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.googleAppPassword.path}";
    };
  };

  # services.snapper = {
  #   configs = snapperConfigs;
  # };
}

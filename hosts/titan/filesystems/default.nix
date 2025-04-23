{
  vars,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./impermanence.nix
  ];
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
    parted
  ];

  services.fstrim.enable = true;
  services.btrfs = {
    autoScrub = {
      interval = "weekly";
      enable = true;
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

  # systemd.services.hd-idle = {
  #   description = "HDD spin down daemon";
  #   wantedBy = ["multi-user.target"];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''
  #       ${pkgs.hd-idle}/bin/hd-idle -i 0 \
  #           -a /dev/disk/by-id/ata-TOSHIBA_DT01ACA200_Z32UXMXGS -i 600 \
  #           -a /dev/disk/by-id/ata-SAMSUNG_HD103SI_S1VSJDWZ570410 -i 600 \
  #           -a /dev/disk/by-id/ata-ST1000LM014-1EJ164_W7708ZYV   -i 600
  #     '';
  #   };
  # };
}

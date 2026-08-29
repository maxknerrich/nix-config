{pkgs, ...}: {
  imports = [
    ./disko.nix
    ./hardware.nix
    ./impermanence.nix
    ./remote-unlock.nix
    ./networking.nix
    ./virtualisation.nix
  ];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "de";

  users = {
    mutableUsers = false;
    groups.mkn.gid = 1000;
    users.mkn = {
      isNormalUser = true;
      description = "Max Knerrich";
      uid = 1000;
      group = "mkn";
      extraGroups = [
        "kvm"
        "libvirtd"
        "wheel"
      ];
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMU+MXkqxIDEg9IPVCluImSjRByx71QCQdveLQNifwGq Max"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "mkn"
      ];
    };
    channel.enable = false;
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [
        "/nix"
        "/srv/storage"
      ];
    };
    fstrim.enable = true;
    smartd = {
      enable = true;
      autodetect = true;
      defaults.autodetected = "-a -o on -S on -n standby,q";
      extraOptions = ["--interval=3600"];
    };
  };

  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  environment.systemPackages = with pkgs; [
    btop
    ethtool
    git
    pciutils
    smartmontools
    tmux
    usbutils
    vim
  ];

  system.stateVersion = "26.05";
}

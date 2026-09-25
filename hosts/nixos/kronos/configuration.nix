{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../../modules/nixos/base.nix
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disko.nix
    ./hardware.nix
    ./impermanence.nix
    ./remote-unlock.nix
    ./networking.nix
    ./virtualisation.nix
  ];

  users.users.${config.my.username}.extraGroups = [
    "kvm"
    "libvirtd"
  ];

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

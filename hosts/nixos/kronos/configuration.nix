{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  consolePassword = config.my.secrets.kronos-console-password;
  ntfyPort = inputs.self.nixosConfigurations.hades.config.my.services.ntfy.backend;
in {
  imports = [
    ../../../modules/nixos/base.nix
    ../../../modules/nixos/home.nix
    ../../../modules/nixos/notify.nix
    ../../../modules/nixos/secrets.nix
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disko.nix
    ./hardware.nix
    ./impermanence.nix
    ./remote-unlock.nix
    ./networking.nix
    ./virtualisation.nix
    ./certificates.nix
    ./snapshots.nix
  ];

  my.secrets = {
    # Login at the KVM console only; SSH stays key-only.
    kronos-console-password = {};
    # Publish-only token of the `kronos` ntfy user on Hades.
    kronos-ntfy-token = {};
  };

  users.users.${config.my.username} = {
    extraGroups = ["kvm"];
    hashedPasswordFile = lib.mkIf consolePassword.present consolePassword.path;
    hashedPassword = lib.mkIf consolePassword.present (lib.mkForce null);
  };

  my.notify = {
    url = "http://hades.internal:${toString ntfyPort}/alerts";
    tokenFile = config.my.secrets.kronos-ntfy-token.path;
  };

  # Leave CPU for running guests while Kronos builds itself and them.
  nix.settings = {
    max-jobs = 2;
    cores = 2;
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

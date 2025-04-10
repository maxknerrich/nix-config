# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  config,
  lib,
  pkgs,
  ...
}: {
  time.timeZone = "Europe/Berlin";

  imports = [
    ./vscode.nix
  ];

  networking.hostName = "fawkes";
  programs.zsh.enable = true;
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = "mkn";
    startMenuLaunchers = true;
  };
  users.users.mkn = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2tkxTzD2+lfM6QCxJwJFchIggPdzcZhQJjFTaRZvKg max.knerrich@outlook.com"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = config.users.users.mkn.openssh.authorizedKeys.keys;

  services.openssh = {
    enable = true;
    ports = [69];
    settings = {
      # root user is used for remote deployment, so we need to allow it
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
    };
  };
  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}

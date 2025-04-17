{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    keyMap = "de";
  };

  environment = {
    shells = [pkgs.zsh];
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  users.users = {
    root = {
      hashedPasswordFile = config.age.secrets.hashedUserPassword.path;
    };
  };

  services.openssh = {
    enable = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      LoginGraceTime = 0;
      PermitRootLogin = lib.mkDefault "no";
    };
    ports = [69];
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  networking.firewall = {
    enable = lib.mkDefault true;
    allowedTCPPorts = [69];
    allowedUDPPorts = [69];
  };

  programs.git.enable = true;
  programs.htop.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    fastfetch
    tmux
    inputs.agenix.packages."${system}".default
  ];
}

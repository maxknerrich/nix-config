{
  pkgs,
  unstablePkgs,
  lib,
  inputs,
  stateVersion,
  ...
}: let
  inherit (inputs) nixpkgs nixpkgs-unstable;
in {
  time.timeZone = "Europe/Berlin";
  system.stateVersion = stateVersion;

  i18n = {
    defaultLocale = "de_DE.UTF-8";
    supportedLocales = ["de_DE.UTF-8" "en_US.UTF-8"];
  };

  console = {
    keyMap = "de";
    font = "Lat2-Terminus16";
  };

  # home-manager = {
  #     useGlobalPkgs = true;
  #     useUserPackages = true;
  #     users.alex = import ../../../home/alex.nix;
  # };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
    # Automate garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5";
    };
  };

  # environment.systemPackages = with pkgs; [
  #   #
  # ];
}

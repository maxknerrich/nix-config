{...}: let
  home = {
    username = "mkn";
    homeDirectory = "/home/mkn";
    stateVersion = "24.11";
  };
in {
  home = home;

  imports = [
    ../../dots/zsh/default.nix
    ./git.nix
    ./packages.nix
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
}

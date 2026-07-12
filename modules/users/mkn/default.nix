{my, ...}: {
  imports = [
    ./theme.nix
    ./home.nix
    ./cli.nix
    ./host-banner.nix
    ./dots.nix
    ./git.nix
  ];

  home = {
    username = my.username;
    homeDirectory = my.homeDirectory;
    stateVersion = "26.05";
  };

  xdg.enable = true;
  programs = {
    hostBanner.enable = true;
    home-manager.enable = true;
    man.generateCaches = false;
  };
}

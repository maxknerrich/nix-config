{my, ...}: {
  imports = [
    ./home.nix
    ./cli.nix
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
    home-manager.enable = true;
    man.generateCaches = false;
  };
}

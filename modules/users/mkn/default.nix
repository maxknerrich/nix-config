{my, ...}: {
  imports = [
    ./theme.nix
    ./terminal.nix
    ./host-banner.nix
    ./git.nix
    ./pi.nix
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

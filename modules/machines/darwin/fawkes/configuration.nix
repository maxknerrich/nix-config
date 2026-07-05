{config, ...}: {
  imports = [
    ../_common
    ./system.nix
  ];

  my = {
    username = "mkn";
    fullName = "Max Knerrich";
    fullUsername = "maxknerrich";
    email = "max@knerrich.com";
    homeDirectory = "/Users/mkn";
    hostName = "fawkes";
  };

  system = {
    primaryUser = config.my.username;
    stateVersion = 6;
  };

  documentation.enable = false;

  networking = {
    hostName = config.my.hostName;
    computerName = config.my.hostName;
    localHostName = config.my.hostName;
  };
}

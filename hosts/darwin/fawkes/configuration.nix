{config, ...}: {
  imports = [
    ../../../modules/darwin
    ./apps.nix
    ./system.nix
  ];

  home-manager.users.${config.my.username} = import ../../../home/hosts/darwin/fawkes.nix;

  system = {
    primaryUser = config.my.username;
    stateVersion = 6;
  };

  documentation.enable = false;

  networking = {
    hostName = "fawkes";
    computerName = config.networking.hostName;
    localHostName = config.networking.hostName;
  };
}

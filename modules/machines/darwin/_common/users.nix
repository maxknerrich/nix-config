{
  config,
  pkgs,
  ...
}: {
  users.knownUsers = [config.my.username];
  users.users.${config.my.username} = {
    name = config.my.username;
    uid = 501;
    home = config.my.homeDirectory;
    description = config.my.fullName;
    shell = pkgs.fish; # Default login shell.
  };

  programs.fish.enable = true;
}

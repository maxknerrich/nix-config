{
  config,
  pkgs,
  ...
}: {
  users.users.${config.my.username} = {
    name = config.my.username;
    home = config.my.homeDirectory;
    description = config.my.fullName;
    shell = pkgs.fish; # Default login shell.
  };

  programs.fish.enable = true;
}

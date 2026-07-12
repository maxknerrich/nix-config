{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [./nix.nix];

  users = {
    knownUsers = [config.my.username];
    users.${config.my.username} = {
      name = config.my.username;
      uid = 501;
      home = config.my.homeDirectory;
      description = config.my.fullName;
      shell = pkgs.fish;
    };
  };
  programs.fish.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-nix";
    sharedModules = [inputs.determinate.homeManagerModules.default];
    extraSpecialArgs = {
      inherit inputs;
      my = config.my;
    };
    users.${config.my.username} = import ../../../users/mkn;
  };
}

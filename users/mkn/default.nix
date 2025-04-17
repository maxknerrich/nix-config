{
  config,
  pkgs,
  ...
}: {
  nix.settings.trusted-users = ["mkn"];

  users = {
    users = {
      mkn = {
        isNormalUser = true;
        description = "Max";
        uid = 1000;
        shell = pkgs.zsh;
        group = "mkn";
        hashedPasswordFile = config.age.secrets.hashedUserPassword.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2tkxTzD2+lfM6QCxJwJFchIggPdzcZhQJjFTaRZvKg max.knerrich@outlook.com"
        ];
        # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
        extraGroups = ["wheel" "networkmanager" "video"];
      };
    };
    groups = {
      mkn = {
        gid = 1000;
      };
    };
  };
  home-manager.users.mkn.imports = [
    ./home.nix
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  programs.zsh.enable = true;
}

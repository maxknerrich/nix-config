{
  config,
  inputs,
  pkgs,
  ...
}: {
  nix.settings.trusted-users = ["mkn"];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.mkn = {imports = [./../../home/mkn.nix];};
  users = {
    users = {
      mkn = {
        isNormalUser = true;
        extraGroups = ["wheel" "podman" "render" "video"];
        groups = "mkn";
        uid = 1000;
        hashedPassword = "$6$8vCdBRvC7OxmyZ/I$5GVwEMJVtJ87I4GJnb2xkadsAovhaB2a0.jY2hto.yfr8JcEopvNwCQi0Nnn3lgzPUx4i9MdvpguRcbgR99JG0";
        openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2tkxTzD2+lfM6QCxJwJFchIggPdzcZhQJjFTaRZvKg max.knerrich@outlook.com"];
        packages = with pkgs; [
          home-manager
        ];
      };
    };
    groups = {
      notthebee = {
        gid = 1000;
      };
    };
  };
  programs.zsh.enable = true;
  programs.zsh.interactiveShellInit = "echo \"\" \n figurine -f \"3d.flf\" $(hostname)}";
}

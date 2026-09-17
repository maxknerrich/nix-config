{config, ...}: {
  imports = [../common/identity.nix];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "de";

  users = {
    mutableUsers = false;
    groups.${config.my.username}.gid = 1000;
    users.${config.my.username} = {
      isNormalUser = true;
      description = config.my.fullName;
      home = config.my.homeDirectory;
      uid = 1000;
      group = config.my.username;
      extraGroups = ["wheel"];
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMU+MXkqxIDEg9IPVCluImSjRByx71QCQdveLQNifwGq Max"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        config.my.username
      ];
    };
    channel.enable = false;
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };
}

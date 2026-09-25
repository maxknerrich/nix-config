{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "mkn";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Max Knerrich";
    };
    fullUsername = lib.mkOption {
      type = lib.types.str;
      default = "maxknerrich";
      description = "Long-lived online handle.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "max@knerrich.com";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/Users"
        else "/home"
      }/${config.my.username}";
    };
    hostName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
    };
  };
}

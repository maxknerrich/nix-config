{
  config,
  lib,
  ...
}: {
  options.my = {
    username = lib.mkOption {type = lib.types.str;};
    fullName = lib.mkOption {type = lib.types.str;};
    fullUsername = lib.mkOption {type = lib.types.str;}; # Long-lived online handle.
    email = lib.mkOption {type = lib.types.str;};
    homeDirectory = lib.mkOption {type = lib.types.str;};
    hostName = lib.mkOption {type = lib.types.str;};
  };

  config = {
    determinateNix = {
      enable = true;
      # Determinate Nix owns nix.conf, so use customSettings instead of nix.settings.
      customSettings = {
        trusted-users = [
          "root"
          config.my.username
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        max-jobs = "auto";
        cores = 0; # Let Nix choose cores per build.
        keep-outputs = true; # Keep build outputs for better cache reuse.
        keep-derivations = true; # Needed to rebuild retained outputs.
      };
      determinateNixd.garbageCollector.strategy = "automatic"; # Let Determinate clean the store.
    };

    nixpkgs.config.allowUnfree = true; # Required by several GUI/CLI packages.
  };
}

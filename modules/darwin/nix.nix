{
  config,
  inputs,
  ...
}: {
  imports = [inputs.determinate.darwinModules.default];

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
}

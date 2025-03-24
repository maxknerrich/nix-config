{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.cockpit;
in {
  config.services.cockpit = mkIf cfg.enable {
    # package = pkgs.cockpit.overrideAttrs (old: {
    #   # remove packagekit and selinux, don't work on NixOS
    #   postBuild = ''
    #     ${old.postBuild}

    #     rm -rf \
    #       dist/packagekit \
    #       dist/selinux
    #   '';
    # });
    package = pkgs.cockpit.overrideAttrs (old: {
      _ = builtins.trace "Available attrs: ${toString (builtins.attrNames old)}" null;
      postPatch = ''
        ${old.postPatch}

        # Remove problematic components after the build
        mkdir -p $out
        [ -d dist ] && rm -rf dist/packagekit dist/selinux || true
      '';
    });
    port = mkDefault 9090;
    openFirewall = mkDefault false;
    settings = {
      WebService = {
        AllowUnencrypted = true;
        # Origins = builtins.concatStringsSep " " [
        #   "http://${config.networking.hostName}:${toString config.services.cockpit.port}"
        #   "https://${config.networking.hostName}:${toString config.services.cockpit.port}"
        #   "http://localhost:${toString config.services.cockpit.port}"
        #   "https://localhost:${toString config.services.cockpit.port}"
        # ];
        Origins = builtins.concatStringsSep " " [
          "http://${config.networking.hostName}.local.knerrich.tech:${toString config.services.cockpit.port}"
          "http://localhost:${toString config.services.cockpit.port}"
        ];
      };
    };
  };

  config.environment = mkIf cfg.enable {
    systemPackages = with pkgs; [
      # nur.repos.procyon.cockpit-podman # TODO replace only if server runs pods
      # nur.repos.dukzcry.cockpit-machines # TODO enable with virtualisation on server
      # nur.repos.dukzcry.cockpit-client
      # nur.repos.dukzcry.libvirt-dbus # TODO enable with virtualisation on server
      cockpit-benchmark
      cockpit-file-sharing
      cockpit-files
      # cockpit-sensors # Currently not working
    ];
  };
}

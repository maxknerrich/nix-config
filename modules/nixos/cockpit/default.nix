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
    package = pkgs.cockpit.overrideAttrs (old: {
      # remove packagekit and selinux, don't work on NixOS
      postBuild = ''
        ${old.postBuild}

        rm -rf \
          dist/packagekit \
          dist/selinux
      '';
    });
  };

  config.environment = mkIf cfg.enable {
    systemPackages = with pkgs; [
      # nur.repos.procyon.cockpit-podman # TODO replace only if server runs pods
      nur.repos.dukzcry.cockpit-machines # TODO enable with virtualisation on server
      nur.repos.dukzcry.cockpit-client
      # nur.repos.dukzcry.libvirt-dbus # TODO enable with virtualisation on server
      cockpit-benchmark
      cockpit-file-sharing
      cockpit-files
      # cockpit-sensors # Currently not working
    ];
  };
}

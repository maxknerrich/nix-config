{
  config,
  inputs,
  lib,
  ...
}: let
  guests = import ./guests.nix;
  guestConfig = name: inputs.self.nixosConfigurations.${name}.config;

  # Host directories a guest's storage lives on; the guest must not start on an
  # empty mountpoint if a disk is missing.
  storageOf = name:
    [config.microvm.stateDir]
    ++ map (share: share.source) (lib.filter (share: share.source != "/nix/store") (guestConfig name).microvm.shares);
in {
  imports = [inputs.microvm.nixosModules.host];

  # Guests are the flake's nixosConfigurations, built with Kronos and staged on
  # every deploy. Changed guests restart into their new configuration, except
  # Zeus, which keeps running until `just restart zeus`.
  microvm.vms =
    lib.mapAttrs (name: _: {
      evaluatedConfig = inputs.self.nixosConfigurations.${name};
      restartIfChanged = name != "zeus";
    })
    guests;

  # QEMU runs as `microvm` and creates Zeus's store image in the nested
  # subvolume disko made; `v` also makes it a subvolume if it is missing.
  systemd.tmpfiles.rules = ["v ${config.microvm.stateDir}/zeus/scratch 0775 microvm kvm -"];

  systemd.services =
    lib.concatMapAttrs (name: _: let
      certificate = (guestConfig name).my.guest.certificate;
      storage = {unitConfig.RequiresMountsFor = storageOf name;};
    in {
      "microvm-virtiofsd@${name}" = storage;
      # Preliminary self-signed certificates exist before a guest's Caddy starts.
      "microvm@${name}" = lib.mkMerge [
        storage
        (lib.mkIf (certificate != null) {
          wants = ["acme-${certificate}.service"];
          after = ["acme-${certificate}.service"];
        })
      ];
    })
    guests;
}

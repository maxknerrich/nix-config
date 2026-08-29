{...}: {
  boot.tmp.cleanOnBoot = true;

  # Reset root after resume detection but before systemd mounts the real root.
  boot.initrd.systemd.services.rollback-root = {
    description = "Reset the ephemeral Btrfs root subvolume";
    wantedBy = ["initrd-root-fs.target"];
    requiredBy = ["sysroot.mount"];
    before = ["sysroot.mount"];
    after = [
      "dev-disk-by\\x2dlabel-rpool.device"
      "systemd-hibernate-resume.service"
    ];
    requires = ["dev-disk-by\\x2dlabel-rpool.device"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu

      marker=/run/kronos-root-rollback.done
      if test -e "$marker"; then
        exit 0
      fi

      mountpoint=/run/kronos-root
      mkdir -p "$mountpoint"
      mount -t btrfs -o subvol=/,degraded /dev/disk/by-label/rpool "$mountpoint"
      trap 'umount "$mountpoint"' EXIT

      if ! btrfs subvolume show "$mountpoint/@root-blank" >/dev/null 2>&1; then
        echo "Missing @root-blank; refusing to reset root" >&2
        exit 1
      fi

      if btrfs subvolume show "$mountpoint/@root" >/dev/null 2>&1; then
        btrfs subvolume delete -R "$mountpoint/@root"
      fi

      btrfs subvolume snapshot "$mountpoint/@root-blank" "$mountpoint/@root"
      touch "$marker"
    '';
  };

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/timers"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}

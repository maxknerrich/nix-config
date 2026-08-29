{lib, ...}: let
  sandisk = "ata-SanDisk_SSD_PLUS_240GB_24313W802439";
  intel = "ata-INTEL_SSDSC2BA200G3_BTTV5335017Q200GGN";
  hdd1 = "ata-OOS20000G_0004CEZ2";
  hdd2 = "ata-OOS20000G_0004TSQR";

  luksPasswordFile = "/tmp/kronos-luks.key";
  luksSettings = {
    crypttabExtraOpts = ["password-cache=yes"];
  };
  luksSsdSettings =
    luksSettings
    // {
      allowDiscards = true;
    };

  ssdMountOptions = [
    "compress-force=zstd:3"
    "noatime"
    "degraded"
  ];
  hddMountOptions = [
    "compress=zstd:3"
    "noatime"
    "degraded"
    "nofail"
    "x-systemd.device-timeout=10s"
  ];
  bootMountOptions = [
    "umask=0077"
    "nofail"
    "x-systemd.device-timeout=10s"
  ];
in {
  disko.devices.disk = {
    a-ssd-sandisk = {
      type = "disk";
      device = "/dev/disk/by-id/${sandisk}";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 1;
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = bootMountOptions;
            };
          };
          swap = {
            priority = 2;
            size = "24G";
            type = "8309";
            content = {
              type = "luks";
              name = "cryptswap";
              passwordFile = luksPasswordFile;
              settings = luksSsdSettings;
              content = {
                type = "swap";
                discardPolicy = "both";
                priority = 10;
                resumeDevice = true;
                mountOptions = [
                  "nofail"
                  "x-systemd.device-timeout=10s"
                ];
              };
            };
          };
          rpool = {
            priority = 3;
            size = "100%";
            type = "8309";
            content = {
              type = "luks";
              name = "rpool-sandisk";
              passwordFile = luksPasswordFile;
              settings = luksSsdSettings;
            };
          };
        };
      };
    };

    b-ssd-intel = {
      type = "disk";
      device = "/dev/disk/by-id/${intel}";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 1;
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot-fallback";
              mountOptions = bootMountOptions;
            };
          };
          rpool = {
            priority = 2;
            size = "100%";
            type = "8309";
            content = {
              type = "luks";
              name = "rpool-intel";
              passwordFile = luksPasswordFile;
              settings = luksSsdSettings;
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L rpool"
                  "-d raid1"
                  "-m raid1"
                  "/dev/mapper/rpool-sandisk"
                ];
                postCreateHook = ''
                  MNTPOINT=$(mktemp -d)
                  mount "$device" "$MNTPOINT" -o subvol=/
                  trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT

                  if ! btrfs subvolume show "$MNTPOINT/@root-blank" >/dev/null 2>&1; then
                    btrfs subvolume snapshot -r "$MNTPOINT/@root" "$MNTPOINT/@root-blank"
                  fi
                '';
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = ssdMountOptions;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ssdMountOptions;
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = ssdMountOptions;
                  };
                  "@vms" = {
                    mountpoint = "/var/lib/libvirt";
                    mountOptions = ssdMountOptions;
                  };
                  "@apps" = {
                    mountpoint = "/srv/apps";
                    mountOptions = ssdMountOptions;
                  };
                  "@cache" = {
                    mountpoint = "/var/cache";
                    mountOptions = ssdMountOptions;
                  };
                };
              };
            };
          };
        };
      };
    };

    c-hdd-1 = {
      type = "disk";
      device = "/dev/disk/by-id/${hdd1}";
      content = {
        type = "gpt";
        partitions.dtank = {
          priority = 1;
          size = "100%";
          type = "8309";
          content = {
            type = "luks";
            name = "dtank-1";
            passwordFile = luksPasswordFile;
            settings = luksSettings;
          };
        };
      };
    };

    d-hdd-2 = {
      type = "disk";
      device = "/dev/disk/by-id/${hdd2}";
      content = {
        type = "gpt";
        partitions.dtank = {
          priority = 1;
          size = "100%";
          type = "8309";
          content = {
            type = "luks";
            name = "dtank-2";
            passwordFile = luksPasswordFile;
            settings = luksSettings;
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L dtank"
                "-d raid1"
                "-m raid1"
                "/dev/mapper/dtank-1"
              ];
              subvolumes = {
                "@storage" = {
                  mountpoint = "/srv/storage";
                  mountOptions = hddMountOptions;
                };
                "@snapshots" = {
                  mountpoint = "/srv/snapshots/storage";
                  mountOptions = hddMountOptions;
                };
              };
            };
          };
        };
      };
    };
  };

  # Mount by filesystem label so either RAID1 member can be discovered first.
  fileSystems =
    lib.genAttrs [
      "/"
      "/nix"
      "/persist"
      "/var/lib/libvirt"
      "/srv/apps"
      "/var/cache"
    ] (_: {device = lib.mkForce "/dev/disk/by-label/rpool";})
    // lib.genAttrs [
      "/srv/storage"
      "/srv/snapshots/storage"
    ] (_: {device = lib.mkForce "/dev/disk/by-label/dtank";});
}

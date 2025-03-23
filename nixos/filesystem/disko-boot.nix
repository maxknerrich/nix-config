let
  ROOT_DISK_1 = "ata-SanDisk_SSD_PLUS_240GB_24313W802439"; # CHANGE THESE
  ROOT_DISK_2 = "ata-INTEL_SSDSC2BA200G3_BTTV5335017Q200GGN"; # CHANGE THESE
in {
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/${ROOT_DISK_1}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efis/${ROOT_DISK_1}-part2";
              };
            };
            bpool = {
              size = "4G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };
            rpool = {
              end = "-1M";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            bios = {
              size = "100%";
              type = "EF02";
            };
          };
        };
      };
      mirror = {
        device = "/dev/disk/by-id/${ROOT_DISK_2}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efis/${ROOT_DISK_2}-part2";
              };
            };
            bpool = {
              size = "4G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };
            rpool = {
              end = "-1M";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            bios = {
              size = "100%";
              type = "EF02";
            };
          };
        };
      };
    };
    zpool = {
      bpool = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
          compatibility = "grub2";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          devices = "off";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/boot";
        datasets = {
          nixos = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/boot";
          };
        };
      };
      rpool = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/";
        datasets = {
          nixos = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/nixos/empty@start";
          };
          "nixos/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          "nixos/var/log" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/log";
          };
          "nixos/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib";
          };
          "nixos/config" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/etc/nixos";
          };
          "nixos/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
          "nixos/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          docker = {
            type = "zfs_volume";
            size = "50G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib/containers";
            };
          };
        };
      };
    };
  };
}

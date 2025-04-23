{...}: let
  id-ssd-1 = "ata-SanDisk_SSD_PLUS_240GB_24313W802439";
  id-ssd-2 = "ata-INTEL_SSDSC2BA200G3_BTTV5335017Q200GGN";
  id-hdd-1 = "ata-OOS20000G_0004CEZ2";
  id-hdd-2 = "ata-OOS20000G_0004TSQR";
in {
  disko.devices = {
    disk = {
      # Root pool disks
      ssd-1 = {
        type = "disk";
        device = "/dev/disk/by-id/${id-ssd-1}";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["uid=0" "gid=0" "fmask=0077" "dmask=0077"];
              };
            };
            swap = {
              size = "24G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true; # Enable hibernation from this device
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
              };
            };
          };
        };
      };
      ssd-2 = {
        type = "disk";
        device = "/dev/disk/by-id/${id-ssd-2}";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-m raid1 -d raid1"
                  "/dev/disk/by-id/${id-ssd-1}-part3"
                  "-L rpool"
                ];
                subvolumes = {
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress-force=zstd:3" "noatime" "ssd"];
                  };
                  "@persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = ["compress-force=zstd:3" "noatime" "ssd"];
                  };
                  "@snapshots" = {
                    mountpoint = "/mnt/snapshots/root";
                    mountOptions = ["compress-force=zstd:3" "noatime" "ssd"];
                  };
                };
              };
            };
          };
        };
      };

      # Data pool disks, uncomment in setup if you don't need partioning
      hdd-1 = {
        type = "disk";
        device = "/dev/disk/by-id/${id-hdd-1}";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "btrfs";
            };
          };
        };
      };
      hdd-2 = {
        type = "disk";
        device = "/dev/disk/by-id/${id-hdd-2}";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-m raid1 -d raid1"
                "/dev/disk/by-id/${id-hdd-1}-part1"
                "-L dtank"
              ];
              subvolumes = {
                "@data" = {
                  mountpoint = "/mnt/storage";
                  mountOptions = ["nofail" "compress-force=zstd:5" "noatime"];
                };
                "@snapshots" = {
                  mountpoint = "/mnt/snapshots/data";
                  mountOptions = ["nofail" "compress-force=zstd:5" "noatime"];
                };
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "relatime"
          "size=25%"
          "mode=755"
        ];
      };
    };
  };
}

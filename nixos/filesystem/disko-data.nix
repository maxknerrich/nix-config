let
  DATA_DISK_1 = "ata-ST1000LM014-1EJ164_W7708ZYV"; # CHANGE THESE
  DATA_DISK_2 = "ata-SAMSUNG_HD103SI_S1VSJDWZ570410"; # CHANGE THESE

  PARITY_DISK_1 = "ata-TOSHIBA_DT01ACA200_Z32UXMXGS"; # CHANGE THESE
in {
  disko.devices = {
    disk = {
      ${DATA_DISK_1} = {
        device = "/dev/disk/by-id/${DATA_DISK_1}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              label = "disk1";
              name = "disk1";
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/@data" = {
                    mountpoint = "/mnt/disks1";
                    mountOptions = ["subvol=@data"];
                  };
                  "/@content" = {
                    mountpoint = "/mnt/snapraid-content/disk1";
                    mountOptions = ["subvol=@content"];
                  };
                  "/@snapshots" = {
                    mountpoint = "/mnt/disk1/.snapshots";
                    mountOptions = ["subvol=@snapshots"];
                  };
                };
              };
            };
          };
        };
      };
      ${DATA_DISK_2} = {
        device = "/dev/disk/by-id/${DATA_DISK_2}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              label = "disk2";
              name = "disk2";
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/@data" = {
                    mountpoint = "/mnt/disks2";
                    mountOptions = ["subvol=@data"];
                  };
                  "/@content" = {
                    mountpoint = "/mnt/snapraid-content/disk2";
                    mountOptions = ["subvol=@content"];
                  };
                  "/@snapshots" = {
                    mountpoint = "/mnt/disk2/.snapshots";
                    mountOptions = ["subvol=@snapshots"];
                  };
                };
              };
            };
          };
        };
      };
      ${PARITY_DISK_1} = {
        device = "/dev/disk/by-id/${PARITY_DISK_1}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            parity0 = {
              label = "parity1";
              name = "parity1";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                extraArgs = ["-m 0" "-T largefile4"];
                mountpoint = "/mnt/parity1";
              };
            };
          };
        };
      };
    };
  };
}

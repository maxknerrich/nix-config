let
  DATA_DISK_1 = "/dev/sda"; # CHANGE THESE
  DATA_DISK_2 = "/dev/sdd"; # CHANGE THESE

  PARITY_DISK_1 = "/dev/sdc"; # CHANGE THESE
in {
  disko.devices = {
    disk = {
      ${DATA_DISK_1} = {
        device = "${DATA_DISK_1}";
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
        device = "${DATA_DISK_2}";
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
        device = "${PARITY_DISK_1}";
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

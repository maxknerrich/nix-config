let
  DATA_DISK_1 = "/dev/vda"; # CHANGE THESE
  DATA_DISK_2 = "/dev/vda"; # CHANGE THESE

  PARITY_DISK_1 = "/dev/vda"; # CHANGE THESE
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
              label = "data";
              name = "data";
              size = "100%";
              content = {
                type = "btrfs";
                mountpoint = "/mnt/disks1";
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
              label = "data";
              name = "data";
              size = "100%";
              content = {
                type = "btrfs";
                mountpoint = "/mnt/disks2";
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
                type = "ext4";
                extraArgs = ["-m 0" "-T largefile 4"];
                mountpoint = "/mnt/parity1";
              };
            };
          };
        };
      };
    };
  };
}

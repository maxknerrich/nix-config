{
  disko.devices = {
    disk = {
      mainDisk = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_SSDPEKKF256G8L_BTHH85041C3R256B";
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
              size = "10G";
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
                extraArgs = [
                  "-f"
                ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["noatime"];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  snapshots = {
                    mountpoint = "/snapshots";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

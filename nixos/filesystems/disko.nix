{
  # Not needed as no impermanence is configured
  # fileSystems = {
  #   "/nix/state".neededForBoot = true;
  #   "/nix".neededForBoot = true;
  #   # "/mnt/emp-next".options = [ "nofail" ];
  #   # "/mnt/emp-staging".options = [ "nofail" ];
  # };

  disko.devices = let
    mainDisk = "ata-SanDisk_SSD_PLUS_240GB_24313W802439";
    # Currently not used as no impermanence is configured
    # postCreateHook = ''
    #   MNTPOINT=$(mktemp -d)
    #   mount "/dev/disk/by-partlabel/rpool2" "$MNTPOINT" -o subvol=/
    #   trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
    #   btrfs subvolume snapshot -r $MNTPOINT/@root $MNTPOINT/@root-blank
    # '';
    rootSsd = id: {
      type = "disk";
      device = "/dev/disk/by-id/${id}";
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
    poolSsd = id: {
      type = "disk";
      device = "/dev/disk/by-id/${id}";
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
                "/dev/disk/by-id/${mainDisk}-part3"
                "-L rpool"
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
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        };
      };
    };
    dataHdd = idx: id: {
      type = "disk";
      device = "/dev/disk/by-id/${id}";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes = {
              "@data" = {
                mountpoint = "/mnt/data${builtins.toString idx}";
              };
              "@content" = {
                mountpoint = "/mnt/snapraid-content/data${builtins.toString idx}";
              };
              "@snapshots" = {
                mountpoint = "/mnt/snapshots/data${builtins.toString idx}";
              };
            };
          };
        };
      };
    };
    parityHdd = idx: id: {
      type = "disk";
      device = "/dev/disk/by-id/${id}";
      content = {
        type = "gpt";
        partitions.parity = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = ["-m 0" "-T largefile4"];
            mountpoint = "/mnt/parity${builtins.toString idx}";
          };
        };
      };
    };
  in {
    disk = {
      # Root pool disks
      ssd1 = rootSsd mainDisk;
      ssd2 = poolSsd "ata-INTEL_SSDSC2BA200G3_BTTV5335017Q200GGN";

      # Data pool disks, uncomment in setup if you don't need partioning
      hdd-1 = dataHdd 1 "ata-ST1000LM014-1EJ164_W7708ZYV";
      hdd-2 = dataHdd 2 "ata-SAMSUNG_HD103SI_S1VSJDWZ570410";
      hdd-3 = parityHdd 1 "ata-TOSHIBA_DT01ACA200_Z32UXMXGS";
    };
  };
}

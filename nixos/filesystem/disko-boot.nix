let
  ROOT_DISK_1 = "/dev/vda"; # CHANGE THESE
  ROOT_DISK_2 = "/dev/vdb"; # CHANGE THESE
in {
  disko.devices = {
    disk = {
      ${ROOT_DISK_1} = {
        device = "${ROOT_DISK_1}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "EFI";
              name = "ESP";
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            swap = {
              label = "swap";
              size = "4G"; # SWAP - Do not Delete this comment
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              label = "rpool";
              name = "btrfs";
              size = "100%";
              content = {
                type = "btrfs";
              };
            };
          };
        };
      };
      ${ROOT_DISK_2} = {
        device = "${ROOT_DISK_2}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            root = {
              label = "rpool";
              name = "btrfs";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f" "-m raid1 -d raid1" "${ROOT_DISK_1}"];
                subvolumes = {
                  "/@root" = {
                    mountpoint = "/";
                    mountOptions = ["subvol=@root" "compress=zstd" "noatime"];
                  };
                  "/@home" = {
                    mountpoint = "/home";
                    mountOptions = ["subvol=@home" "compress=zstd" "noatime"];
                  };
                  "/@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["subvol=@nix" "compress=zstd" "noatime"];
                  };
                  "/@persist" = {
                    mountOptions = ["subvol=@persist" "compress=zstd" "noatime"];
                    mountpoint = "/persist";
                  };
                  "/@log" = {
                    mountOptions = ["subvol=@log" "compress=zstd" "noatime"];
                    mountpoint = "/var/log";
                  };
                };
                postCreateHook = ''
                  mount "/dev/disk/by-label/system" "$MNTPOINT" -o subvol=/
                  trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                  btrfs subvolume snapshot -r $MNTPOINT/@root $MNTPOINT/@root-blank
                '';
              };
            };
          };
        };
      };
    };
  };
}

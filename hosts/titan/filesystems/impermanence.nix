{
  impermanence,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    # `sudo ncdu -x /`

    pkgs.ncdu
  ];

  boot.tmp.cleanOnBoot = true;
  fileSystems."/persistent".neededForBoot = true;

  # There are two ways to clear the root filesystem on every boot:

  ##  1. use tmpfs for /

  ##  2. (btrfs/zfs only)take a blank snapshot of the root filesystem and revert to it on every boot via:

  ##  3. boot.initrd.postDeviceCommands = ''

  ##       mkdir -p /run/mymount

  ##       mount -o subvol=/ /dev/disk/by-uuid/UUID /run/mymount

  ##       btrfs subvolume delete /run/mymount

  ##       btrfs subvolume snapshot / /run/mymount

  ##     '';

  #

  #  See also https://grahamc.com/blog/erase-your-darlings/

  environment.persistence."/persistent" = {
    # sets the mount option x-gvfs-hide on all the bind mounts

    # to hide them from the file manager

    hideMounts = true;

    directories = [
      "/etc/NetworkManager/system-connections"

      "/etc/ssh"

      "/etc/nix/inputs"

      # my files

      "/etc/agenix/"

      "/var/log"

      "/var/lib"

      # created by modules/nixos/fhs-fonts.nix

      # for flatpak apps

      # "/usr/share/fonts"

      # "/usr/share/icons"
    ];

    files = [
      "/etc/machine-id"
    ];

    users.mkn = {
      directories = [
        "nix-config"

        {
          directory = ".ssh";

          mode = "0700";
        }

        ".cache"
        ".config"
        ".local"
        ".zplug"
      ];

      files = [
        ".wakatime.cfg"

        ".wakatime.bdb"
      ];
    };
  };
}

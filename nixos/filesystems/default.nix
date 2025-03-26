{
  vars,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./snapraid.nix
    # ./swap.nix # TODO
  ];
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
    parted
  ];

  fileSystems.${vars.slowArray} = {
    device = "/mnt/data*";
    options = [
      "defaults"
      "allow_other"
      "moveonenospc=1"
      "minfreespace=250G"
      "func.getattr=newest"
      "fsname=mergerfs_storage"
      # "uid=994"
      # "gid=993"
      # "umask=002"
      "x-mount.mkdir"
    ];
    fsType = "fuse.mergerfs";
  };
  systemd.services.hd-idle = {
    description = "HDD spin down daemon";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.hd-idle}/bin/hd-idle -i 0 \
            -a /dev/disk/by-id/ata-TOSHIBA_DT01ACA200_Z32UXMXGS -i 600 \
            -a /dev/disk/by-id/ata-SAMSUNG_HD103SI_S1VSJDWZ570410 -i 600 \
            -a /dev/disk/by-id/ata-ST1000LM014-1EJ164_W7708ZYV   -i 600
      '';
    };
  };
}

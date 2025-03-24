{
  vars,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./snapraid.nix
  ];
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
    parted
  ];

  fileSystems.${vars.slowArray} = {
    device = "/mnt/disk*";
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
}

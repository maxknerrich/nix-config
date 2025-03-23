{
  config,
  lib,
  vars,
  pkgs,
  ...
}: {
  # configure impermanence
  # environment.persistence."/persist" = {
  #   directories = [
  #     "/etc/nixos"
  #   ];
  #   files = [
  #     "/etc/machine-id"
  #     "/etc/ssh/ssh_host_ed25519_key"
  #     "/etc/ssh/ssh_host_ed25519_key.pub"
  #     "/etc/ssh/ssh_host_rsa_key"
  #     "/etc/ssh/ssh_host_rsa_key.pub"
  #   ];
  # };

  # security.sudo.extraConfig = ''
  #   # rollback results in sudo lectures after each reboot
  #   Defaults lecture = never
  # '';

  imports = [
    ./disko-data.nix
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

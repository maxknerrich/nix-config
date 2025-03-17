{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  # imports =
  #   [ (modulesPath + "/installer/scan/not-detected.nix")
  #   ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "mpt3sas" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  powerManagement.cpuFreqGovernor = "powersave";

  fileSystems."/" = {
    device = "rpool/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0A00-892B";
    fsType = "vfat";
  };

  # Secondary boot partition - mount it to a special location
  fileSystems."/boot-backup" = {
    device = "/dev/disk/by-uuid/0A3A-BC85"; # Replace with second drive's UUID
    fsType = "vfat";
  };

  # Then add this to make systemd-boot install to both ESPs
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.efi.mirroredBoots = [
    {
      devices = ["nodev"];
      path = "/boot-backup";
    }
  ];

  swapDevices = [];

  ## btfrs disks
  ############
  ## rpool - boot mirror
  # ata-INTEL_SSDSC2BA200G3_BTTV5335017Q200GGN
  # ata-SanDisk_SSD_PLUS_240GB_24313W802439

  # media storage disks etc
  fileSystems."/mnt/storage" = {
    device = "/mnt/disks/disk*";
    fsType = "mergerfs";
    options = ["defaults" "moveonenospc=true" "dropcacheonclose=true" "nonempty" "allow_other" "use_ino" "cache.files=off" "minfreespace=250G" "fsname=mergerfs"];
  };

  fileSystems."/mnt/disks/parity1" = {
    device = "/dev/disk/by-id/ata-TOSHIBA_DT01ACA200_Z32UXMXGS-part1";
    fsType = "ext4";
  };

  fileSystems."/mnt/disks/disk1" = {
    device = "/dev/disk/by-id/ata-ST1000LM014-1EJ164_W7708ZYV-part1";
    fsType = "ext4";
  };

  fileSystems."/mnt/disks/disk2" = {
    device = "/dev/disk/by-id/ata-SAMSUNG_HD103SI_S1VSJDWZ570410-part1";
    fsType = "ext4";
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  networking.hostId = "16223009"; # generated using echo titan | md5sum | head -c 8
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

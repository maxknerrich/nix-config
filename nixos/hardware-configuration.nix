# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  vars,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot.zfs.forceImportRoot = true;
  # boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  # boot.loader = {
  #   systemd-boot = {
  #     enable = true;
  #     consoleMode = "auto";
  #     editor = false; # Security - prevent editing boot parameters
  #   };
  #   efi = {
  #     canTouchEfiVariables = true;
  #     efiSysMountPoint = "/boot";
  #   };
  #   # Disable GRUB completely
  #   grub.enable = false;
  # };
  # # Optimize BTRFS settings
  # boot.supportedFilesystems = ["btrfs"];

  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = ["ata-SanDisk_SSD_PLUS_240GB_24313W802439" "ata-INTEL_SSDSC2BA200G3_BTTV5335017Q200GGN"];
      immutable = false;
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      removableEfi = true;
    };
  };

  boot.kernelParams = ["noatime"];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

{config, ...}: {
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "usbhid"
      "uas"
      "sd_mod"
      "r8169"
    ];
    kernelModules = ["kvm-intel"];
    loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        configurationLimit = 10;
        mirroredBoots = [
          {
            path = "/boot";
            devices = ["nodev"];
          }
          {
            path = "/boot-fallback";
            devices = ["nodev"];
          }
        ];
      };
      timeout = 3;
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}

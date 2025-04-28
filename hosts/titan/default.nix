# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    outputs.nixosModules.cockpit
    # outputs.nixosModules.snapraid-btrfs TODO Implement
    outputs.nixosModules.tg-notify
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    inputs.disko.nixosModules.disko
    ./filesystems
    ./services
  ];

  tg-notify = {
    enable = true;
    credentialsFile = config.age.secrets.tgCredentials.path;
  };

  # services.vscode-server.enable = true;
  # services.vscode-server.installPath = "$HOME/.vscode-server-insiders";

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "conservative";
    powertop.enable = true;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
      outputs.overlays.nur

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
  };

  boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [
    "kvm-intel"
    "cpufreq_conservative"
    "cpufreq_powersave"
    "cpufreq_ondemand"
  ];
  boot.extraModulePackages = [];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      configurationLimit = 15;
    };
    timeout = lib.mkDefault 2;
  };
  console.earlySetup = true;

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking.hostName = "titan";
  networking.hostId = "59561e29"; # head -c4 /dev/urandom | od -A none -t x4

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
    };
  };

  environment.systemPackages = with pkgs; [
    just
    hd-idle
    powertop
    smartmontools
    hdparm
  ];

  # TODO: Only here as cockpit crashes with PAM remove later
  security.sudo.extraRules = [
    {
      users = ["mkn"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"]; # "SETENV" # Adding the following could be a good idea
        }
      ];
    }
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
    ];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

  # services.cockpit = {
  #   enable = true;
  # };
  networking.firewall = {
    enable = false;
  };
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}

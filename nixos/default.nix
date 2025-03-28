# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  vars,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    outputs.nixosModules.cockpit
    outputs.nixosModules.snapraid-btrfs
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

  time.timeZone = vars.timeZone;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
    powertop.enable = true;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
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
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
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

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;

      auto-optimise-store = true;
      trusted-users = ["root" "@wheel"];
    };
    gc = {
      # Perform garbage collection weekly to maintain low disk usage
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # FIXME: Add the rest of your current configuration

  # TODO: Set your hostname
  networking.hostName = "titan";
  networking.hostId = "59561e29"; # head -c4 /dev/urandom | od -A none -t x4

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    keyMap = "de";
  };

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users = {
    mutableUsers = false;
    users = {
      # FIXME: Replace with your username
      mkn = {
        isNormalUser = true;
        description = "Max";
        uid = 1000;
        group = "mkn";
        hashedPasswordFile = config.age.secrets.hashedUserPassword.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2tkxTzD2+lfM6QCxJwJFchIggPdzcZhQJjFTaRZvKg max.knerrich@outlook.com"
        ];
        # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
        extraGroups = ["wheel" "networkmanager"];
      };
      root.openssh.authorizedKeys.keys = config.users.users.mkn.openssh.authorizedKeys.keys;
    };
    groups = {
      mkn = {
        gid = 1000;
      };
    };
  };
  age.secrets.hashedUserPassword = {
    file = "${inputs.mysecrets}/hashedUserPassword.age";
  };
  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # root user is used for remote deployment, so we need to allow it
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    # nix and deployment tools
    nil
    just
    hd-idle
    powertop
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

  services.cockpit = {
    enable = true;
    openFirewall = true;
  };
  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web = {
      listen.port = 8080;
    };
    openFirewall = true;
  };
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}

{
  config,
  inputs,
  pkgs,
  lib,
  name,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    # (builtins.fetchTarball {
    #   url = "https://github.com/nix-community/nixos-vscode-server/tarball/master";
    #   sha256 = "09j4kvsxw1d5dvnhbsgih0icbrxqv90nzf0b589rb5z6gnzwjnqf";
    # })
    ./../common/nixos-common.nix
    ./../common/common-packages.nix
  ];

  ## DEPLOYMENT
  deployment = {
    targetHost = "titan.local.knerrich.tech";
    targetUser = "mkn";
    buildOnTarget = false;
    allowLocalDeployment = true;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    mirroredBoots = [
      {
        devices = ["nodev"];
        path = "/boot";
      }
      {
        devices = ["nodev"];
        path = "/bootBackup";
      }
    ];
  };

  fileSystems."/boot1".options = ["nofail"];
  fileSystems."/boot2".options = ["nofail"];

  boot.kernelModules = ["drivetemp"];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  # boot.kernelParams = [
  #   "i915.fastboot=1"
  #   "i915.enable_guc=3"
  #   #"i915.force_probe=4e71"  # For Raptor Lake
  # ];

  boot.supportedFilesystems = ["btrfs"];
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly"; # Default is weekly
    fileSystems = ["/"]; # Scrub the root filesystem
  };

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    # ansible
    # bc
    # devbox
    dig
    e2fsprogs # badblocks
    figurine
    git
    gptfdisk
    hddtemp
    htop
    intel-gpu-tools
    inxi
    iotop
    # jq
    lm_sensors
    # mc
    mergerfs
    # molly-guard
    ncdu
    # nmap
    # nvme-cli
    powertop
    python3
    smartmontools
    snapraid
    tmux
    tree
    wget
    # xfsprogs

    # zfs send/rec with sanoid/syncoid
    # sanoid
    # lzop
    # mbuffer
    # pv
    zstd
  ];

  ## quicksync
  hardware.firmware = [pkgs.linux-firmware];
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      # VA-API drivers
      intel-vaapi-driver # This is the right one for your HD Graphics 4600
      vaapiVdpau
      libvdpau-va-gl

      # You can keep these if you want, but they're more relevant for newer Intel GPUs
      libva
      libva-utils

      # Diagnostic tools
      glxinfo
      pciutils
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "i965"; # Changed from "iHD" to "i965" for Haswell GPU
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    LIBVA_MESSAGING_LEVEL = "1";
    GST_VAAPI_ALL_DRIVERS = "1";
  };

  networking = {
    firewall.enable = false;
    hostName = "titan";
    useDHCP = true;
    # defaultGateway = "10.42.0.254";
    # nameservers = ["10.42.0.253"];
    # localCommands = ''
    #   ip rule add to 10.42.0.0/21 priority 2500 lookup main || true
    # '';
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.openssh = {
    enable = true;
    PasswordAuthentication = lib.mkDefault false;
    PermitRootLogin = "no";
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  # services.tailscale.enable = true;

  # services.sanoid = {
  #   enable = true;
  #   interval = "hourly";
  #   # backupmedia
  #   templates.backupmedia = {
  #     daily = 3;
  #     monthly = 3;
  #     autoprune = true;
  #     autosnap = true;
  #   };
  #   datasets."bigrust18/media" = {
  #     useTemplate = ["backupmedia"];
  #     recursive = true;
  #   };
  #   extraArgs = ["--debug"];
  # };

  # services.syncoid = {
  #   enable = true;
  #   user = "root";
  #   interval = "hourly";
  #   commands = {
  #     "bigrust18/media" = {
  #       target = "root@deepthought:bigrust20/media";
  #       extraArgs = ["--sshoption=StrictHostKeyChecking=off"];
  #       recursive = true;
  #     };
  #   };
  #   commonArgs = ["--debug"];
  # };

  # services.vscode-server.enable = true;

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    securityType = "user";
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "titan";
        "netbios name" = "titan";
        "security" = "user";
        "guest ok" = "yes";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "load printers" = "no";
      };
    };
    shares = let
      mkShare = path: {
        path = path;
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "mkn";
        "force group" = "users";
      };
    in {
      storage = mkShare "/mnt/storage";
    };
  };

  nix = {
    settings = {
      trusted-users = ["root" "mkn"];
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };
}

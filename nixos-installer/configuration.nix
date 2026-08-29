{
  inputs,
  pkgs,
  ...
}: {
  networking.hostName = "nixos-installer";

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMU+MXkqxIDEg9IPVCluImSjRByx71QCQdveLQNifwGq Max"
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowUsers = [
        "nixos"
        "root"
      ];
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    btop
    cryptsetup
    curl
    git
    gptfdisk
    jq
    nvme-cli
    parted
    rsync
    tmux
    vim
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
  ];

  users.motd = ''
    NixOS headless installer

    Connect as: ssh nixos@<installer-ip>
    Network status: ip -brief address

    Configuration: https://github.com/maxknerrich/nix-config
    Clone it with: git clone https://github.com/maxknerrich/nix-config.git

    Disk operations are intentionally not automated. Inspect the target disks
    before running disko or nixos-install.
  '';

  system.stateVersion = "26.05";
}

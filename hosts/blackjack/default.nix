{
  config,
  pgks,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "blackjack";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # PulseAudio compatibility
    jack.enable = true; # JACK compatibility
  };

  users.users.root.openssh.authorizedKeys.keys = config.users.users.mkn.openssh.authorizedKeys.keys;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}

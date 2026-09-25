{
  config,
  inputs,
  ...
}: {
  imports = [inputs.nix-homebrew.darwinModules.nix-homebrew];

  nix-homebrew = {
    enable = true;
    user = config.my.username;
    enableRosetta = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      autoUpdate = false; # Tap versions are pinned by flake.lock.
      upgrade = true;
      cleanup = "zap";
    };

    brews = [
      "mas" # Required for Mac App Store applications below.
      "ykman" # Nix libffi is incompatible with the current macOS dyld.
    ];

    casks = [
      # Browsers
      "zen"
      "tor-browser"
      "helium-browser"

      # Development and terminal
      "zed"
      "ghostty"
      "t3-code"
      "codex-app"
      "codexbar"

      # Input and system utilities
      "eurkey-next"
      "scroll-reverser"
      "thaw"
      "raycast"
      "mole-app"
      "lulu"

      # Creative and productivity
      "figma"
      "affinity"
      "timemator"
      "obsidian"
      #"kitlangton-hex"

      # Media and communication
      "spotify"
      "whatsapp"

      # Games, backup, and privacy
      "prismlauncher"
      "kopiaui"
      "nordvpn"
      "tailscale-app"
      "proton-pass"
      "proton-drive"
    ];

    masApps = {
      "DaVinci Resolve" = 571213070;
      Photomator = 1444636541;
      WireGuard = 1451685025;
    };
  };
}

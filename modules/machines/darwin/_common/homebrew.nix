{config, ...}: {
  nix-homebrew = {
    enable = true;
    user = config.my.username;
    enableRosetta = false; # Apple Silicon only; do not manage /usr/local.
    mutableTaps = false; # Keep taps declarative.
    autoMigrate = true; # Adopt an existing Homebrew install if present.
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap"; # Remove undeclared Homebrew packages and cask leftovers.
    };
    brews = [
      "mas" # Installs Mac App Store apps declared below.
      "mole" # CLI Mac cleaner from mole.fit.
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
      "daisydisk"
      "pearcleaner"
      "lulu"

      # Creative and productivity
      "figma"
      "affinity"
      "timemator"
      "obsidian"
      "typewhisper"

      # Media and communication
      "spotify"
      "whatsapp"

      # Games, backup, and privacy
      "prismlauncher"
      "kopiaui"
      "nordvpn"
      "proton-pass"
      "proton-drive"
    ];
    masApps.Photomator = 1444636541; # MAS-only photo editor.
  };
}

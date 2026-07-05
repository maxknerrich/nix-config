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
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none"; # Do not remove manually installed apps yet.
    };
    brews = [
      "mas" # Installs Mac App Store apps declared below.
    ];
    casks = [
      # Browsers
      "zen"
      "tor-browser"
      "helium-browser"

      # Development and terminal
      "zed"
      "ghostty"

      # Input and system utilities
      "eurkey-next"
      "scroll-reverser"
      "stats"
      "raycast"
      "mole-app"
      "daisydisk"
      "pearcleaner"

      # Creative and productivity
      "figma"
      "affinity"
      "timemator"
      "obsidian"

      # Media and communication
      "spotify"
      "whatsapp"

      # Games, backup, and privacy
      "prismlauncher"
      "kopiaui"
      "nordvpn"
      "proton-pass"
    ];
    masApps.Photomator = 1444636541; # MAS-only photo editor.
  };
}

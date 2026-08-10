{
  config,
  inputs,
  ...
}: let
  username = config.my.username;
in {
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
      "kitlangton-hex"

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
      Photomator = 1444636541;
      WireGuard = 1451685025;
    };
  };

  home-manager.users.${username} = {
    config,
    theme,
    ...
  }: let
    repo = "${config.home.homeDirectory}/nix-config";
    protonDrive = "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-max@knerrich.com-folder";
    link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
    protonDriveLink = name: config.lib.file.mkOutOfStoreSymlink "${protonDrive}/${name}";
  in {
    services.proton-pass-agent = {
      enable = true;
      extraArgs = [
        "--vault-name"
        "Personal"
      ];
    };
    launchd.agents.proton-pass-agent.domain = "gui";

    programs.ghostty = {
      enable = true;
      package = null; # App is installed by Homebrew; HM writes config only.
      settings = {
        theme = theme.apps.ghostty;
        command = "/etc/profiles/per-user/${username}/bin/fish";
        macos-option-as-alt = "left";
      };
    };

    home.file = {
      ".config/zed/settings.json".source = link "modules/users/mkn/dotfiles/zed/settings.json";
      ".config/zed/keymap.json".source = link "modules/users/mkn/dotfiles/zed/keymap.json";

      "[2] - Personal".source = protonDriveLink "[2] - Personal";
      "[3] - Work".source = protonDriveLink "[3] - Work";
      "[4] - Money & Tax".source = protonDriveLink "[4] - Money & Tax";
      "[9] - ARCHIVE".source = protonDriveLink "[9] - ARCHIVE";
    };
  };
}

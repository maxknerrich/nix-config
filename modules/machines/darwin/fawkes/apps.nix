{config, ...}: let
  username = config.my.username;
in {
  nix-homebrew = {
    enable = true;
    user = config.my.username;
    enableRosetta = false;
    mutableTaps = false;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    brews = [
      "mas" # Required for Mac App Store applications below.
      "mole"
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

    masApps.Photomator = 1444636541;
  };

  home-manager.users.${username} = {
    config,
    theme,
    ...
  }: let
    repo = "${config.home.homeDirectory}/nix-config";
    link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
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
    };
  };
}

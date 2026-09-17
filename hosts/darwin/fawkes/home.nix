{
  config,
  my,
  theme,
  ...
}: let
  repo = "${config.home.homeDirectory}/nix-config";
  protonDrive = "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-max@knerrich.com-folder";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
  protonDriveLink = name: config.lib.file.mkOutOfStoreSymlink "${protonDrive}/${name}";
in {
  imports = [
    ../../../home
    ../../../home/optional/development.nix
    ../../../home/optional/git.nix
    ../../../home/optional/herdr.nix
    ../../../home/optional/pi.nix
  ];

  services.proton-pass-agent = {
    enable = true;
    extraArgs = [
      "--vault-name"
      "Personal"
    ];
  };
  launchd.agents.proton-pass-agent.domain = "gui";

  # Home Manager sets SSH_AUTH_SOCK in shells; GUI apps need launchd's value.
  launchd.agents.proton-pass-environment = {
    enable = true;
    domain = "gui";
    config = {
      RunAtLoad = true;
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''/bin/launchctl setenv SSH_AUTH_SOCK "$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)/${config.services.proton-pass-agent.socket}"''
      ];
    };
  };

  programs.ghostty = {
    enable = true;
    package = null; # App is installed by Homebrew; HM writes config only.
    settings = {
      theme = theme.apps.ghostty;
      command = "/etc/profiles/per-user/${my.username}/bin/fish";
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
}

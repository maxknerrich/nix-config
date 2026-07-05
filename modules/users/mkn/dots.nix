{config, ...}: let
  repo = "/Users/mkn/nix-config";
  # Mutable symlinks let app config update without rebuilding Home Manager.
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in {
  home.file = {
    # Pi: link only repo-backed config, not auth, sessions, or runtime state.
    ".config/pi/agent/AGENTS.md".source = link "modules/users/mkn/dotfiles/pi/agent/AGENTS.md";
    ".config/pi/agent/settings.json".source = link "modules/users/mkn/dotfiles/pi/agent/settings.json";
    ".config/pi/agent/keybindings.json".source = link "modules/users/mkn/dotfiles/pi/agent/keybindings.json";
    ".config/pi/agent/prompts".source = link "modules/users/mkn/dotfiles/pi/agent/prompts";
    ".config/pi/agent/skills".source = link "modules/users/mkn/dotfiles/pi/agent/skills";
    ".config/pi/agent/themes".source = link "modules/users/mkn/dotfiles/pi/agent/themes";
    ".config/pi/agent/extensions".source = link "modules/users/mkn/dotfiles/pi/agent/extensions";

    # Zed: app from Homebrew, config from this repo.
    ".config/zed/settings.json".source = link "modules/users/mkn/dotfiles/zed/settings.json";
    ".config/zed/keymap.json".source = link "modules/users/mkn/dotfiles/zed/keymap.json";
  };
}

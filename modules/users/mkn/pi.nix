{config, ...}: let
  repo = "${config.home.homeDirectory}/nix-config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in {
  home = {
    sessionVariables.PI_TELEMETRY = "0";

    # Keep configuration here, but leave Pi auth, sessions, and runtime state unmanaged.
    file = {
      ".pi/agent/AGENTS.md".source = link "modules/users/mkn/dotfiles/pi/agent/AGENTS.md";
      ".pi/agent/settings.json".source = link "modules/users/mkn/dotfiles/pi/agent/settings.json";
      ".pi/agent/keybindings.json".source = link "modules/users/mkn/dotfiles/pi/agent/keybindings.json";
      ".pi/agent/prompts".source = link "modules/users/mkn/dotfiles/pi/agent/prompts";
      ".pi/agent/skills".source = link "modules/users/mkn/dotfiles/pi/agent/skills";
      ".pi/agent/themes".source = link "modules/users/mkn/dotfiles/pi/agent/themes";
      ".pi/agent/extensions".source = link "modules/users/mkn/dotfiles/pi/agent/extensions";
    };
  };
}

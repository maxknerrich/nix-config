{config, ...}: let
  repo = "${config.home.homeDirectory}/nix-config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
  sharedAgentLink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/${path}";
  sharedAgentFiles = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/${name}";
      value.source = sharedAgentLink name;
    }) (builtins.attrNames (builtins.readDir ./dotfiles/.agents))
  );
in {
  home = {
    sessionVariables.PI_TELEMETRY = "0";

    # Keep configuration here, but leave Pi auth, sessions, and runtime state unmanaged.
    file =
      {
        ".pi/agent/settings.json".source = link "modules/users/mkn/dotfiles/pi/agent/settings.json";
        ".pi/agent/keybindings.json".source = link "modules/users/mkn/dotfiles/pi/agent/keybindings.json";
        ".pi/agent/prompts".source = link "modules/users/mkn/dotfiles/pi/agent/prompts";
        ".agents".source = link "modules/users/mkn/dotfiles/.agents";
        ".pi/agent/themes".source = link "modules/users/mkn/dotfiles/pi/agent/themes";
        ".pi/agent/extensions".source = link "modules/users/mkn/dotfiles/pi/agent/extensions";
      }
      // sharedAgentFiles;
  };
}

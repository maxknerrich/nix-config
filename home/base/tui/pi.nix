{config, ...}: let
  dotfiles = "${config.home.homeDirectory}/nix-config/home/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  sharedAgentLink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/${path}";
  sharedAgentFiles = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/${name}";
      value.source = sharedAgentLink name;
    }) (builtins.attrNames (builtins.readDir ../../dotfiles/.agents))
  );
in {
  home = {
    sessionVariables.PI_TELEMETRY = "0";

    # Keep configuration here, but leave Pi auth, sessions, and runtime state unmanaged.
    file =
      {
        ".pi/agent/settings.json".source = link "pi/agent/settings.json";
        ".pi/agent/web-search.json".source = link "pi/agent/web-search.json";
        ".pi/agent/cloak.json".source = link "pi/agent/cloak.json";
        ".pi/agent/keybindings.json".source = link "pi/agent/keybindings.json";
        ".pi/agent/prompts".source = link "pi/agent/prompts";
        ".agents".source = link ".agents";
        ".pi/agent/themes".source = link "pi/agent/themes";
        ".pi/agent/extensions".source = link "pi/agent/extensions";
      }
      // sharedAgentFiles;
  };
}

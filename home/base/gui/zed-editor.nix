{config, ...}: let
  dotfiles = "${config.home.homeDirectory}/nix-config/home/dotfiles/zed";
  link = name: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${name}";
in {
  home.file = {
    ".config/zed/settings.json".source = link "settings.json";
    ".config/zed/keymap.json".source = link "keymap.json";
  };
}

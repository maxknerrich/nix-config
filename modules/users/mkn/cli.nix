{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        ls = "eza";
        ll = "eza -la";
        la = "eza -a";
        cat = "bat --paging=never";
      };
      interactiveShellInit = ''
        # Vite Plus manages Node outside Nix.
        if test -f "$HOME/.vite-plus/env.fish"
          source "$HOME/.vite-plus/env.fish"
        end
      '';
    };
    bat.enable = true;
    eza = {
      enable = true;
      enableFishIntegration = true;
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    ghostty = {
      enable = true;
      package = null; # App is installed by Homebrew; HM writes config only.
      settings = {
        theme = "dark:Vitesse Dark,light:Vitesse Light";
        macos-option-as-alt = true;
      };
    };
  };
}

{pkgs, ...}: {
  home.packages = with pkgs; [
    eza
    bat
  ];
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = ["--cmd cd"];
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.unsafeDiscardStringContext (builtins.readFile ./omp.toml));
    };
    zsh = {
      enable = true;
      enableCompletion = false;
      zplug = {
        enable = true;
        plugins = [
          {name = "zsh-users/zsh-autosuggestions";}
          {name = "zsh-users/zsh-syntax-highlighting";}
          {name = "zsh-users/zsh-completions";}
          {name = "zsh-users/zsh-history-substring-search";}
          {name = "unixorn/warhol.plugin.zsh";}
        ];
      };
      shellAliases = {
        ".." = "cd ..";
        ls = "exa --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions";
        ll = "exa -alh";
        tree = "exa --tree";
        cat = "bat";
      };

      initExtra = ''
        # Cycle back in the suggestions menu using Shift+Tab
        bindkey '^[[Z' reverse-menu-complete

        bindkey '^B' autosuggest-toggle
        # Make Ctrl+W remove one path segment instead of the whole path
        WORDCHARS=''${WORDCHARS/\/}

        # Highlight the selected suggestion
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu yes=long select

        export EDITOR=nano || export EDITOR=vim

        source $ZPLUG_HOME/repos/unixorn/warhol.plugin.zsh/warhol.plugin.zsh
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down

        if grep -q microsoft /proc/version 2>/dev/null; then
          alias explorer="/mnt/c/Windows/explorer.exe"
          alias code="/mnt/c/Users/mkn/AppData/Local/Programs/'Microsoft VS Code'/bin/code";
        fi

        if command -v motd &> /dev/null
        then
          motd
        fi
        bindkey -e
      '';
    };
  };
}

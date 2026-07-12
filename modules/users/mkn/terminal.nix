{
  lib,
  pkgs,
  theme,
  ...
}: {
  home.packages = with pkgs;
    [
      # Nix tooling
      alejandra
      nixd

      # Development and shell helpers
      ccusage
      codex
      gh
      herdr
      just
      mosh
      tree
    ]
    ++ lib.optionals stdenv.isDarwin [
      yubikey-manager
    ];

  programs = {
    fish = {
      enable = true;
      shellAliases = {
        ls = "eza -l --group-directories-first";
        l = "eza -l --group-directories-first";
        ll = "eza -lah --group-directories-first --git";
        la = "eza -a --group-directories-first";
        lt = "eza --tree --level=2 --group-directories-first";
        tree = "eza --tree --group-directories-first";
        cat = "bat --paging=never";
        less = "bat --paging=always";
        cd = "z";
        cdi = "zi";
        back = "z -";
      };
      interactiveShellInit = ''
        # Vite Plus manages Node outside Nix.
        if test -f "$HOME/.vite-plus/env.fish"
          source "$HOME/.vite-plus/env.fish"
        end
      '';
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        add_newline = false;
        format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
        right_format = "$status";
        character = {
          success_symbol = "[❯](${theme.colors.green})";
          error_symbol = "[❯](${theme.colors.red})";
          vimcmd_symbol = "[❮](${theme.colors.blue})";
        };
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
          style = "bold ${theme.colors.blue}";
          read_only = " 󰌾";
        };
        git_branch = {
          symbol = " ";
          style = theme.colors.purple;
          format = "[$symbol$branch]($style) ";
        };
        git_status = {
          style = theme.colors.yellow;
          format = "([$all_status$ahead_behind]($style) )";
          conflicted = "=";
          ahead = "⇡$count";
          behind = "⇣$count";
          diverged = "⇕⇡$ahead_count⇣$behind_count";
          untracked = "?$count";
          stashed = "*$count";
          modified = "!$count";
          staged = "+$count";
          renamed = "»$count";
          deleted = "✘$count";
        };
        nix_shell = {
          symbol = "❄ ";
          format = "[$symbol$name]($style) ";
          style = theme.colors.cyan;
        };
        cmd_duration = {
          min_time = 1000;
          format = "[took $duration]($style) ";
          style = theme.colors.whiteDim;
        };
        status = {
          disabled = false;
          format = "[$status]($style)";
          style = theme.colors.red;
        };
      };
    };

    bat = {
      enable = true;
      config = {
        theme = theme.apps.bat;
        style = "numbers,changes,header";
        paging = "never";
      };
    };
    eza = {
      enable = true;
      enableFishIntegration = true;
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}

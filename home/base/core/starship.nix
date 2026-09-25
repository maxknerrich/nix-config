{
  lib,
  my,
  pkgs,
  theme,
  ...
}: let
  isDefaultHost = my.hostName == "fawkes";
  hostColor =
    if isDefaultHost
    then theme.colors.blue
    else "#${builtins.substring 0 6 (builtins.hashString "sha256" my.hostName)}";
  fishColor = lib.removePrefix "#" hostColor;
in {
  home.packages = [pkgs.figlet];

  programs.fish.functions.fish_greeting = ''
    set -l banner_host (hostname -s 2>/dev/null; or hostname)
    set_color ${fishColor}
    ${pkgs.figlet}/bin/figlet -f small $banner_host
    set_color normal
  '';

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "${lib.optionalString (!isDefaultHost) "$hostname"}$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
      right_format = "$status";
      hostname = lib.mkIf (!isDefaultHost) {
        ssh_only = false;
        style = "bold ${hostColor}";
        format = "[$hostname]($style) ";
      };
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
}

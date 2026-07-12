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

  programs.starship.settings = {
    format = lib.mkForce "${lib.optionalString (!isDefaultHost) "$hostname"}$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
    hostname = lib.mkIf (!isDefaultHost) {
      ssh_only = false;
      style = "bold ${hostColor}";
      format = "[$hostname]($style) ";
    };
  };
}

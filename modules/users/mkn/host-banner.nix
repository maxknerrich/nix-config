{
  config,
  lib,
  pkgs,
  my,
  theme,
  ...
}: let
  cfg = config.programs.hostBanner;
  hostName = my.hostName;
  isDefaultHost = hostName == cfg.defaultHostName;
  generatedColor = "#${builtins.substring 0 6 (builtins.hashString "sha256" hostName)}";
  hostColor =
    if isDefaultHost
    then cfg.defaultColor
    else generatedColor;
  fishColor = lib.removePrefix "#" hostColor;
in {
  options.programs.hostBanner = {
    enable = lib.mkEnableOption "a colored hostname ASCII banner and host-aware prompt";
    defaultHostName = lib.mkOption {
      type = lib.types.str;
      default = "fawkes";
      description = "Host that keeps the default prompt and omits the prompt hostname.";
    };
    defaultColor = lib.mkOption {
      type = lib.types.str;
      default = theme.colors.blue;
      description = "Banner color for the default host.";
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}

{
  config,
  lib,
  theme,
  ...
}: let
  color = alpha: value: "0x${alpha}${lib.removePrefix "#" value}";
in {
  services.jankyborders = {
    enable = true;
    settings = {
      style = "round";
      width = 4;
      hidpi = "on";
      active_color = color "ff" theme.colors.blue;
      inactive_color = color "66" theme.colors.whiteDim;
    };
    errorLogFile = "${config.home.homeDirectory}/Library/Logs/omadar-borders.err.log";
    outLogFile = "${config.home.homeDirectory}/Library/Logs/omadar-borders.out.log";
  };
}

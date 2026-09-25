{
  pkgs,
  omadar,
  theme,
  sketchybar,
}:
# Both modules use this package so the bar's wake script and Rift's event
# subscription refresh the same three workspace states.
pkgs.writeShellApplication {
  name = "omadar-bar-workspace";
  text = ''
    RIFT_CLI=${pkgs.lib.escapeShellArg omadar.riftCliBinary}
    SKETCHYBAR=${pkgs.lib.escapeShellArg (pkgs.lib.getExe sketchybar)}
    JQ=${pkgs.lib.escapeShellArg (pkgs.lib.getExe pkgs.jq)}
    ACTIVE_BACKGROUND=${pkgs.lib.escapeShellArg "0x44${pkgs.lib.removePrefix "#" theme.colors.whiteDim}"}
    ACTIVE_BORDER=${pkgs.lib.escapeShellArg "0x99${pkgs.lib.removePrefix "#" theme.colors.whiteDim}"}
    ACTIVE_TEXT=${pkgs.lib.escapeShellArg "0xff${pkgs.lib.removePrefix "#" theme.colors.foreground}"}
    INACTIVE_TEXT=${pkgs.lib.escapeShellArg "0xff${pkgs.lib.removePrefix "#" theme.colors.whiteDim}"}
    ${builtins.readFile ./scripts/bar-workspace.sh}
  '';
}

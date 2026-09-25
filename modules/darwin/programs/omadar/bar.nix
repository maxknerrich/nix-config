{
  config,
  lib,
  pkgs,
  omadar,
  theme,
  ...
}: let
  sketchybar = lib.getExe config.programs.sketchybar.package;
  color = value: "0xff${lib.removePrefix "#" value}";
  workspaceHelper = import ./bar-workspace.nix {
    inherit pkgs omadar theme;
    sketchybar = config.programs.sketchybar.package;
  };
  clock = pkgs.writeShellApplication {
    name = "omadar-bar-clock";
    text = ''
      ${sketchybar} --set "''${NAME:-clock}" "label=$(/bin/date '+%a %d %b  %H:%M')"
    '';
  };
  workspaces = lib.concatStringsSep "\n" (
    lib.imap0 (
      index: name: let
        item = "workspace.${toString (index + 1)}";
      in ''
        ${sketchybar} --add item ${lib.escapeShellArg item} left \
          --set ${lib.escapeShellArg item} \
            icon=${lib.escapeShellArg name} icon.drawing=on label.drawing=off \
            icon.font='.AppleSystemUIFont:Medium:12.0' icon.align=center icon.width=26 align=center \
            icon.color=${lib.escapeShellArg (color theme.colors.whiteDim)} \
            icon.padding_left=0 icon.padding_right=0 width=30 \
            padding_left=0 padding_right=0 \
            background.height=29 background.corner_radius=7 \
            background.color=0x00000000 background.border_width=0 \
            click_script=${lib.escapeShellArg "${omadar.riftCliBinary} execute workspace switch ${toString index}"}
      ''
    )
    omadar.workspaceNames
  );
in {
  programs.sketchybar = {
    enable = true;
    configType = "bash";
    config = ''
      ${sketchybar} --bar position=top height=${toString omadar.barHeight} topmost=window show_in_fullscreen=on \
        color=${lib.escapeShellArg (color theme.colors.black)} \
        padding_left=${toString omadar.gap} padding_right=8
      ${sketchybar} --default icon.font='.AppleSystemUIFont:Medium:12.0' \
        label.font='.AppleSystemUIFont:Medium:13.0' \
        icon.color=${lib.escapeShellArg (color theme.colors.foreground)} \
        label.color=${lib.escapeShellArg (color theme.colors.foreground)} \
        background.drawing=off
      ${workspaces}
      # Rift updates workspace icons through the helper using background.image=app.<bundle-id>.
      ${sketchybar} --set workspace.1 \
        script=${lib.escapeShellArg "${workspaceHelper}/bin/omadar-bar-workspace"} \
        --subscribe workspace.1 system_woke display_change
      ${sketchybar} --add item clock right \
        --set clock icon.drawing=off label.font='.AppleSystemUIFont:Medium:13.0' \
          label.width=130 label.align=right padding_left=0 padding_right=0 \
          update_freq=10 script=${lib.escapeShellArg "${clock}/bin/omadar-bar-clock"} \
        --subscribe clock system_woke
      ${sketchybar} --update
    '';
  };

  xdg.configFile."sketchybar/sketchybarrc".onChange = ''
    if /bin/launchctl print "gui/$UID/org.nix-community.home.sketchybar" >/dev/null 2>&1; then
      ${sketchybar} --reload
    fi
  '';
}

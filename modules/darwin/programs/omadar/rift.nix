{
  config,
  lib,
  pkgs,
  omadar,
  theme,
  ...
}: let
  toml = pkgs.formats.toml {};
  floatingRule = app_id: {
    inherit app_id;
    floating = true;
    position = {
      x = 0.5;
      y = 0.5;
    };
    size = {
      w = 875;
      h = 600;
    };
  };
  workspaceHelper = import ./bar-workspace.nix {
    inherit pkgs omadar theme;
    sketchybar = config.programs.sketchybar.package;
  };
  workspaceCommand = "${workspaceHelper}/bin/omadar-bar-workspace";
  logDir = "${config.home.homeDirectory}/Library/Logs/rift";
  # v0.5.10 runs startup commands before opening the CLI server. This short
  # retry exits once the workspaces are ready; no event-state daemon is needed.
  registration = pkgs.writeShellApplication {
    name = "omadar-rift-register";
    text = ''
      RIFT_CLI=${lib.escapeShellArg omadar.riftCliBinary}
      WORKSPACE_COMMAND=${lib.escapeShellArg workspaceCommand}
      ${builtins.readFile ./scripts/rift-register.sh}
    '';
  };
in {
  xdg.configFile."rift/config.toml" = {
    source = toml.generate "rift-config.toml" {
      settings = {
        default_disable = false;
        animate = true;
        animation_duration = omadar.animationDuration;
        animation_fps = omadar.animationFps;
        focus_follows_mouse = false;
        mouse_follows_focus = false;
        mouse_hides_on_focus = false;
        hot_reload = true;
        layout = {
          mode = "bsp";
          gaps = {
            inner = {
              horizontal = omadar.gap;
              vertical = omadar.gap;
            };
            outer = {
              # The bar already occupies the menu-bar frame.
              top = omadar.gap;
              left = omadar.gap;
              bottom = omadar.gap;
              right = omadar.gap;
            };
          };
        };
        gestures = {
          enabled = true;
          fingers = 4; # Leave the existing three-finger drag untouched.
          skip_empty = true;
          consume_dock_swipe = true;
          haptics_enabled = false;
        };
        ui.menu_bar.enabled = false;
        run_on_start = ["${registration}/bin/omadar-rift-register"];
      };
      virtual_workspaces = {
        enabled = true;
        default_workspace_count = omadar.workspaceCount;
        workspace_names = omadar.workspaceNames;
        default_workspace = 0;
        preserve_focus_per_workspace = true;
        workspace_auto_back_and_forth = false;
        prevent_wrapping = true;
        auto_assign_windows = false;
        app_rules =
          map floatingRule [
            "com.apple.finder"
            "com.apple.systempreferences"
            "me.proton.pass.electron"
          ]
          ++ [
            (floatingRule "com.raycast.macos" // {title_regex = "^Settings$";})
            {
              app_id = "app.zen-browser.zen";
              title_regex = "^Opening .+$";
              floating = true;
            }
            {
              app_id = "app.zen-browser.zen";
              title_regex = "^Picture-in-Picture$";
              manage = false;
            }
          ];
        workspace_rules = [];
      };
      # Karabiner owns every binding; Rift's default Option bindings must not load.
      keys = {};
    };
    # HM runs onChange after linkGeneration, only when this file changes and
    # never on a dry run. Reload only an already responsive Rift instance.
    # The callback path is stable; v0.5.10 deduplicates repeat subscriptions.
    onChange = ''
      if ${lib.escapeShellArg omadar.riftCliBinary} query workspaces >/dev/null 2>&1; then
        ${lib.escapeShellArg omadar.riftCliBinary} execute config reload
      fi
    '';
  };

  # Link the config/helper and create both service log directories before HM
  # bootstraps either GUI LaunchAgent. Do not write logs to /tmp.
  home.activation.omadarAgentPrerequisites = lib.hm.dag.entryBetween ["setupLaunchAgents"] ["linkGeneration"] ''
    run /bin/mkdir -p ${lib.escapeShellArg logDir} ${lib.escapeShellArg "${config.home.homeDirectory}/Library/Logs/sketchybar"}
  '';

  launchd.agents.rift = {
    enable = true;
    config = {
      ProgramArguments = [omadar.riftBinary];
      EnvironmentVariables = {
        PATH = "${builtins.dirOf omadar.riftBinary}:/usr/bin:/bin:/usr/sbin:/sbin";
        RUST_LOG = "error,warn,info";
      };
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ProcessType = "Interactive";
      LimitLoadToSessionType = "Aqua";
      StandardOutPath = "${logDir}/rift.out.log";
      StandardErrorPath = "${logDir}/rift.err.log";
    };
  };
}

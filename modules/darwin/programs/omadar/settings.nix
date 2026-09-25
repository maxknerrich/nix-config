# Internal defaults shared by the keyboard, tiler, and bar. No public settings API yet.
{
  lib,
  brewPrefix,
}: let
  workspaceCount = 5;
  riftCliBinary = "${brewPrefix}/bin/rift-cli";
  command = args: lib.escapeShellArgs args;
  binding = key: modifiers: args: {
    inherit key modifiers;
    command = command args;
  };
  riftBinding = key: modifiers: args:
    binding key modifiers ([riftCliBinary "execute"] ++ args);
  directions = ["left" "down" "up" "right"];
  applications = {
    b = "Zen";
    e = "Zed";
    o = "Obsidian";
    s = "Spotify";
  };
in {
  inherit workspaceCount riftCliBinary;
  riftBinary = "${brewPrefix}/bin/rift";
  workspaceNames = builtins.genList (index: toString (index + 1)) workspaceCount;
  animationDuration = 0.14;
  animationFps = 120.0;
  gap = 6;
  barHeight = 38;

  bindings =
    [
      (binding "spacebar" [] ["/usr/bin/open" "-a" "Raycast"])
      (binding "return_or_enter" [] ["/usr/bin/open" "-a" "Ghostty"])
      (riftBinding "t" [] ["window" "toggle-float"])
      (riftBinding "f" [] ["window" "toggle-fullscreen-within-gaps"])
      (riftBinding "w" [] ["window" "close"])
      (riftBinding "tab" [] ["workspace" "next" "false"])
      (riftBinding "tab" ["shift"] ["workspace" "prev" "false"])
      (riftBinding "tab" ["control"] ["workspace" "last"])
    ]
    ++ lib.concatLists (builtins.genList (index: [
        (riftBinding (toString (index + 1)) [] ["workspace" "switch" (toString index)])
        (riftBinding (toString (index + 1)) ["shift"] ["workspace" "move-window" (toString index)])
      ])
      workspaceCount)
    ++ lib.concatMap (direction: [
      (riftBinding "${direction}_arrow" [] ["window" "focus" direction])
      (riftBinding "${direction}_arrow" ["shift"] ["layout" "move-node" direction])
    ])
    directions
    ++ lib.mapAttrsToList (key: app:
      binding key ["shift"] ["/usr/bin/open" "-a" app])
    applications;
}

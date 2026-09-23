{
  lib,
  pkgs,
  ...
}: let
  herdrWindowTitle = pkgs.writeShellApplication {
    name = "herdr-window-title";
    runtimeInputs = [pkgs.jq];
    text = ''
      snapshot="$($HERDR_BIN_PATH api snapshot)"
      space="$(jq -r '.result.snapshot.workspaces[] | select(.focused == true) | .label' <<< "$snapshot")"

      if [[ -n "$space" ]]; then
        "$HERDR_BIN_PATH" terminal title set "herdr · $space" >/dev/null
      fi
    '';
  };
  herdrWindowTitlePlugin = pkgs.writeTextDir "herdr-plugin.toml" ''
    id = "mkn.window-title"
    name = "Space window title"
    version = "1.0.0"
    min_herdr_version = "0.7.5"
    description = "Show the focused Herdr space in the outer terminal title"
    platforms = ["linux", "macos"]

    [[startup]]
    command = ["${herdrWindowTitle}/bin/herdr-window-title"]

    [[events]]
    on = "workspace.focused"
    command = ["${herdrWindowTitle}/bin/herdr-window-title"]

    [[events]]
    on = "workspace.renamed"
    command = ["${herdrWindowTitle}/bin/herdr-window-title"]
  '';
in {
  home.packages = [pkgs.herdr];

  home.activation.herdrWindowTitlePlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.herdr}/bin/herdr plugin link ${herdrWindowTitlePlugin} --enabled
  '';
}

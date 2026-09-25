# Omadar

Rift tiling, JankyBorders, a minimal SketchyBar, and Globe-as-Super through Karabiner. Managed by nix-darwin and Home Manager.

Enable from the host configuration:

```nix
imports = [../../../modules/darwin/programs/omadar];
services.omadar = {
  enable = true;
  user = "mkn";
};
```

Edit defaults and shortcuts in [`settings.nix`](settings.nix).

## Setup

- Run `just verify` and `just build` before activation.
- Approve Karabiner's driver/input permissions and Rift's Accessibility access.
- Move dictation to Right Option and remove conflicting Globe bindings in dictation and Raycast.
- Verify Globe shortcuts, F1–F12, four-finger workspace swipes, three-finger drag, bar placement, and focused-window borders on the actual Mac.

## Recovery

Select **Recovery (unmodified)** in Karabiner using the mouse. If workspace indicators fail after a slow startup, restart Rift.

Before the next approved `just switch`, stop the trial border agent with `launchctl bootout gui/$(id -u)/local.omadar-tuning.borders` and remove `~/Library/LaunchAgents/local.omadar-tuning.borders.plist`. Remove the writable `~/.config/rift/config.toml`, `~/.config/sketchybar/sketchybarrc`, and `~/.config/borders/bordersrc` so Home Manager can link their Nix equivalents. Restart Rift after switching to replace the live event subscriptions.

Disabling Omadar does not restore the previous keyboard configuration or macOS preferences. Review Homebrew's `cleanup = "zap"` first: it can remove withdrawn apps and their data.

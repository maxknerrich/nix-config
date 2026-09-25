{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.services.omadar;
in {
  options.services.omadar = {
    enable = lib.mkEnableOption "the Omadar keyboard-first desktop";
    user = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "mkn";
      description = "Existing macOS and Home Manager user whose desktop Omadar manages.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.user != "" && builtins.hasAttr cfg.user config.users.users;
        message = "services.omadar.user must name an existing macOS user with a Home Manager profile.";
      }
      {
        assertion = config.homebrew.enable && config.nix-homebrew.enable;
        message = "Omadar requires the host's Homebrew and nix-homebrew integration to be enabled.";
      }
    ];

    nix-homebrew.taps."acsandmann/homebrew-tap" = inputs.omadar-homebrew-tap;
    homebrew = {
      brews = [
        {
          name = "acsandmann/tap/rift";
          # Home Manager owns the sole Rift LaunchAgent.
          start_service = false;
          restart_service = false;
        }
      ];
      casks = ["karabiner-elements"];
    };

    # Refuse competing installations/services before Homebrew or HM changes anything.
    system.checks.text = ''
      if [ -x ${lib.escapeShellArg "${config.homebrew.prefix}/bin/sketchybar"} ]; then
        echo "Omadar: a Homebrew SketchyBar already exists. Review its migration to the Nix package before activating." >&2
        exit 2
      fi
      omadar_home=${lib.escapeShellArg (config.users.users.${cfg.user}.home or "")}
      omadar_uid=$(/usr/bin/id -u ${lib.escapeShellArg cfg.user}) || exit 2
      for omadar_label in homebrew.mxcl.rift git.acsandmann.rift homebrew.mxcl.sketchybar local.omadar-tuning.borders; do
        if [ -e "$omadar_home/Library/LaunchAgents/$omadar_label.plist" ] \
          || [ -e "/Library/LaunchDaemons/$omadar_label.plist" ] \
          || /bin/launchctl print "gui/$omadar_uid/$omadar_label" >/dev/null 2>&1 \
          || /bin/launchctl print "system/$omadar_label" >/dev/null 2>&1; then
          echo "Omadar: existing $omadar_label service found. Retire it explicitly before enabling the Home Manager service." >&2
          exit 2
        fi
      done
    '';

    system.defaults = {
      NSGlobalDomain = {
        _HIHideMenuBar = lib.mkDefault true;
        "com.apple.keyboard.fnState" = lib.mkDefault false;
      };
      hitoolbox.AppleFnUsageType = lib.mkDefault "Do Nothing";
      dock.autohide = lib.mkDefault true;
    };

    home-manager.users.${cfg.user} = {
      imports = [./home.nix];
      _module.args.omadar = import ./settings.nix {
        inherit lib;
        brewPrefix = config.homebrew.prefix;
      };
    };
  };
}

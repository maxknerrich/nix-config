{
  config,
  lib,
  pkgs,
  omadar,
  ...
}: let
  # Internal keyboards can omit vendor_id, so match them explicitly.
  appleKeyboard = {
    type = "device_if";
    identifiers = [
      {is_built_in_keyboard = true;}
      {
        is_keyboard = true;
        vendor_id = 1452;
      }
      {
        is_keyboard = true;
        vendor_id = 76;
      }
    ];
  };
  superHeld = {
    type = "variable_if";
    name = "omadar_super_held";
    value = 1;
  };
  conditions = [appleKeyboard superHeld];
  exact = modifiers: {
    mandatory = modifiers;
    optional = ["caps_lock"];
  };
  # Only Caps Lock may be present in addition to the requested Shift/Ctrl layer.
  action = binding: {
    type = "basic";
    from = {
      key_code = binding.key;
      modifiers = exact binding.modifiers;
    };
    inherit conditions;
    to = [{shell_command = binding.command;}];
  };
  functionModifiers =
    builtins.foldl'
    (sets: modifier: sets ++ map (set: set ++ [modifier]) sets)
    [[]] ["shift" "control" "option" "command"];
  functionKeys = builtins.genList (i: "f${toString (i + 1)}") 12;
  functionAction = key: modifiers: {
    type = "basic";
    from = {
      key_code = key;
      modifiers = exact modifiers;
    };
    inherit conditions;
    # Function-key conversion runs after complex modifications. Synthetic Fn
    # asks Karabiner for an actual F key with the media-first keyboard setting.
    to = [
      {
        key_code = key;
        modifiers = ["fn"] ++ modifiers;
      }
    ];
  };
  # Catch-all keyboard matching would otherwise eat modifier downs and ups.
  modifier = key: {
    type = "basic";
    from = {
      key_code = key;
      modifiers = {optional = ["any"];};
    };
    inherit conditions;
    to = [{key_code = key;}];
  };
  suppressed = kind: {
    type = "basic";
    from = {
      any = kind;
      modifiers = {optional = ["any"];};
    };
    inherit conditions;
    to = [];
  };
  manipulators =
    [
      {
        type = "basic";
        from = {
          key_code = "fn";
          modifiers = {optional = ["any"];};
        };
        conditions = [appleKeyboard];
        to = [
          {
            set_variable = {
              name = "omadar_super_held";
              value = 1;
              key_up_value = 0;
            };
          }
        ];
      }
    ]
    ++ map action omadar.bindings
    ++ lib.concatMap (key: map (functionAction key) functionModifiers) functionKeys
    ++ map modifier [
      "left_shift"
      "right_shift"
      "left_control"
      "right_control"
      "left_option"
      "right_option"
      "left_command"
      "right_command"
    ]
    ++ map suppressed ["key_code" "consumer_key_code"];
  karabinerConfig = {
    global.show_in_menu_bar = true;
    profiles = [
      {
        name = "Omadar";
        selected = true;
        complex_modifications.rules = [
          {
            description = "Apple Globe as Omadar Super (actions, F keys, then suppression)";
            inherit manipulators;
          }
        ];
      }
      {
        name = "Recovery (unmodified)";
        selected = false;
        complex_modifications.rules = [];
      }
    ];
  };
  karabinerJson = (pkgs.formats.json {}).generate "omadar-karabiner.json" karabinerConfig;
  installKeyboard = pkgs.writeShellScript "omadar-install-karabiner" ''
    set -eu
    source=$1
    dir=$2
    target="$dir/karabiner.json"
    backup="$dir/karabiner.json.pre-omadar"

    /bin/mkdir -p -m 700 "$dir"
    if [ -f "$target" ] && [ ! -e "$backup" ]; then
      /usr/bin/install -m 600 "$target" "$backup"
    fi
    if [ -f "$target" ] && /usr/bin/cmp -s "$source" "$target"; then
      exit 0
    fi
    temp=$(/usr/bin/mktemp "$dir/.karabiner.json.XXXXXXXX")
    trap '/bin/rm -f "$temp"' EXIT
    /usr/bin/install -m 600 "$source" "$temp"
    /bin/mv -f "$temp" "$target"
  '';
in {
  # run honors HM dry-run; the installer handles backup and atomic replacement.
  home.activation.omadarKeyboard = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${installKeyboard} ${karabinerJson} ${lib.escapeShellArg "${config.home.homeDirectory}/.config/karabiner"}
  '';
}

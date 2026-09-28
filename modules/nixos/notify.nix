# Backup jobs push their failures to ntfy on Hades within seconds. Units listed
# in `my.notify.units` get an OnFailure= hook; until the publish token exists
# the hook is skipped rather than failing.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.notify;
in {
  options.my.notify = {
    url = lib.mkOption {
      type = lib.types.str;
      description = "ntfy topic URL to publish to.";
    };
    tokenFile = lib.mkOption {
      type = lib.types.str;
      description = "File holding an ntfy access token with write access to the topic.";
    };
    units = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Services whose failure is published.";
    };
  };

  config = lib.mkIf (cfg.units != []) {
    systemd.services =
      lib.genAttrs cfg.units (_: {onFailure = ["notify-failure@%n.service"];})
      // {
        "notify-failure@" = {
          description = "Publish the failure of %i to ntfy";
          unitConfig.ConditionPathExists = cfg.tokenFile;
          serviceConfig.Type = "oneshot";
          path = [pkgs.curl];
          scriptArgs = "%i";
          script = ''
            curl -fsS --max-time 30 \
              -H "Authorization: Bearer $(cat ${cfg.tokenFile})" \
              -H "Title: $1 failed on ${config.networking.hostName}" \
              -H "Priority: high" \
              -H "Tags: warning" \
              -d "journalctl -u $1 on ${config.networking.hostName} has the details." \
              ${cfg.url}
          '';
        };
      };
  };
}

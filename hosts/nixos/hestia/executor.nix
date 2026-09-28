# Executor (MCP gateway), one instance for agents on Zeus, Hermes and Fawkes.
# Installed by Max through Vite+ into mkn's persistent home and run as mkn's
# user service; its bearer token and credential store live in ~/.executor.
# Executor's own `executor install` binds localhost only, hence this unit.
{
  config,
  lib,
  ...
}: let
  port = config.my.services.executor.backend;
  domain = config.my.services.executor.domain;
in {
  my.services.executor = {
    backend = 4788;
    domain = "executor.ts.knerrich.com";
    expose = "tailnet";
    allowGuests = [
      "zeus"
      "hermes"
    ];
  };

  systemd.user.services.executor = {
    description = "Executor MCP gateway";
    wantedBy = ["default.target"];
    unitConfig = {
      ConditionUser = config.my.username;
      # Waits for `vp add -g executor`; start it by hand after installing.
      ConditionPathExists = "%h/.vite-plus/bin/executor";
    };
    environment = {
      PATH = lib.mkForce "%h/.vite-plus/bin:/run/current-system/sw/bin";
      EXECUTOR_DISABLE_UPDATE_CHECK = "1";
    };
    serviceConfig = {
      # Listens on the segment for Zeus and Hermes; the firewall limits who connects.
      ExecStart = "%h/.vite-plus/bin/executor daemon run --foreground --hostname 0.0.0.0 --port ${toString port} --allowed-host ${domain}";
      Restart = "on-failure";
    };
  };
}

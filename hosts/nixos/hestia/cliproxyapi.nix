# CLIProxyAPI: Fawkes, Zeus and Hermes route every coding subscription through
# it. Provider sign-ins are runtime state in its auth directory; the config is
# rewritten from Nix on every start. Clients need no key: the allowlist is the
# gate. The management API stays off until its key exists and only answers
# localhost, i.e. Caddy.
{
  config,
  lib,
  pkgs,
  ...
}: let
  package = pkgs.callPackage ../../../pkgs/cliproxyapi {};
  managementKey = config.my.secrets.hestia-cliproxy-management;
  dir = "/var/lib/cliproxyapi";
in {
  my.secrets.hestia-cliproxy-management = {};

  my.services.cliproxy = {
    backend = 8317;
    domain = "cliproxy.home.knerrich.tech";
    expose = "tailnet";
    allowGuests = [
      "zeus"
      "hermes"
    ];
  };

  users = {
    users.cliproxyapi = {
      isSystemUser = true;
      group = "cliproxyapi";
      home = dir;
    };
    groups.cliproxyapi = {};
  };

  environment.systemPackages = [package];

  systemd.services.cliproxyapi = {
    description = "CLIProxyAPI";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = [pkgs.jq];
    serviceConfig = {
      User = "cliproxyapi";
      Group = "cliproxyapi";
      StateDirectory = "cliproxyapi";
      StateDirectoryMode = "0700";
      WorkingDirectory = dir;
      LoadCredential = lib.optional managementKey.present "management-key:${managementKey.path}";
      Restart = "on-failure";
    };
    # JSON is YAML; CLIProxyAPI hashes the plaintext key when it loads the file.
    preStart = ''
      key=""
      if test -r "''${CREDENTIALS_DIRECTORY:-/nonexistent}/management-key"; then
        key=$(cat "$CREDENTIALS_DIRECTORY/management-key")
      fi
      umask 077
      jq -n --arg key "$key" '{
        "config-version": 8,
        server: {host: "", port: ${toString config.my.services.cliproxy.backend}},
        management: {"allow-remote": false, "secret-key": $key},
        oauth: {"auth-dir": "${dir}/auths"},
        observability: {usage: {"usage-statistics-enabled": true}}
      }' > ${dir}/config.yaml
    '';
    script = "exec ${lib.getExe package} -config ${dir}/config.yaml";
  };
}

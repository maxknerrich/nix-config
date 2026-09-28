# Let's Encrypt wildcards for the private names, by DNS-01 against Cloudflare.
# Only Kronos holds the token; each certificate directory is shared read-only
# into the guests that serve it (group `certs`, whose gid the guests share).
{
  config,
  lib,
  ...
}: let
  token = config.my.secrets.kronos-cloudflare-token;
  certificates = {
    "ts.knerrich.com" = "*.ts.knerrich.com";
    "zeus.ts.knerrich.com" = "*.zeus.ts.knerrich.com";
  };
in {
  my.secrets.kronos-cloudflare-token = {};

  security.acme = {
    acceptTerms = true;
    defaults = {
      inherit (config.my) email;
      dnsProvider = "cloudflare";
      credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = token.path;
      # Kronos's resolver would send ts.knerrich.com to Hestia's private zone,
      # where the challenge record never exists.
      dnsResolver = "9.9.9.9:53";
      group = "certs";
    };
    certs = lib.mapAttrs (_: domain: {inherit domain;}) certificates;
  };

  # Guests serve the preliminary self-signed certificates until the token exists.
  systemd.services = lib.mapAttrs' (name: _:
    lib.nameValuePair "acme-order-renew-${name}" {
      unitConfig.ConditionPathExists = token.path;
    })
  certificates;

  # Own the shared directories before microvm's tmpfiles rule could create
  # them for its own user (the earliest tmpfiles file wins).
  systemd.tmpfiles.settings."00-acme-shares" = lib.mapAttrs' (name: _:
    lib.nameValuePair "/var/lib/acme/${name}" {
      d = {
        user = "acme";
        group = "certs";
        mode = "0750";
      };
    })
  certificates;
}

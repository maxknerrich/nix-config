# Zeus: the coding-agent VM. Its home volume is disposable by design (btrbk on
# Kronos is the only protection); the store overlay is scratch space.
{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../../modules/nixos/guest.nix
    ../../../modules/nixos/home.nix
  ];

  networking.hostName = "zeus";

  my.guest = {
    certificate = "dev.knerrich.tech";
    nixLd = true;
  };

  # Agent tools that are missing from, or lag in, the stable release; Fawkes
  # uses the same pinned unstable versions.
  nixpkgs.overlays = [
    (_: prev: {
      inherit (inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}) ccusage codex herdr;
    })
  ];

  # nix build, nix develop and just verify work inside the guest; its store
  # overlay is the scratch volume.
  nix.settings.max-jobs = 2;

  my.secrets.zeus-github-key.owner = config.my.username;

  # T3 Code owns its launcher, unit and updates (its install script and
  # `t3 service install`); Nix provides the lingering user, curl and nix-ld.
  users.users.${config.my.username}.linger = true;
  environment.systemPackages = [pkgs.curl];

  # T3 listens on localhost; Caddy serves it under the dev wildcard, where an
  # exact name wins over the port rule below.
  my.services.t3 = {
    backend = 3773;
    domain = "t3.dev.knerrich.tech";
    expose = "tailnet";
  };

  # <port>.dev.knerrich.tech → localhost:<port> for ports 3000–9999 only,
  # which keeps system ports and Caddy's admin API out of reach. Dev servers
  # stay on localhost; HMR websockets pass through.
  services.caddy = {
    enable = true;
    virtualHosts."https://*.dev.knerrich.tech".extraConfig = ''
      tls /run/certs/fullchain.pem /run/certs/key.pem
      @dev header_regexp port Host ^([3-9][0-9]{3})\.dev\.knerrich\.tech$
      handle @dev {
        reverse_proxy localhost:{re.port.1}
      }
      handle {
        respond 404
      }
    '';
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [443];
}

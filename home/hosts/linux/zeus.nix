{
  lib,
  osConfig,
  ...
}: let
  # Zeus's own GitHub key, decrypted by agenix to tmpfs; never on the home volume.
  githubKey = osConfig.my.secrets.zeus-github-key;
in {
  imports = [
    ../../linux/tui.nix
    ../../base/tui/pi.nix
  ];

  programs = lib.mkIf githubKey.present {
    # Sign with Zeus's key instead of the Proton Pass key, which Zeus never holds.
    git.settings.user.signingKey = lib.mkForce githubKey.path;

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com" = {
        IdentityFile = githubKey.path;
        IdentitiesOnly = true;
      };
    };
  };
}

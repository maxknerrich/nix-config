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

  # T3 owns its unit (`t3 service install`), whose server listens on 127.0.0.1
  # unless T3CODE_HOST says otherwise. Listening everywhere lets paired devices
  # and Hades's check reach it; Zeus's firewall limits port 3773 to those.
  xdg.configFile."systemd/user/t3code.service.d/listen.conf".text = ''
    [Service]
    Environment=T3CODE_HOST=0.0.0.0
  '';

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

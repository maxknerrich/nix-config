{config, ...}: let
  initrdHostKey = "/persist/secrets/initrd/ssh_host_ed25519_key";
in {
  boot.initrd = {
    network.ssh = {
      enable = true;
      port = 2222;
      authorizedKeys = config.users.users.mkn.openssh.authorizedKeys.keys;
      hostKeys = [initrdHostKey];
    };

    systemd = {
      extraBin.systemd-tty-ask-password-agent = "${config.boot.initrd.systemd.package}/bin/systemd-tty-ask-password-agent";
      users.root.shell = "/bin/sh";
    };
  };
}

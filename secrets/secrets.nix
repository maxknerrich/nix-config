let
  # Recovery identity: Max's Proton Pass SSH key. Every secret encrypts to it.
  mkn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMU+MXkqxIDEg9IPVCluImSjRByx71QCQdveLQNifwGq Max";

  # Host keys: each host decrypts only its own runtime secrets. A guest's key
  # is generated on its first boot and added here before its secrets exist.
  kronos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGzJG2gc2lhki5QcshrKvnE66vc03xOnaqScfqPjmcLD kronos";
  zeus = null;
  hestia = null;
  hades = null;

  for = host:
    [mkn]
    ++ (
      if host == null
      then []
      else [host]
    );
in {
  "kronos-luks.age".publicKeys = [mkn];
  "kronos-console-password.age".publicKeys = for kronos;
  "kronos-cloudflare-token.age".publicKeys = for kronos;
  "kronos-ntfy-token.age".publicKeys = for kronos;

  "zeus-github-key.age".publicKeys = for zeus;

  "hestia-cliproxy-management.age".publicKeys = for hestia;

  "hades-kopia-home.age".publicKeys = for hades;
  "hades-offsite.age".publicKeys = for hades;
}

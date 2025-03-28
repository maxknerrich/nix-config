## Adding a new host

1. cat the system-level public key(/etc/ssh/ssh_host_ed25519_key.pub) of the new host, and send it to an old host which has already been configured.
2. On the old host:
  1. Add the public key to secrets.nix, and rekey all the secrets via sudo agenix -r -i /etc/ssh/ssh_host_ed25519_key.
  2. Commit and push the changes to nix-secrets.
3. On the new host:
   1. Clone this repo and run nixos-rebuild switch to deploy it, all the secrets will be decrypted automatically via the host private key.

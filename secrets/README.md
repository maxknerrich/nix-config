# Agenix secrets

Only encrypted `*.age` files and their public-recipient rules belong here.
Never commit age identities, decrypted values, temporary key files, or editor
backups.

The `kronos-luks.age` file is an installation/recovery secret. Agenix
encrypts it to the Proton Pass SSH key listed in `secrets.nix`; its private key
is supplied transiently with `pass-cli run` and is never written to the
repository. The secret must be decrypted on the deployment Mac and must not be
declared as a runtime `age.secrets` entry on Kronos.

fmt:
    nix fmt

check:
    nix flake check

build:
    nix build .#darwinConfigurations.fawkes.system --no-link

# Create or edit a declared Agenix secret using the Proton Pass SSH key.
secret name:
    PROTON_PASS_AGENT_REASON="Edit the Agenix secret {{ name }}.age" PROTON_SSH_PRIVATE_KEY="pass://Personal/Max/Private key" SECRETS_DIR="$PWD/secrets" SECRET_NAME={{ quote(name) }} pass-cli run -- bash -c 'cd "$SECRETS_DIR" && RULES=./secrets.nix agenix -e "$SECRET_NAME.age" -i <(printf "%s\n" "$PROTON_SSH_PRIVATE_KEY") </dev/tty >/dev/tty 2>/dev/tty'

# Install a discovered NixOS host destructively with secrets supplied by Proton Pass.
install host ip:
    @printf 'This irreversibly wipes the configured disks for %s.\n' {{quote(host)}}; prompt=$(printf 'Type WIPE %s to continue: ' {{quote(host)}}); read -r -p "$prompt" reply; test "$reply" = {{quote("WIPE " + host)}}
    PROTON_PASS_AGENT_REASON={{quote("Install " + host + " with its LUKS credential and SSH host keys")}} INSTALL_LUKS_PASSPHRASE={{quote("pass://KDE/" + host + "/Keys.LUKS")}} INSTALL_INITRD_HOST_KEY={{quote("pass://KDE/" + host + "/initrd.Private key")}} INSTALL_SYSTEM_HOST_KEY={{quote("pass://KDE/" + host + "/Host Key.Private key")}} REPO_ROOT="$PWD" HOST={{quote(host)}} LUKS_REMOTE_PATH={{quote("/tmp/" + host + "-luks.key")}} TARGET={{quote("nixos@" + ip)}} pass-cli run -- sh -c 'set -eu; umask 077; temp_dir=$(mktemp -d); trap '\''rm -rf "$temp_dir"'\'' 0; luks_key="$temp_dir/luks.key"; extra_files="$temp_dir/extra-files"; initrd_key="$extra_files/persist/secrets/initrd/ssh_host_ed25519_key"; system_key="$extra_files/persist/etc/ssh/ssh_host_ed25519_key"; mkdir -p "$(dirname "$initrd_key")" "$(dirname "$system_key")"; chmod 0755 "$extra_files/persist" "$extra_files/persist/etc" "$(dirname "$system_key")"; printf "%s" "$INSTALL_LUKS_PASSPHRASE" >"$luks_key"; printf "%s\n" "$INSTALL_INITRD_HOST_KEY" >"$initrd_key"; printf "%s\n" "$INSTALL_SYSTEM_HOST_KEY" >"$system_key"; unset INSTALL_LUKS_PASSPHRASE INSTALL_INITRD_HOST_KEY INSTALL_SYSTEM_HOST_KEY; ssh-keygen -y -P "" -f "$initrd_key" >"$initrd_key.pub"; ssh-keygen -y -P "" -f "$system_key" >"$system_key.pub"; chmod 0644 "$initrd_key.pub" "$system_key.pub"; ssh-keygen -lf "$initrd_key.pub"; ssh-keygen -lf "$system_key.pub"; cd "$REPO_ROOT"; nix run github:nix-community/nixos-anywhere -- --flake "$REPO_ROOT#$HOST" --build-on remote --disk-encryption-keys "$LUKS_REMOTE_PATH" "$luks_key" --extra-files "$extra_files" "$TARGET"'

# Unlock a discovered NixOS host using its Proton Pass LUKS credential.
unlock host ip:
    PROTON_PASS_AGENT_REASON={{ quote("Unlock " + host + " remotely") }} UNLOCK_LUKS_PASSPHRASE={{ quote("pass://KDE/" + host + "/Keys.LUKS") }} UNLOCK_INITRD_HOST_KEY={{ quote("pass://KDE/" + host + "/initrd.Public key") }} IP={{ quote(ip) }} pass-cli run -- sh -c 'set -eu; umask 077; known_hosts=$(mktemp); trap '\''rm -f "$known_hosts"'\'' 0; luks_passphrase=$UNLOCK_LUKS_PASSPHRASE; initrd_host_key=$UNLOCK_INITRD_HOST_KEY; unset UNLOCK_LUKS_PASSPHRASE UNLOCK_INITRD_HOST_KEY; printf "[%s]:2222 %s\n" "$IP" "$initrd_host_key" >"$known_hosts"; printf "%s\n" "$luks_passphrase" | ssh -tt -p 2222 -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$known_hosts" "root@$IP" /bin/systemd-tty-ask-password-agent'

# Build the headless x86_64 NixOS installer ISO (requires a Linux builder).
iso:
    nix build ./nixos-installer#nixosConfigurations.installer.config.system.build.isoImage

# Apply the currently locked configuration.
switch:
    sudo -H darwin-rebuild switch --flake .#fawkes

# Update flake inputs without activating them.
update:
    nix flake update

# Update, validate, and activate the new configuration.
upgrade:
    just update
    just doctor
    just switch

doctor:
    just fmt
    just check
    just build

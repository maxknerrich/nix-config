fmt:
    nix fmt

check:
    nix flake check --all-systems --no-build
    nix eval --raw .#nixosConfigurations.kronos.config.system.build.toplevel.drvPath >/dev/null
    nix flake check ./nixos-installer --all-systems --no-build

shellcheck:
    nix shell --inputs-from . nixpkgs#shellcheck --command shellcheck scripts/install-nixos.sh scripts/unlock-initrd.sh

build:
    nix build .#darwinConfigurations.fawkes.system --no-link

# Create or edit a declared Agenix secret using the Proton Pass SSH key.
secret name:
    PROTON_PASS_AGENT_REASON="Edit the Agenix secret {{ name }}.age" PROTON_SSH_PRIVATE_KEY="pass://Personal/Max/Private key" SECRETS_DIR="$PWD/secrets" SECRET_NAME={{ quote(name) }} pass-cli run -- bash -c 'cd "$SECRETS_DIR" && RULES=./secrets.nix agenix -e "$SECRET_NAME.age" -i <(printf "%s\n" "$PROTON_SSH_PRIVATE_KEY") </dev/tty >/dev/tty 2>/dev/tty'

# Install a discovered NixOS host destructively with secrets supplied by Proton Pass.
install host ip:
    @printf 'This irreversibly wipes the configured disks for %s.\n' {{ quote(host) }}; prompt=$(printf 'Type WIPE %s to continue: ' {{ quote(host) }}); read -r -p "$prompt" reply; test "$reply" = {{ quote("WIPE " + host) }}
    PROTON_PASS_AGENT_REASON={{ quote("Install " + host + " with its LUKS credential and SSH host keys") }} INSTALL_LUKS_PASSPHRASE={{ quote("pass://KDE/" + host + "/Keys.LUKS") }} INSTALL_INITRD_HOST_KEY={{ quote("pass://KDE/" + host + "/initrd.Private key") }} INSTALL_SYSTEM_HOST_KEY={{ quote("pass://KDE/" + host + "/Host Key.Private key") }} REPO_ROOT="$PWD" HOST={{ quote(host) }} LUKS_REMOTE_PATH={{ quote("/tmp/" + host + "-luks.key") }} TARGET={{ quote("nixos@" + ip) }} pass-cli run -- "$PWD/scripts/install-nixos.sh"

# Unlock a discovered NixOS host using its Proton Pass LUKS credential.
unlock host ip:
    PROTON_PASS_AGENT_REASON={{ quote("Unlock " + host + " remotely") }} UNLOCK_LUKS_PASSPHRASE={{ quote("pass://KDE/" + host + "/Keys.LUKS") }} UNLOCK_INITRD_HOST_KEY={{ quote("pass://KDE/" + host + "/initrd.Public key") }} IP={{ quote(ip) }} pass-cli run -- "$PWD/scripts/unlock-initrd.sh"

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
    just --fmt --check
    just fmt
    just shellcheck
    just check
    just build

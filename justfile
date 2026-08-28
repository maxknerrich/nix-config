fmt:
    nix fmt

check:
    nix flake check

build:
    nix build .#darwinConfigurations.fawkes.system --no-link

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

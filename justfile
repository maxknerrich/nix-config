fmt:
    nix fmt

check:
    nix flake check

build:
    nix build .#darwinConfigurations.fawkes.system --no-link

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

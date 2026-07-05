fmt:
    nix fmt

check:
    nix flake check

build:
    nix build .#darwinConfigurations.fawkes.system --no-link

switch:
    sudo -H darwin-rebuild switch --flake .#fawkes

doctor:
    just fmt
    just check
    just build

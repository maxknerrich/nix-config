# nix-config

Nix configuration for Max's Mac (`fawkes`, `aarch64-darwin`).

## Bootstrap

Place this repo at `/Users/mkn/nix-config`, then run:

```sh
nix flake lock
sudo -H darwin-rebuild switch --flake .#fawkes
```

If needed for the first run:

```sh
sudo -H nix run nix-darwin -- switch --flake .#fawkes
```

## Daily commands

```sh
just fmt
just doctor
just switch
```

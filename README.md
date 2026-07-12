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

## Configuration

- Shared shell and CLI packages: `modules/users/mkn/terminal.nix`
- Focused user modules: `git.nix`, `theme.nix`, `host-banner.nix`, and `pi.nix`
- `fawkes` GUI applications: `modules/machines/darwin/fawkes/apps.nix`
- Host-specific macOS settings: `modules/machines/darwin/fawkes/system.nix`

## Daily commands

```sh
just switch   # Apply the current lock file.
just update   # Update the lock file only.
just upgrade  # Update, validate, and switch.
just doctor   # Format, check, and build.
```

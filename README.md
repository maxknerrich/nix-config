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

## Headless NixOS installer

The `nixos-installer/` configuration builds a minimal `x86_64-linux` ISO with
DHCP, SSH key authentication for the `nixos` user, flakes, disko, and recovery
tools. Disk formatting and installation remain manual.

Changes to the installer or its flake inputs publish a new ISO to the rolling
[`nixos-installer-latest`](https://github.com/maxknerrich/nix-config/releases/tag/nixos-installer-latest)
GitHub release. Build it locally on Linux or with a configured Linux builder:

```sh
just iso
```

The ISO is written beneath `result/iso/`. After booting it, find its address
from DHCP or the local console and connect with `ssh nixos@<installer-ip>`.

## Daily commands

```sh
just switch   # Apply the current lock file.
just update   # Update the lock file only.
just upgrade  # Update, validate, and switch.
just doctor   # Format, check, and build.
just iso      # Build the headless NixOS installer ISO.
```

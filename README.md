# nix-config

Nix configuration for Max's infrastructure:

- `fawkes`: macOS laptop, `aarch64-darwin`, using nix-darwin and Home Manager.
- `kronos`: NixOS storage and KVM host, `x86_64-linux`, using stable NixOS.
- `nixos-installer/`: independently pinned headless installer.

## Layout

```text
hosts/
  darwin/fawkes/        # macOS system composition, applications and preferences
  nixos/kronos/         # Hardware, disks, networking, unlock and virtualization
home/
  base/                # Cross-platform core, terminal tools and GUI configuration
  darwin/              # macOS user-environment profile and integrations
  linux/               # Minimal and full terminal user-environment profiles
  hosts/               # Per-platform, per-host Home Manager entry points
  dotfiles/            # Pi, shared agent and Zed files
modules/
  common/identity.nix   # Shared system identity options and defaults
  darwin/              # macOS account, Nix and Home Manager integration
  nixos/base.nix       # Linux admin account, locale and Nix defaults
nixos-installer/
scripts/
secrets/
```

`hosts/` owns system composition and hardware or site-specific settings.
`modules/` contains reusable system configuration. All Home Manager configuration
and user files live under `home/`; see its [layout and import examples](home/README.md).

The constructors in `hosts/darwin/default.nix` and `hosts/nixos/default.nix`
discover directories containing `configuration.nix`. Hosts and their imported
modules own dependencies such as Home Manager, Disko, Agenix and impermanence.
The current constructors target Apple Silicon Darwin and x86-64 NixOS respectively.

`modules/nixos/base.nix` is for Max-administered Linux hosts. It includes the
`mkn` admin account, trusted Nix access and passwordless sudo. It is not a sandbox
policy for agent accounts. KVM and libvirt access remain specific to Kronos.

## Bootstrap Fawkes

Place this repo at `/Users/mkn/nix-config`, then run:

```sh
sudo -H darwin-rebuild switch --flake .#fawkes
```

If needed for the first run:

```sh
sudo -H nix run nix-darwin -- switch --flake .#fawkes
```

## Headless NixOS installer

The `nixos-installer/` configuration builds a minimal `x86_64-linux` ISO with
DHCP, SSH key authentication for the `nixos` user, flakes, disko, and recovery
tools. Disk formatting and installation remain manual.

Changes to the installer or its flake inputs publish a verified, immutable
[GitHub release](https://github.com/maxknerrich/nix-config/releases/latest).
Build it locally on Linux or with a configured Linux builder:

```sh
just iso
```

The ISO is written beneath `result/iso/`. After booting it, find its address
from DHCP or the local console and connect with `ssh nixos@<installer-ip>`.

`just install host ip` is destructive and assumes Kronos's encrypted-disk and
`/persist` key layout, plus the corresponding Proton Pass item. It is not a
generic guest installer. `just unlock host ip` handles remote initrd unlock.

The installer has its own flake and lockfile so desktop changes do not change
recovery media. Main-configuration validation does not publish installer releases.

## Daily commands

```sh
just hooks    # Enable formatting and validation Git hooks for this clone.
just verify   # Check formatting, shell scripts and all declared hosts; no activation.
just build    # Build Fawkes without activating it.
just switch   # Apply Fawkes's current lock file.
just update   # Update the main lock file only.
just upgrade  # Update, validate, and switch Fawkes.
just doctor   # Format, verify, and build Fawkes.
just iso      # Build the headless NixOS installer ISO.
```

`just check` evaluates every declared Darwin and NixOS host to its system
derivation, plus the independent installer flake. It does not build or activate
systems, update lockfiles, or connect to hosts. CI runs the same checks.

## Design references

- [Ryan4Yin's home configuration](https://github.com/ryan4yin/nix-config/tree/main/home):
  shared core, TUI and GUI configuration composed by platform and host.
- [Truxnell's goals](https://truxnell.github.io/nix-config/overview/goals/): simple
  administration, stable core systems and reproducibility.

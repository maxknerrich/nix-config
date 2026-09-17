# nix-config

Nix configuration for Max's infrastructure:

- `fawkes`: macOS laptop, `aarch64-darwin`, using nix-darwin and Home Manager.
- `kronos`: NixOS storage and KVM host, `x86_64-linux`, using stable NixOS.
- `nixos-installer/`: independently pinned headless installer.

## Layout

```text
hosts/
  darwin/
    default.nix          # Discover Darwin hosts and construct flake outputs
    fawkes/
      configuration.nix  # System composition
      home.nix           # User environment and optional features
      apps.nix           # Homebrew applications
      system.nix         # macOS preferences
  nixos/
    default.nix          # Discover NixOS hosts and construct flake outputs
    kronos/              # Hardware, disks, networking, unlock, virtualization
home/
  default.nix            # Shared user baseline
  shell.nix              # Fish, aliases, Bat, Eza, Zoxide, Mosh, Tree
  prompt.nix             # Starship and host banner
  theme.nix
  optional/
    development.nix      # Development CLIs and Vite Plus shell initialization
    git.nix              # Personal Git identity and signing policy
    herdr.nix            # Herdr and its window-title plugin
    pi.nix               # Pi configuration links, not installation or credentials
modules/
  common/identity.nix    # Shared identity options and defaults
  darwin/                # macOS account, Nix and Home Manager integration
  nixos/base.nix         # Linux admin account, locale and Nix defaults
  users/mkn/dotfiles/    # Existing live-linked files; see below
nixos-installer/
scripts/
secrets/
```

Hosts choose what to import. `modules/` contains reusable system configuration;
`home/` contains Home Manager configuration. Hardware and site-specific policy
stay with the host. There is no automatic import of optional features.

The host constructors only discover directories containing `configuration.nix`
and construct outputs. Hosts and their imported modules own dependencies such as
Home Manager, Disko, Agenix and impermanence. The current constructors target
Apple Silicon Darwin and x86-64 NixOS respectively.

## Shared defaults and opt-ins

Importing `home/default.nix` gives the `mkn` user the shared shell, prompt, theme,
and Home Manager basics. It does not include development tools, Git signing,
Herdr, Pi, or desktop applications.

Each host's `home.nix` selects optional features. For example, a future host could
use the shell baseline plus Pi configuration:

```nix
# hosts/nixos/zeus/home.nix, after adding that host's Home Manager integration
{
  imports = [
    ../../../home
    ../../../home/optional/pi.nix
  ];
}
```

Fawkes explicitly imports all its existing optional features in
`hosts/darwin/fawkes/home.nix`. Adding an optional file does nothing until a host
imports it. Prefer ordinary NixOS and Home Manager options over custom wrappers.

Kronos does not use Home Manager yet. Future NixOS integration should use a Home
Manager release compatible with the host's nixpkgs release and pass `inputs` and
`my = config.my` through `home-manager.extraSpecialArgs`. Set each new host's
Home Manager state version deliberately rather than updating existing hosts'
state versions during upgrades.

`modules/nixos/base.nix` is the baseline for Max-administered Linux hosts. It
includes the `mkn` admin account, trusted Nix access and passwordless sudo. It is
not a sandbox policy for agent accounts. KVM and libvirt access remain specific
to Kronos.

### Live-linked dotfiles

Pi and Zed currently use out-of-store symlinks into
`modules/users/mkn/dotfiles/`. That directory intentionally stays at its existing
path so rearranging Nix files does not break the active user environment before
a rebuild. Its contents are not changed by this structural refactor.

The Pi opt-in expects the repository at `~/nix-config`. It manages configuration,
not the Pi executable, auth, sessions, or runtime state. Remote deployment and any
future dotfile relocation need a separate migration; sharing configuration does
not mean sharing personal credentials.

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

- [Ryan4Yin's nix-config](https://github.com/ryan4yin/nix-config): separate hosts,
  reusable system configuration and cross-platform Home Manager configuration.
- [Truxnell's goals](https://truxnell.github.io/nix-config/overview/goals/): simple
  administration, stable core systems and reproducibility.

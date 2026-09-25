# Nix config

This repository manages Max's macOS devices, NixOS hypervisors, and NixOS VMs.

Do not commit secrets, auth files, sessions, or runtime state. Encrypted `.age` files under `secrets/` are allowed. Do not activate a host unless Max asks.

## Terms

- **you** means the agent changing this repository
- **me** means Max, the owner
- **host** means one of Max's devices or servers
- **installer** means the custom `nixos-installer` ISO
- **user** means the main Linux/macOS user, `mkn`

## Repository layout

```text
hosts/
  darwin/<host>/             # Complete nix-darwin host composition
  nixos/<host>/              # Complete NixOS host composition and hardware config
home/
  base/core/                 # Basic cross-platform shell: Fish, Starship, Zoxide, theme
  base/tui/                  # Optional terminal development tools
  base/gui/                  # Optional graphical application configuration
  darwin/                    # Shared macOS Home Manager profile and integrations
  linux/                     # Minimal and full Linux Home Manager profiles
  hosts/<platform>/<host>.nix # Per-host Home Manager composition and overrides
  dotfiles/                  # Files linked by Home Manager
modules/
  common/                    # Reusable system modules shared across platforms
  darwin/                    # Reusable nix-darwin modules
    programs/<name>/         # Self-contained program integrations, such as Omadar
  nixos/                     # Reusable NixOS modules
nixos-installer/             # Independently pinned installer ISO
scripts/                     # Installation and recovery scripts
secrets/                     # Agenix rules and encrypted secrets
t3code/                      # T3 Code submodule, not Nix configuration
```

Put settings used by one host under `hosts/<platform>/<host>/`. Put reusable system configuration under `modules/`. Personal user configuration belongs under `home/`.

Self-contained program integrations belong under `modules/darwin/programs/<name>/`. Keep their implementation together, including private Home Manager adapters and helper scripts. The public entry point is `default.nix`; a private `home.nix` may configure the selected user. This is module implementation, not a place for unrelated personal dotfiles or per-host preferences. Host imports and enablement remain explicit.

Home Manager imports are explicit. Put shared user settings in the narrowest `home/base/` group, platform integrations in `home/darwin/` or `home/linux/`, and select them from `home/hosts/`. Adding a file must not enable it automatically.

Run `just verify` after Nix changes. Do not update lock files unless the task requires it.

## Host naming

- Devices use mythological creatures, such as `fawkes` or `blackjack`.
- Bare-metal hosts and hypervisors use Greek Titans, such as `kronos` or `atlas`.
- VMs and servers use Greek gods, such as `zeus` or `athena`.

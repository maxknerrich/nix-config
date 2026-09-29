# Home Manager

Home configuration is split by capability and composed with explicit imports. Adding a file does not enable it.

- `base/core/` is the basic shell used on interactive hosts. It includes Fish, Starship, Zoxide, Bat, Eza, and the shared theme.
- `base/tui/` adds development tools and Herdr. Pi remains a separate opt-in module.
- `base/gui/` contains shared desktop application configuration.
- `darwin/` composes the macOS profile and platform integrations.
- `linux/core.nix` provides the basic shell for headless hosts.
- `linux/tui.nix` adds the full terminal development profile.
- `hosts/` selects profiles and host-specific overrides.
- `dotfiles/` contains files linked by Home Manager.

Fawkes uses the Darwin profile and opts into Pi. Kronos, Hestia and Hades import `linux/core.nix`; Zeus imports `linux/tui.nix` and Pi. NixOS hosts load their profile from `hosts/linux/<hostname>.nix` through `modules/nixos/home.nix`.

Pi configuration does not include credentials, sessions, or runtime state. Those stay outside this repository.

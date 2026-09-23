# Home Manager configuration

This follows [Ryan4Yin's home layout](https://github.com/ryan4yin/nix-config/tree/main/home):
shared configuration grouped by purpose, platform entry points, and one entry per
host. Imports are explicit rather than automatically scanning directories.

```text
home/
├── base/
│   ├── home.nix                 # Identity, state version and Home Manager basics
│   ├── core/
│   │   ├── default.nix          # Minimal shared shell environment
│   │   ├── shells/default.nix   # Fish, aliases and everyday CLI tools
│   │   ├── starship.nix         # Prompt and host banner
│   │   ├── theme.nix
│   │   └── git.nix              # Personal Git identity and signing
│   ├── tui/
│   │   ├── default.nix          # Git, development tools and Herdr
│   │   ├── dev-tools.nix
│   │   ├── herdr.nix
│   │   └── pi.nix               # Selected separately by each host
│   └── gui/
│       ├── default.nix
│       ├── zed-editor.nix
│       └── terminal/ghostty.nix
├── darwin/
│   ├── default.nix              # Shared core, TUI and GUI plus macOS integrations
│   ├── terminal.nix             # Homebrew Ghostty package and macOS settings
│   └── proton-pass.nix          # Desktop SSH-agent socket and CLI package
├── linux/
│   ├── core.nix                 # Minimal headless user environment
│   └── tui.nix                  # Core plus the full terminal-tool profile
├── hosts/
│   └── darwin/fawkes.nix        # Platform selection, Pi opt-in and local overrides
└── dotfiles/                    # Pi, shared agent and Zed files
```

## Composition

Each system configuration references one file under `home/hosts/<platform>/`.
That file selects its platform profile, adds individual features, and defines
host-specific overrides.

Fawkes imports `home/darwin/` and explicitly opts into `base/tui/pi.nix`. Its
Proton Drive links stay in the host entry. Shared Ghostty settings live under
`base/gui/terminal/`; Homebrew installation and macOS keyboard settings are not
part of the shared GUI configuration.

The minimal core profile includes the shell, prompt and theme. It does not enable
Git signing, development tools, Herdr, Pi or GUI applications. The full TUI profile
adds Git signing, development tools and Herdr. Pi is not enabled by either default
profile.

For a future Linux host with the shared shell and Pi configuration:

```nix
# home/hosts/linux/zeus.nix
{
  imports = [
    ../../linux/core.nix
    ../../base/tui/pi.nix
  ];
}
```

Use `../../linux/tui.nix` instead of `core.nix` for the full terminal-tool profile,
or import individual files for a smaller selection. Adding a file to a directory
does not enable it. There is no Linux desktop profile until one is needed.

Kronos still has no Home Manager integration. When adding a Linux host's user
environment, use a Home Manager release compatible with its nixpkgs release and
pass `inputs` and `my = config.my` through `home-manager.extraSpecialArgs`. Choose
its initial state version deliberately; do not bump existing hosts' state
versions as part of routine upgrades.

## Dotfiles and live links

Pi and Zed use out-of-store symlinks into `home/dotfiles/`, with the repository
expected at `~/nix-config`. The Pi module manages configuration, not installation,
auth, sessions or runtime state. Sharing configuration does not share credentials.

Moving these files requires migrating their live user links as well as updating
Nix paths. Restart Pi after moving its extensions so loaded code uses the new
locations.

The earlier link-only migration keeps its Home Manager file package rooted at
`~/.local/state/nix-config/home-layout-migration`. After a normal rebuild has
activated the relocated dotfiles, that temporary root can be removed.

# nix-config

Nix configuration for Max's infrastructure:

- `fawkes`: Apple Silicon MacBook managed by nix-darwin and Home Manager
- `kronos`: x86-64 NixOS storage and KVM host
- `nixos-installer`: independently pinned headless recovery and installation ISO

## Layout

- `hosts/` composes complete systems and holds host-specific settings.
- `modules/` contains reusable system modules.
- `home/` contains Home Manager profiles and dotfiles.
- `nixos-installer/` contains the standalone installer flake.
- `scripts/` contains installation and recovery scripts.
- `secrets/` contains Agenix rules and encrypted secrets.

See [`home/README.md`](home/README.md) for Home Manager composition.

## Commands

```sh
just verify   # Check formatting, scripts, hosts, and the installer without activation
just build    # Build Fawkes without activating it
just switch   # Build and activate Fawkes
just update   # Update the main lock file
just upgrade  # Update, verify, and activate Fawkes
just iso      # Build the NixOS installer ISO
```

For the first Fawkes activation:

```sh
sudo -H nix run nix-darwin -- switch --flake .#fawkes
```

`just install host ip` formats disks and installs a host. It currently assumes Kronos's encrypted-disk layout and Proton Pass secret. `just unlock host ip` handles remote initrd unlock.

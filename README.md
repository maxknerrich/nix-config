# nix-config

Nix configuration for Max's infrastructure:

- `fawkes`: Apple Silicon MacBook managed by nix-darwin and Home Manager
- `kronos`: x86-64 NixOS storage host and microvm hypervisor for four guests:
  - `zeus`: coding agents (T3 Code, pi, codex) with HTTPS dev domains
  - `hestia`: CLIProxyAPI, Executor, private DNS for `home.knerrich.tech`
  - `hades`: Kopia server, Proton Drive mirror, offsite backup, Gatus, ntfy
  - `hermes`: empty guest for assistant agents
- `nixos-installer`: independently pinned headless recovery and installation ISO

## Layout

- `hosts/` composes complete systems and holds host-specific settings.
- `modules/` contains reusable system modules.
- `home/` contains Home Manager profiles and dotfiles.
- `nixos-installer/` contains the standalone installer flake.
- `scripts/` contains installation and recovery scripts.
- `secrets/` contains Agenix rules and encrypted secrets.
- `pkgs/` contains packages missing from nixpkgs.
- `tailscale/policy.hujson` is the tailnet policy, applied by hand.

See [`home/README.md`](home/README.md) for Home Manager composition.

## Commands

```sh
just verify   # Check formatting, scripts, hosts, and the installer without activation
just build    # Build Fawkes without activating it
just switch   # Build and activate Fawkes
just update   # Update the main lock file
just upgrade  # Update, verify, and activate Fawkes
just iso      # Build the NixOS installer ISO
just deploy kronos  # Build on Kronos, activate it and stage its guests
just restart zeus   # Restart Zeus into its staged configuration
```

Guests are `nixosConfigurations` deployed only through Kronos. A deploy restarts every changed guest except Zeus, which keeps its agent sessions until `just restart zeus`.

For the first Fawkes activation:

```sh
sudo -H nix run nix-darwin -- switch --flake .#fawkes
```

`just install host ip` formats disks and installs a host. It currently assumes Kronos's encrypted-disk layout and Proton Pass secret. `just unlock host ip` handles remote initrd unlock.

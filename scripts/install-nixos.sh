#!/usr/bin/env bash
set -euo pipefail

: "${REPO_ROOT:?}"
: "${HOST:?}"
: "${LUKS_REMOTE_PATH:?}"
: "${TARGET:?}"
: "${INSTALL_LUKS_PASSPHRASE:?}"
: "${INSTALL_INITRD_HOST_KEY:?}"
: "${INSTALL_SYSTEM_HOST_KEY:?}"

umask 077
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

luks_key="$temp_dir/luks.key"
extra_files="$temp_dir/extra-files"
initrd_key="$extra_files/persist/secrets/initrd/ssh_host_ed25519_key"
system_key="$extra_files/persist/etc/ssh/ssh_host_ed25519_key"

mkdir -p "$(dirname "$initrd_key")" "$(dirname "$system_key")"
chmod 0755 \
  "$extra_files/persist" \
  "$extra_files/persist/etc" \
  "$(dirname "$system_key")"

printf '%s' "$INSTALL_LUKS_PASSPHRASE" >"$luks_key"
printf '%s\n' "$INSTALL_INITRD_HOST_KEY" >"$initrd_key"
printf '%s\n' "$INSTALL_SYSTEM_HOST_KEY" >"$system_key"
unset INSTALL_LUKS_PASSPHRASE INSTALL_INITRD_HOST_KEY INSTALL_SYSTEM_HOST_KEY

ssh-keygen -y -P '' -f "$initrd_key" >"$initrd_key.pub"
ssh-keygen -y -P '' -f "$system_key" >"$system_key.pub"
chmod 0644 "$initrd_key.pub" "$system_key.pub"
ssh-keygen -lf "$initrd_key.pub"
ssh-keygen -lf "$system_key.pub"

cd "$REPO_ROOT"
nix run github:nix-community/nixos-anywhere -- \
  --flake "$REPO_ROOT#$HOST" \
  --build-on remote \
  --disk-encryption-keys "$LUKS_REMOTE_PATH" "$luks_key" \
  --extra-files "$extra_files" \
  "$TARGET"

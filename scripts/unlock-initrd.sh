#!/usr/bin/env bash
set -euo pipefail

: "${IP:?}"
: "${UNLOCK_LUKS_PASSPHRASE:?}"
: "${UNLOCK_INITRD_HOST_KEY:?}"

umask 077
known_hosts=$(mktemp)
trap 'rm -f "$known_hosts"' EXIT

luks_passphrase=$UNLOCK_LUKS_PASSPHRASE
initrd_host_key=$UNLOCK_INITRD_HOST_KEY
unset UNLOCK_LUKS_PASSPHRASE UNLOCK_INITRD_HOST_KEY

printf '[%s]:2222 %s\n' "$IP" "$initrd_host_key" >"$known_hosts"
printf '%s\n' "$luks_passphrase" | ssh -tt \
  -F /dev/null \
  -p 2222 \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o GlobalKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$known_hosts" \
  "root@$IP" \
  /bin/systemd-tty-ask-password-agent

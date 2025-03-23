# infrastructure
This repo contains the code I use for deploying and managing servers my homelab and personal machines.

## Installation runbook (NixOS)

Create a root password using the TTY

```bash
sudo su
passwd
```

From your host, copy the public SSH key to the server

```bash
export NIXOS_HOST=192.168.2.xxx
ssh-add ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519 root@$NIXOS_HOST
```

SSH into the host with agent forwarding enabled (for the secrets repo access)

```bash
ssh -A root@$NIXOS_HOST
```

Partition and mount the boot/root drives using [disko](https://github.com/nix-community/disko)

```bash
curl https://raw.githubusercontent.com/maxknerrich/infrastructure/refs/heads/main/nixos/filesystem/disko-boot.nix \
    -o /tmp/disko-boot.nix
```
Change disk names if needed
```bash
lsblk # check the disks
nano /tmp/disko-boot.nix # edit the disks name
```

Create the boot/root partition
```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko \
    -- -m destroy,format,mount /tmp/disko-boot.nix
```

If you want to format the data and parity drives do the following
```bash
curl https://raw.githubusercontent.com/maxknerrich/infrastructure/refs/heads/main/nixos/filesystem/disko-data.nix \
    -o /tmp/disko-data.nix
nano /tmp/disko-boot.nix # edit the disks name

```

Format the data and parity drives
```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko \
		-- -m destroy,format,mount /tmp/disko-data.nix
```	

After that remount the boot partitions
```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko \
		-- -m mount /tmp/disko-boot.nix
```

After the command has run, your file system should have been formatted and mounted. You can verify this by running the following command:

```bash
mount | grep /mnt
```

Clone this repository

```bash
mkdir -p /mnt/etc/nixos
git clone https://github.com/maxknerrich/infrastructure.git /mnt/etc/nixos
```

Install the system

```bash
nixos-install \
--root "/mnt" \
--no-root-passwd \
--flake "git+file:///mnt/etc/nixos#titan"
```

Unmount the filesystems

```bash
umount "/mnt/boot/efis/*"
umount -Rl "/mnt"
zpool export -a
```

Reboot

```bash
reboot
```

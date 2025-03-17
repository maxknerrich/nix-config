#!/bin/bash
set -e

# Create partitions on both SSDs
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sda -- set 1 boot on
sudo parted /dev/sda -- mkpart primary 512MiB 100%

# Repeat for second SSD
sudo parted /dev/sdd -- mklabel gpt
sudo parted /dev/sdd -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sdd -- set 1 boot on
sudo parted /dev/sdd -- mkpart primary 512MiB 100%

# Create BTRFS mirror
sudo mkfs.btrfs -m raid1 -d raid1 -L rpool /dev/sda2 /dev/sdd2

# Create EFI boot partitions
sudo mkfs.fat -F 32 /dev/sda1
sudo mkfs.fat -F 32 /dev/sdd1

# Mount BTRFS
sudo mount /dev/sda2 /mnt

# Create BTRFS subvolumes
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix

# Unmount and remount with subvolumes
sudo umount /mnt
sudo mount -o subvol=root /dev/sda2 /mnt
sudo mkdir -p /mnt/{home,nix,boot,boot-backup}
sudo mount -o subvol=home /dev/sda2 /mnt/home
sudo mount -o subvol=nix /dev/sda2 /mnt/nix
sudo mount /dev/sda1 /mnt/boot
sudo mount /dev/sdd1 /mnt/boot-backup

# --- Data and Parity Drive Setup ---

# Create directories for data disks
sudo mkdir -p /mnt/mnt/disks/{disk1,disk2,parity1}
sudo mkdir -p /mnt/mnt/storage

# Partition the data drives
sudo parted /dev/sdc -- mklabel gpt
sudo parted /dev/sdc -- mkpart primary 1MiB 100%

sudo parted /dev/sdb -- mklabel gpt
sudo parted /dev/sdb -- mkpart primary 1MiB 100%

# Partition the parity drive
sudo parted /dev/sde -- mklabel gpt
sudo parted /dev/sde -- mkpart primary 1MiB 100%

# Format the data drives with ext4
sudo mkfs.ext4 -L data1 /dev/sde1
sudo mkfs.ext4 -L data2 /dev/sdc1

# Format the parity drive with ext4
sudo mkfs.ext4 -L parity1 /dev/sdb1

# Mount the data and parity drives
sudo mount /dev/sdc1 /mnt/disk1
sudo mount /dev/sde1 /mnt/disk2
sudo mount /dev/sdb1 /mnt/parity1



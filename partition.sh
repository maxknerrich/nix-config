#!/bin/bash
set -e

# Define drive variables
BOOT1=/dev/sdb
BOOT2=/dev/sdd
DATA1=/dev/sdc
DATA2=/dev/sde
PARITY=/dev/sda
MOUNT_POINT="/mnt"

# Function to check if a device exists
check_device() {
    if [ ! -b "$1" ]; then
        echo "Error: Device $1 does not exist"
        exit 1
    fi
}

# Verify devices exist
check_device $BOOT1
check_device $BOOT2
check_device $DATA1
check_device $DATA2
check_device $PARITY

echo "This script will partition and format the following drives:"
echo "Boot Drive 1: $BOOT1"
echo "Boot Drive 2: $BOOT2"
echo "Data Drive 1: $DATA1"
echo "Data Drive 2: $DATA2"
echo "Parity Drive: $PARITY"
echo ""
echo "WARNING: ALL DATA ON THESE DRIVES WILL BE ERASED!"
read -p "Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled"
    exit 0
fi

# Create partitions on both SSDs
echo "Partitioning boot drives..."
parted ${BOOT1} -- mklabel gpt
parted ${BOOT1} -- mkpart ESP fat32 1MiB 512MiB
parted ${BOOT1} -- set 1 boot on
parted ${BOOT1} -- mkpart primary 512MiB 100%

# Repeat for second SSD
parted ${BOOT2} -- mklabel gpt
parted ${BOOT2} -- mkpart ESP fat32 1MiB 512MiB
parted ${BOOT2} -- set 1 boot on
parted ${BOOT2} -- mkpart primary 512MiB 100%

# Create BTRFS mirror - add force flag to overwrite any existing filesystem
echo "Creating BTRFS RAID1 array..."
mkfs.btrfs -f -m raid1 -d raid1 -L rpool ${BOOT1}2 ${BOOT2}2

# Create EFI boot partitions
echo "Formatting EFI partitions..."
mkfs.fat -F 32 ${BOOT1}1
mkfs.fat -F 32 ${BOOT2}1

# Mount BTRFS
echo "Mounting BTRFS filesystem..."
mount ${BOOT1}2 ${MOUNT_POINT}

# Create BTRFS subvolumes
echo "Creating BTRFS subvolumes..."
btrfs subvolume create ${MOUNT_POINT}/@
btrfs subvolume create ${MOUNT_POINT}/@home
btrfs subvolume create ${MOUNT_POINT}/@nix
btrfs subvolume create ${MOUNT_POINT}/@var_log     # System logs


# Create any additional subvolumes you might need
btrfs subvolume create ${MOUNT_POINT}/@snapshots   # For storing snapshots
btrfs subvolume create ${MOUNT_POINT}/@data

# Enable quota management
echo "Enabling BTRFS quotas..."
btrfs quota enable ${MOUNT_POINT}
btrfs qgroup limit 15G ${MOUNT_POINT}/@nix
btrfs qgroup limit 5G ${MOUNT_POINT}/@var_log

# List created subvolumes
echo "Created subvolumes:"
btrfs subvolume list ${MOUNT_POINT}

# Unmount and remount with subvolumes
echo "Remounting with subvolumes..."
umount ${MOUNT_POINT}
mount -o subvol=@ ${BOOT1}2 ${MOUNT_POINT}

# Create mount points
mkdir -p ${MOUNT_POINT}/{home,nix,snapshots,data,boot,boot-backup}
mkdir -p ${MOUNT_POINT}/var/log

# Mount subvolumes
echo "Mounting subvolumes..."
mount -o subvol=@home ${BOOT1}2 ${MOUNT_POINT}/home
mount -o subvol=@nix ${BOOT1}2 ${MOUNT_POINT}/nix
mount -o subvol=@var_log ${BOOT1}2 ${MOUNT_POINT}/var/log
mount -o subvol=@snapshots ${BOOT1}2 ${MOUNT_POINT}/snapshots
mount -o subvol=@data ${BOOT1}2 ${MOUNT_POINT}/data

# Mount boot partitions
echo "Mounting boot partitions..."
mount ${BOOT1}1 ${MOUNT_POINT}/boot
mount ${BOOT2}1 ${MOUNT_POINT}/boot-backup

# --- Data and Parity Drive Setup ---

# Create directories for data disks
echo "Creating data disk directories..."
mkdir -p ${MOUNT_POINT}/mnt/disks/{disk1,disk2,parity1}
mkdir -p ${MOUNT_POINT}/mnt/storage

# Partition the data drives
echo "Partitioning data and parity drives..."
parted ${DATA1} -- mklabel gpt
parted ${DATA1} -- mkpart primary 1MiB 100%

parted ${DATA2} -- mklabel gpt
parted ${DATA2} -- mkpart primary 1MiB 100%

# Partition the parity drive
parted ${PARITY} -- mklabel gpt
parted ${PARITY} -- mkpart primary 1MiB 100%

# Format the data drives with ext4
echo "Formatting data drives..."
mkfs.ext4 -F -L data1 ${DATA1}1
mkfs.ext4 -F -L data2 ${DATA2}1

# Format the parity drive with ext4
echo "Formatting parity drive..."
mkfs.ext4 -F -L parity1 ${PARITY}1

# Mount the data and parity drives
echo "Mounting data and parity drives..."
mount ${DATA1}1 ${MOUNT_POINT}/mnt/disks/disk1
mount ${DATA2}1 ${MOUNT_POINT}/mnt/disks/disk2
mount ${PARITY}1 ${MOUNT_POINT}/mnt/disks/parity1

echo ""
echo "=== Partitioning and Setup Complete ==="
echo "BTRFS filesystem with subvolumes is mounted at ${MOUNT_POINT}"
echo "Boot partitions are mounted at ${MOUNT_POINT}/boot and ${MOUNT_POINT}/boot-backup"
echo "Data drives are mounted at ${MOUNT_POINT}/mnt/disks/disk1 and ${MOUNT_POINT}/mnt/disks/disk2"
echo "Parity drive is mounted at ${MOUNT_POINT}/mnt/disks/parity1"
echo ""
echo "You can now proceed with your NixOS installation."

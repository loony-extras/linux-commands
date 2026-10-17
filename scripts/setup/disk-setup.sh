#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Disk and Partition Setup Script
# =============================================================================
# Partitions a single disk with GPT layout ready for LVM.
# Run BEFORE lvm-setup.sh.
#
# Usage:
#   sudo bash disk-setup.sh --disk /dev/sdb [--efi] [--boot-size 1G]
#
# WARNING: Destroys ALL data on the target disk. Verify with lsblk first.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DISK=""
INCLUDE_EFI="no"
BOOT_SIZE="1G"
LOG_FILE="/var/log/disk-setup.log"

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[ERROR] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "Must run as root"

while [[ $# -gt 0 ]]; do
  case $1 in
    --disk)       DISK="$2"; shift 2 ;;
    --efi)        INCLUDE_EFI="yes"; shift ;;
    --boot-size)  BOOT_SIZE="$2"; shift 2 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

[[ -n "$DISK" ]] || error "Usage: $0 --disk /dev/sdX [--efi] [--boot-size 1G]"
[[ -b "$DISK" ]] || error "Not a block device: $DISK"

# ---------------------------------------------------------------------------
# Safety Check
# ---------------------------------------------------------------------------
log "Disk: $DISK"
lsblk "$DISK"

# Verify the disk is not currently mounted
if mount | grep -q "^${DISK}"; then
  error "Disk $DISK has mounted partitions. Unmount first."
fi

# Confirm
echo ""
echo "WARNING: This will DESTROY ALL DATA on $DISK"
echo "Current partition table:"
lsblk "$DISK" -o NAME,SIZE,FSTYPE,MOUNTPOINT
echo ""
read -r -p "Type 'yes I am sure' to continue: " confirm
[[ "$confirm" == "yes I am sure" ]] || error "Aborted by user"

# ---------------------------------------------------------------------------
# Wipe disk
# ---------------------------------------------------------------------------
log "Wiping existing partition table and signatures"
wipefs -a "$DISK"
dd if=/dev/zero of="$DISK" bs=4096 count=1000 status=none  # Clear first 4MB

# ---------------------------------------------------------------------------
# Create GPT partition table
# ---------------------------------------------------------------------------
log "Creating GPT partition table"
parted -s "$DISK" mklabel gpt

# Calculate partition boundaries
START="1MiB"

if [[ "$INCLUDE_EFI" == "yes" ]]; then
  log "Creating EFI partition (512MiB)"
  parted -s "$DISK" mkpart primary fat32 "${START}" 513MiB
  parted -s "$DISK" set 1 esp on
  EFI_PART="${DISK}1"
  START="513MiB"
  BOOT_PART_NUM=2
  LVM_PART_NUM=3
else
  BOOT_PART_NUM=1
  LVM_PART_NUM=2
fi

# Boot partition
log "Creating /boot partition ($BOOT_SIZE)"
parted -s "$DISK" mkpart primary ext4 "${START}" "${START%MiB}+${BOOT_SIZE}"
# Recalculate end for next partition
BOOT_END=$(parted -s "$DISK" unit MiB print | awk "/^ ${BOOT_PART_NUM}/{print \$3}" | tr -d MiB)
BOOT_PART="${DISK}${BOOT_PART_NUM}"

# LVM partition (rest of disk)
log "Creating LVM partition (remainder of disk)"
parted -s "$DISK" mkpart primary "${BOOT_END}MiB" 100%
parted -s "$DISK" set "${LVM_PART_NUM}" lvm on
LVM_PART="${DISK}${LVM_PART_NUM}"

# ---------------------------------------------------------------------------
# Format partitions
# ---------------------------------------------------------------------------
log "Formatting partitions"

if [[ "$INCLUDE_EFI" == "yes" ]]; then
  mkfs.vfat -F 32 -n EFI "$EFI_PART"
  log "EFI: $EFI_PART → FAT32"
fi

mkfs.ext4 -q -L boot "$BOOT_PART"
log "Boot: $BOOT_PART → ext4"

# LVM partition is left raw for lvm-setup.sh to consume
log "LVM raw partition ready: $LVM_PART"

# ---------------------------------------------------------------------------
# Show results
# ---------------------------------------------------------------------------
echo ""
log "=== Partition layout ==="
lsblk "$DISK" -o NAME,SIZE,TYPE,FSTYPE,LABEL
echo ""
log "UUIDs (copy these for /etc/fstab):"
blkid "$DISK"*

echo ""
log "Disk setup complete. Run scripts/setup/lvm-setup.sh --pv $LVM_PART next."

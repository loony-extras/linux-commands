# Partitioning

MBR vs GPT, fdisk, parted and disk tools.

---

## Files

- [disk-setup.sh](disk-setup.sh)

---

## Usage

```bash
sudo bash storage/partitioning/disk-setup.sh --disk /dev/sdb --efi
```

GPT partitioning (EFI + boot + LVM raw partition) with a safety confirmation.
Continue with [storage/lvm](../lvm/).

---

## Disk Partitioning — MBR vs GPT

### MBR (Master Boot Record)
- Max 4 primary partitions (or 3 primary + 1 extended)
- Max disk size: 2 TB
- Use only on legacy BIOS systems

### GPT (GUID Partition Table)
- Up to 128 partitions by default
- Supports disks > 2 TB
- Required for UEFI systems
- Use for all modern installs

### Recommended Partition Layout (GPT + UEFI)

| Mount      | Size        | Type           | Filesystem |
|------------|-------------|----------------|------------|
| /boot/efi  | 512 MB      | EFI System     | FAT32      |
| /boot      | 1 GB        | Linux partition | ext4       |
| /          | 20–50 GB    | LVM or direct  | ext4/xfs   |
| /home      | Variable    | LVM            | ext4/xfs   |
| /var       | 10–20 GB    | LVM            | ext4/xfs   |
| /var/log   | 5–10 GB     | LVM            | ext4       |
| /tmp       | 2–4 GB      | LVM or tmpfs   | ext4/tmpfs |
| swap       | RAM size    | Linux swap     | swap       |

### Partitioning with parted (non-interactive)

```bash
# Replace /dev/sda with your disk
DISK=/dev/sda

parted -s "$DISK" mklabel gpt

# EFI partition (1–512MB)
parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

# /boot partition (513MB–1.5GB)
parted -s "$DISK" mkpart primary ext4 513MiB 1537MiB

# LVM partition (rest of disk)
parted -s "$DISK" mkpart primary 1537MiB 100%
parted -s "$DISK" set 3 lvm on

# Format EFI and boot
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
```


---

## Disk Management Tools

### lsblk — block device tree

```bash
lsblk                          # Basic tree view
lsblk -f                       # Show filesystem type and UUID
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID,MODEL
lsblk -d -o NAME,SIZE,ROTA    # ROTA=1 means rotational (HDD), 0=SSD
```

### fdisk — MBR partition editor

```bash
fdisk -l                       # List all disks and partitions
fdisk /dev/sdb                 # Open interactive editor for /dev/sdb
# Inside fdisk:
# n = new partition
# d = delete partition
# p = print partition table
# w = write and exit
# q = quit without saving
# t = change partition type
# l = list partition types
```

### parted — supports GPT, scriptable

```bash
parted /dev/sdb print          # Show partition table
parted /dev/sdb mklabel gpt    # Create GPT label
parted /dev/sdb mkpart primary ext4 0% 50%
parted /dev/sdb resizepart 1 80%   # Extend partition 1 to 80% of disk

# Non-interactive / scripted
parted -s /dev/sdb mklabel gpt mkpart primary 1MiB 100%
```

### gdisk — GPT-specific (safer than fdisk for GPT)

```bash
gdisk /dev/sdb
# Inside gdisk:
# n = new partition
# d = delete
# p = print
# w = write
# o = create new empty GPT
```

### disk I/O testing

```bash
# Raw write speed (bypass OS cache)
dd if=/dev/zero of=/tmp/testfile bs=1G count=1 oflag=direct
# Result: bytes copied, time, speed

# Raw read speed
dd if=/tmp/testfile of=/dev/null bs=1G iflag=direct

# Detailed disk performance with iostat
iostat -xz 1 5          # Extended stats, 1-second interval, 5 times
iostat -d -p /dev/sda   # Per-partition stats
```


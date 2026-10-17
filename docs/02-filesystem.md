# Section 02 — Linux Filesystem & Storage

## 2.1 Filesystem Hierarchy Standard (FHS)

```
/               Root filesystem — everything hangs from here
├── bin/        Essential user binaries (ls, cp, mv) — symlink to /usr/bin on modern systems
├── boot/       Bootloader files, kernel, initrd
├── dev/        Device files (block, char, pseudo-devices)
├── etc/        System-wide configuration files
├── home/       User home directories
├── lib/        Essential shared libraries — symlink to /usr/lib on modern systems
├── lib64/      64-bit libraries
├── media/      Removable media mount points (USB, CD)
├── mnt/        Temporary mount points for manual mounts
├── opt/        Optional/add-on software (non-distro packages)
├── proc/       Virtual fs — kernel and process information
├── root/       Root user's home directory
├── run/        Runtime data (PIDs, sockets) — tmpfs, cleared on reboot
├── sbin/       System binaries (for root) — symlink to /usr/sbin
├── srv/        Data served by system services (http, ftp)
├── sys/        Virtual fs — hardware/kernel info (sysfs)
├── tmp/        Temporary files — cleared on reboot (often tmpfs)
├── usr/        Secondary hierarchy
│   ├── bin/    Most user programs
│   ├── include/ C header files
│   ├── lib/    Libraries
│   ├── local/  Locally compiled software (not managed by apt)
│   ├── sbin/   Non-essential system admin binaries
│   └── share/  Architecture-independent data
└── var/        Variable data
    ├── cache/  Application cache
    ├── lib/    Persistent app state
    ├── log/    Log files
    ├── mail/   Mailboxes
    ├── run/    PID files (legacy, symlink to /run)
    ├── spool/  Queued tasks (print, mail, cron)
    └── tmp/    Temporary files preserved between reboots
```

---

## 2.2 Mounting and Unmounting

```bash
# Mount a device
mount /dev/sdb1 /mnt/data

# Mount with specific filesystem type
mount -t ext4 /dev/sdb1 /mnt/data

# Mount with options
mount -o rw,noatime,nodiratime /dev/sdb1 /mnt/data

# Read-only mount
mount -o ro /dev/sdb1 /mnt/data

# Remount existing mount (e.g., change ro → rw without unmounting)
mount -o remount,rw /mnt/data

# Unmount
umount /mnt/data

# Lazy unmount (when device is busy — waits for last process to close)
umount -l /mnt/data

# Force unmount (dangerous — can corrupt data)
umount -f /mnt/data

# Find what's using a mount (before unmounting)
lsof +D /mnt/data
fuser -mv /mnt/data

# Show all current mounts
findmnt
mount | column -t

# Mount ISO file (loop device)
mount -o loop /path/to/image.iso /mnt/iso

# Mount tmpfs (RAM-based filesystem)
mount -t tmpfs -o size=512M tmpfs /mnt/ramdisk
```

---

## 2.3 /etc/fstab Configuration

fstab controls what gets mounted at boot. Each field:
```
<device>  <mountpoint>  <fstype>  <options>  <dump>  <pass>
```
- `dump`: 0=don't dump, 1=dump (mostly unused today)
- `pass`: 0=skip fsck, 1=root (first), 2=other (parallel after root)

```bash
# /etc/fstab — production example

# Root on LVM
/dev/vg_system/lv_root   /           ext4  defaults,noatime,errors=remount-ro  0  1

# Boot partition
UUID=<boot-uuid>          /boot       ext4  defaults,noatime                    0  2

# EFI
UUID=<efi-uuid>           /boot/efi   vfat  umask=0077                          0  2

# Home
/dev/vg_system/lv_home   /home       ext4  defaults,noatime,nodev               0  2

# /var
/dev/vg_system/lv_var    /var        ext4  defaults,noatime,nodev               0  2

# /var/log — separate to prevent log storms from filling root
/dev/vg_system/lv_var_log /var/log   ext4  defaults,noatime,nodev               0  2

# /tmp — with security options
/dev/vg_system/lv_tmp    /tmp        ext4  defaults,noatime,nodev,nosuid,noexec  0  2

# /tmp as tmpfs (RAM-backed — fast, auto-cleared)
tmpfs                    /tmp        tmpfs rw,nosuid,nodev,noexec,size=2G        0  0

# Swap
/dev/vg_system/lv_swap   none        swap  sw                                    0  0

# NFS mount example
192.168.1.100:/exports/data  /mnt/nfs  nfs  defaults,_netdev,nfsvers=4          0  0

# Bind mount (make /data accessible at /srv/data)
/data                    /srv/data   none  bind                                   0  0
```

```bash
# Test fstab without rebooting (mount everything in fstab)
mount -a

# Get UUID of a device (use UUID in fstab, not /dev/sdX which can change)
blkid /dev/sda1
lsblk -o NAME,UUID,FSTYPE,MOUNTPOINT
```

---

## 2.4 Disk Management Tools

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

---

## 2.5 LVM Deep Dive

### Architecture
```
Physical Disk (/dev/sda3)
       ↓
Physical Volume (PV)    ← pvcreate
       ↓
Volume Group (VG)       ← vgcreate (pool of PVs)
       ↓
Logical Volume (LV)     ← lvcreate (flexible partitions)
       ↓
Filesystem (ext4, xfs)  ← mkfs
```

### PV (Physical Volume) Operations

```bash
pvcreate /dev/sdb              # Initialize disk as PV
pvcreate /dev/sdb1 /dev/sdc1   # Multiple PVs at once
pvdisplay                      # Detailed info
pvs                            # Summary table
pvscan                         # Scan for PVs
pvremove /dev/sdb              # Remove PV (VG must be removed first)
```

### VG (Volume Group) Operations

```bash
vgcreate vg_data /dev/sdb /dev/sdc     # Create VG spanning two disks
vgdisplay vg_data
vgs                                     # Summary
vgextend vg_data /dev/sdd              # Add PV to existing VG
vgreduce vg_data /dev/sdd              # Remove PV from VG (must be empty)
vgrename vg_data vg_production         # Rename VG
vgremove vg_data                       # Remove VG (all LVs must be removed)
```

### LV (Logical Volume) Operations

```bash
# Create LVs
lvcreate -L 50G -n lv_data vg_data          # Fixed size
lvcreate -l 100%FREE -n lv_data vg_data     # Use all remaining space
lvcreate -l 50%VG -n lv_data vg_data        # 50% of VG

# Display
lvdisplay /dev/vg_data/lv_data
lvs

# Extend an LV online (no downtime with ext4/xfs)
lvextend -L +20G /dev/vg_data/lv_data
# Then resize the filesystem:
resize2fs /dev/vg_data/lv_data           # ext4
xfs_growfs /mnt/data                     # xfs (must be mounted)

# Reduce an LV (ext4 only — xfs cannot shrink)
umount /mnt/data
e2fsck -f /dev/vg_data/lv_data
resize2fs /dev/vg_data/lv_data 30G      # Shrink filesystem first
lvreduce -L 30G /dev/vg_data/lv_data    # Then shrink LV

# Remove LV
umount /mnt/data
lvremove /dev/vg_data/lv_data

# Rename LV
lvrename vg_data lv_data lv_production
```

### LVM Snapshots

```bash
# Create a snapshot (for backup or testing)
lvcreate -s -L 5G -n lv_data_snap /dev/vg_data/lv_data

# Mount the snapshot read-only
mount -o ro /dev/vg_data/lv_data_snap /mnt/snapshot

# Restore from snapshot (DANGEROUS — overwrites original)
umount /mnt/data
lvconvert --merge /dev/vg_data/lv_data_snap

# Check snapshot usage (don't let it fill — snapshot corruption)
lvs -o lv_name,lv_size,snap_percent
```

### LVM Thin Provisioning

```bash
# Create a thin pool (enables over-provisioning and efficient snapshots)
lvcreate -L 100G --thinpool thin_pool vg_data

# Create thin volumes (allocate on write)
lvcreate -V 50G --thin -n lv_app vg_data/thin_pool
lvcreate -V 50G --thin -n lv_db  vg_data/thin_pool

# Thin snapshot (very space-efficient)
lvcreate -s --name lv_app_snap vg_data/lv_app
```

---

## 2.6 RAID Setup with mdadm

### RAID Levels Summary

| Level | Min Disks | Redundancy | Performance | Notes |
|-------|-----------|-----------|-------------|-------|
| 0     | 2         | None       | High R+W    | Striping, data loss if any disk fails |
| 1     | 2         | 1 disk     | Read high   | Mirroring |
| 5     | 3         | 1 disk     | Good        | Parity distributed |
| 6     | 4         | 2 disks    | Good        | Double parity |
| 10    | 4         | 1 per mirror| Highest    | RAID 1+0 |

```bash
# Install mdadm
apt install -y mdadm

# Create RAID 1 (mirror) on two disks
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc

# Create RAID 5 on three disks
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd

# Create RAID 10 on four disks
mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

# Monitor build progress
cat /proc/mdstat
watch -n1 cat /proc/mdstat

# Save RAID config
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

# Check RAID status
mdadm --detail /dev/md0

# Simulate disk failure
mdadm /dev/md0 --fail /dev/sdc

# Remove failed disk
mdadm /dev/md0 --remove /dev/sdc

# Add replacement disk
mdadm /dev/md0 --add /dev/sde

# Stop a RAID array
mdadm --stop /dev/md0

# Format and use RAID device like any block device
mkfs.ext4 /dev/md0
mount /dev/md0 /mnt/raid
```

---

## 2.7 File Permissions

### Basic Permission Model

```
-rwxr-xr-x  1  user  group  size  date  filename
│├──┤├──┤├──┤
│ u   g   o        u=user/owner, g=group, o=others
│
└─ file type: - file, d directory, l symlink, b block, c char, p pipe, s socket
```

### chmod — change mode

```bash
# Symbolic mode
chmod u+x file           # Add execute for owner
chmod go-w file          # Remove write from group and others
chmod a+r file           # Add read for all
chmod u=rwx,go=rx file   # Set exact permissions

# Octal mode (most common)
chmod 755 file           # rwxr-xr-x
chmod 644 file           # rw-r--r--
chmod 600 file           # rw-------  (private keys, secrets)
chmod 700 dir            # rwx------
chmod 777 file           # AVOID on production (world-writable)

# Recursive
chmod -R 755 /var/www/html

# Common permission patterns
# Config files:  644 (root:root)
# Scripts:       755 (root:root)
# Private keys:  600 (user:user)
# Directories:   755 or 750
# Shared dir:    2775 (setgid)
```

### chown — change owner

```bash
chown user:group file
chown -R www-data:www-data /var/www/html
chown root:sudo /usr/bin/somescript
```

### Special permission bits

```bash
# SUID (Set User ID) — run as file owner, not current user
chmod u+s /usr/bin/passwd    # passwd runs as root regardless of who runs it
ls -l /usr/bin/passwd        # shows: -rwsr-xr-x

# SGID (Set Group ID) — run with file's group / inherit group for dirs
chmod g+s /var/shared        # Files in /var/shared inherit its group
ls -ld /var/shared           # shows: drwxr-sr-x

# Sticky bit — only file owner can delete in shared directory
chmod +t /tmp
ls -ld /tmp                  # shows: drwxrwxrwt

# Combined (SUID+SGID+Sticky in octal)
chmod 7755 file              # SUID+SGID+Sticky = 7, then 755
chmod 1777 /tmp              # Sticky bit only
chmod 2755 /var/shared       # SGID only
chmod 4755 /usr/bin/prog     # SUID only
```

### ACLs (Access Control Lists) — fine-grained beyond rwx

```bash
# Install ACL tools
apt install -y acl

# View ACLs
getfacl /var/www/html

# Set ACL for a specific user
setfacl -m u:nginx:rx /var/www/html

# Set ACL for a specific group
setfacl -m g:developers:rwx /var/www/html

# Set default ACL (inherited by new files/dirs)
setfacl -d -m u:nginx:rx /var/www/html

# Remove an ACL entry
setfacl -x u:nginx /var/www/html

# Remove all ACLs
setfacl -b /var/www/html

# Copy ACLs from one file to another
getfacl file1 | setfacl --set-file=- file2
```

---

## 2.8 Inodes and File Metadata

```bash
# Inode contains: permissions, owner, timestamps, size, block pointers
# NOT the filename (that's in the directory entry)

# View inode number
ls -i file.txt
stat file.txt              # Full metadata

# Find files by inode (useful after filename corruption)
find /path -inum 12345

# Check inode usage (can run out on tmpfs or log-heavy systems)
df -i                      # Inode usage per filesystem

# Hard links — multiple names, same inode
ln file.txt hardlink.txt
stat file.txt              # Link count increases

# Soft/symbolic links — separate inode, points to name
ln -s /path/to/original /path/to/symlink
ls -la symlink             # shows: lrwxrwxrwx ... -> /path/to/original
readlink -f symlink        # Resolve full path

# Find broken symlinks
find /path -xtype l        # Symlinks pointing to nonexistent targets

# File timestamps
stat file.txt
# atime = last Access   (reading)
# mtime = last Modify   (content change)
# ctime = last Change   (metadata change: permissions, owner)

# Touch to update timestamps
touch file.txt             # Updates atime + mtime
touch -a file.txt          # Update atime only
touch -m file.txt          # Update mtime only
touch -t 202401011200 file.txt   # Set specific timestamp

# Immutable flag — cannot be deleted or modified even by root
chattr +i /etc/passwd
lsattr /etc/passwd         # shows: ----i--- /etc/passwd
chattr -i /etc/passwd      # Remove immutable flag

# Append-only (log files — can only add, not overwrite or delete)
chattr +a /var/log/myapp.log

# List extended attributes
lsattr -R /etc/
```

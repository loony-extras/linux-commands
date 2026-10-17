# mount & fstab

Mounting and persistent mounts.

---

## Files

- [fstab.example](fstab.example)

---

## Usage

`fstab.example` is an annotated production `/etc/fstab` with noatime, noexec, nosuid
and a separate /tmp. Use it as a reference; don't copy it over a live fstab.

---

## Mounting and Unmounting

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

## /etc/fstab Configuration

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


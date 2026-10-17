# RAID

Software RAID with mdadm.

---

## RAID Setup with mdadm

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


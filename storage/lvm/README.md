# LVM

Logical Volume Manager.

---

## Files

- [lvm-setup.sh](lvm-setup.sh)

---

## Usage

```bash
sudo bash storage/lvm/lvm-setup.sh --pv /dev/sdb3 --profile server
```

Creates PV → VG → LVs and generates fstab entries.

```bash
# Profiles:
# server  → root 30G, home 10G, var 15G, var/log 8G, tmp 4G, swap=RAM
# db      → root 20G, var 40G (WAL space), var/log 10G, /data=remainder
# desktop → root 25G, home=remainder, var 10G, swap 8G
```

---

## LVM Setup (Logical Volume Manager)

LVM adds a flexible abstraction layer between physical disks and filesystems, enabling
live resizing, snapshots, and striping without downtime.

```bash
# Physical Volume creation
pvcreate /dev/sda3

# Volume Group creation (name it after the server role or hostname)
vgcreate vg_system /dev/sda3

# Logical Volumes
lvcreate -L 30G  -n lv_root    vg_system
lvcreate -L 20G  -n lv_home    vg_system
lvcreate -L 15G  -n lv_var     vg_system
lvcreate -L 8G   -n lv_var_log vg_system
lvcreate -L 4G   -n lv_tmp     vg_system
lvcreate -L 4G   -n lv_swap    vg_system

# Format volumes
mkfs.ext4 /dev/vg_system/lv_root
mkfs.ext4 /dev/vg_system/lv_home
mkfs.ext4 /dev/vg_system/lv_var
mkfs.ext4 /dev/vg_system/lv_var_log
mkfs.ext4 /dev/vg_system/lv_tmp
mkswap    /dev/vg_system/lv_swap

# Activate swap
swapon /dev/vg_system/lv_swap
```


---

## LVM Deep Dive

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


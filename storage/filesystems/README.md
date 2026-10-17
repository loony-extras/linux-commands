# Filesystems

FHS, filesystem choice, inodes and metadata.

---

## Filesystem Selection

### ext4
- Default for most Debian/Ubuntu installs
- Mature, journal-based, excellent recovery tools
- Good general-purpose choice for `/`, `/home`, `/var`
- Max file size: 16 TB; Max volume: 1 EB

### XFS
- High-performance for large files and high-throughput workloads
- Excellent parallel I/O (databases, media servers)
- Cannot shrink online (only grow)
- Preferred for `/var`, data volumes

### Btrfs
- Copy-on-write (CoW) filesystem
- Native snapshots, checksums, RAID support built in
- Use for: desktop, NAS, situations needing snapshot-based backups
- Avoid on heavy random-write databases (MySQL InnoDB, PostgreSQL)

```bash
# ext4 format with tuned options
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 \
  -L root /dev/vg_system/lv_root

# XFS format
mkfs.xfs -L data /dev/vg_system/lv_var

# Btrfs with compression
mkfs.btrfs -L btrfs_pool /dev/sdb
mount -o compress=zstd /dev/sdb /mnt/data
```


---

## Filesystem Hierarchy Standard (FHS)

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

## Inodes and File Metadata

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

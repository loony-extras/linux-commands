# Section 11 — Troubleshooting Guide

## 11.1 Boot Issues — GRUB Recovery

### Scenario: System won't boot, drops to GRUB prompt

```
# At grub> prompt, find and boot your kernel manually
grub> ls                           # List partitions
grub> ls (hd0,gpt2)/              # List files on partition
grub> set root=(hd0,gpt2)
grub> linux /boot/vmlinuz-6.5.0-35-generic root=/dev/sda2
grub> initrd /boot/initrd.img-6.5.0-35-generic
grub> boot
```

### Scenario: GRUB rescue prompt

```
grub rescue> ls
grub rescue> ls (hd0,gpt2)/
grub rescue> set prefix=(hd0,gpt2)/boot/grub
grub rescue> insmod normal
grub rescue> normal
```

### GRUB repair from live USB

```bash
# Boot from Ubuntu live USB, then:
# 1. Find your disk
lsblk

# 2. Mount the system
mount /dev/sda2 /mnt           # Root partition
mount /dev/sda1 /mnt/boot/efi  # EFI (if UEFI)
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

# 3. Chroot
chroot /mnt

# 4. Reinstall GRUB
grub-install /dev/sda          # BIOS
grub-install --target=x86_64-efi --efi-directory=/boot/efi  # UEFI

update-grub

# 5. Exit and reboot
exit
umount -R /mnt
reboot
```

### Scenario: Kernel panic on boot

```bash
# At GRUB menu, press 'e' to edit the boot entry
# Find the linux line, add at the end:
#   systemd.unit=rescue.target    (rescue shell)
#   init=/bin/bash                (minimal shell before init)
#   nomodeset                     (video driver issues)
#   recovery                      (Ubuntu recovery mode)

# Once in recovery shell:
mount -o remount,rw /          # Mount root read-write
fsck -y /dev/sda2              # Check filesystem
journalctl -b -1               # Previous boot logs
```

### Scenario: initramfs dropped to busybox

```bash
# At initramfs prompt:
(initramfs) blkid              # Find disks
(initramfs) fsck -y /dev/sda2  # Check + repair filesystem
(initramfs) exit               # Try continuing boot
```

---

## 11.2 Network Failures — Systematic Debugging

### The OSI Model Debugging Ladder (bottom to top)

```bash
# Layer 1: Physical
ip link show eth0               # Is interface UP?
ethtool eth0                    # Link detected? Speed/duplex?
dmesg | grep eth0               # Driver errors?

# Layer 2: Data Link
ip link                         # MAC address visible?
ip neigh show                   # ARP table populated?
ping -I eth0 192.168.1.1       # Can we reach gateway?
arping -I eth0 192.168.1.1     # ARP ping

# Layer 3: Network
ip addr show                    # Do we have an IP?
ip route                        # Is default route set?
ping 192.168.1.1               # Gateway reachable?
ping 8.8.8.8                   # Internet reachable (bypasses DNS)

# Layer 4+: Transport/Application
ping google.com                 # DNS working?
dig google.com                  # DNS query directly
curl -v http://google.com      # HTTP working?
ss -tlnp | grep :80            # Is service listening?
nc -zv google.com 80           # Can we reach the port?

# If ping to 8.8.8.8 works but DNS fails:
cat /etc/resolv.conf            # Check DNS config
resolvectl status               # systemd-resolved status
dig @8.8.8.8 google.com        # Test with specific DNS server

# If locally fine but can't reach outside:
ip route show                   # Is default route there?
traceroute 8.8.8.8             # Where does it die?

# Firewall blocking?
ufw status
iptables -L -n | grep -v ACCEPT | grep -v ^Chain | grep -v ^$
iptables -L OUTPUT -n           # Is outgoing traffic blocked?
```

### Network automation script

```bash
#!/bin/bash
# Quick network diagnostics

echo "=== Interface Status ==="
ip addr show | grep -E "^[0-9]|inet "

echo "=== Routes ==="
ip route

echo "=== DNS ==="
cat /etc/resolv.conf | grep nameserver

echo "=== Connectivity Tests ==="
ping -c 1 -W 2 $(ip route | awk '/default/{print $3}') && echo "GATEWAY: OK" || echo "GATEWAY: FAIL"
ping -c 1 -W 2 8.8.8.8 && echo "INTERNET: OK" || echo "INTERNET: FAIL"
ping -c 1 -W 2 google.com && echo "DNS: OK" || echo "DNS: FAIL"

echo "=== Listening Services ==="
ss -tlnp

echo "=== Recent Network Errors ==="
dmesg | grep -i "link\|error\|fail" | tail -10
```

---

## 11.3 Disk Issues

### Scenario: Filesystem corruption (ext4)

```bash
# NEVER run fsck on a mounted filesystem (except /)
# For /:
sudo touch /forcefsck            # Force check on next reboot
# Or at GRUB: add fsck.mode=force to kernel cmdline

# Manual fsck (boot from recovery or live USB)
fsck -y /dev/sda2               # Auto-fix yes to all questions
fsck -n /dev/sda2               # Check only, don't fix
e2fsck -p /dev/sda2             # Automatically fix "safe" issues

# If fsck fails badly:
e2fsck -c /dev/sda2             # Check for bad blocks first
badblocks -v /dev/sda2          # Find bad blocks
e2fsck -y -c /dev/sda2         # Fix + check bad blocks

# After repair, check filesystem:
dumpe2fs /dev/sda2 | head -50   # Filesystem statistics
tune2fs -l /dev/sda2            # Superblock info
```

### Scenario: Disk full

```bash
# Find what's eating space
df -h                            # Which filesystem is full?
du -sh /var/*  | sort -rh | head -10
du -sh /var/log/*  | sort -rh | head -10
ncdu /var                        # Interactive exploration

# Quick wins
# 1. Old log files
journalctl --vacuum-size=500M   # Trim journald
logrotate -f /etc/logrotate.conf
find /var/log -name "*.gz" -mtime +30 -delete

# 2. Package cache
apt clean                        # Remove downloaded .deb files
apt autoremove                   # Remove orphaned packages

# 3. Old kernels
dpkg -l 'linux-image-*' | grep ^ii
apt purge linux-image-<old-version>

# 4. Docker leftovers
docker system prune -a --volumes

# 5. Core dumps
find / -name "core" -type f 2>/dev/null
find / -name "*.core" 2>/dev/null | xargs rm -f

# 6. Temp files
rm -rf /tmp/* /var/tmp/*

# Emergency: if / is full and you can't even login
# Use forcefsck, or boot live USB, or:
# Free space immediately (truncate a log without deleting)
truncate -s 0 /var/log/large-file.log

# Find deleted files still held open by processes (they hold disk space!)
lsof +L1 | grep deleted          # Files deleted but still open
# Kill the process or restart the service to release the space
```

### Scenario: LVM issues

```bash
# LV not found at boot
vgscan                           # Scan for VGs
vgchange -ay                     # Activate all VGs
lvdisplay                        # List LVs

# Recover from VG metadata corruption
vgcfgrestore -l vg_system        # List available backups (in /etc/lvm/backup)
vgcfgrestore vg_system           # Restore from backup

# PV damaged or missing
pvdisplay                        # Show PV status
vgreduce --removemissing vg_system  # Remove missing PV

# Snapshot full (merge immediately)
lvdisplay | grep snap_percent    # Check usage
# If snapshot is full, it becomes invalid
lvremove /dev/vg/snap            # Remove invalid snapshot
```

---

## 11.4 Memory Leaks

```bash
# Identify leaking process
free -h                          # Is available memory decreasing over time?
watch -n 10 'free -h; ps aux --sort=-%mem | head -5'

# smem — shows proportional set size (PSS) accounting for shared memory
apt install smem
smem -r -k -s uss | head -20    # Top processes by private memory

# valgrind — memory leak detection for C/C++
apt install valgrind
valgrind --leak-check=full --show-leak-kinds=all ./myprogram

# /proc/$PID/smaps — detailed memory breakdown
grep -E "^(VmRSS|VmPSS|Private|Shared)" /proc/$(pgrep myapp)/status

# Track memory over time
PID=$(pgrep -n myapp)
while sleep 60; do
  echo "$(date) RSS: $(grep VmRSS /proc/$PID/status | awk '{print $2}')kB"
done >> /var/log/myapp-mem.log

# For Python memory leaks
python3 -c "
import tracemalloc
tracemalloc.start()
# your code here
snapshot = tracemalloc.take_snapshot()
for stat in snapshot.statistics('lineno')[:10]:
    print(stat)
"

# For Java heap dumps
jmap -heap <PID>               # Heap summary
jmap -dump:format=b,file=/tmp/heapdump.hprof <PID>  # Full heap dump
# Analyze with Eclipse MAT or VisualVM

# Node.js memory profiling
node --inspect myapp.js
# Connect Chrome DevTools at chrome://inspect
```

---

## 11.5 Debugging System Crashes

### Kernel crashes — analyzing vmcore

```bash
# Enable kernel crash dumps
apt install -y linux-crashdump kdump-tools

# Configure in /etc/default/kdump-tools
# KDUMP_SYSCTL="kernel.panic_on_oops=1"

# Check kdump status
kdump-config show
systemctl status kdump-tools

# After crash, vmcore is at /var/crash/
ls -la /var/crash/

# Analyze with crash tool
apt install -y crash linux-image-$(uname -r)-dbgsym
crash /usr/lib/debug/boot/vmlinux-$(uname -r) /var/crash/*/vmcore

# Inside crash:
# bt    = backtrace
# log   = dmesg from crash
# ps    = processes at crash time
# sys   = system info

# Check OOM events
dmesg | grep -E "OOM|killed|Out of memory" | tail -20

# Check for segfaults
journalctl | grep segfault | tail -20
dmesg | grep "segfault at"
```

### Hung system / deadlock debugging

```bash
# Magic SysRq (if keyboard accessible)
# Enable: echo 1 > /proc/sys/kernel/sysrq
# Then Alt+SysRq+<key>:
# t = show all task state (look for D state = deadlock)
# m = memory info
# p = current task state
# u = remount filesystems read-only
# s = sync filesystems
# b = reboot immediately
# o = power off

# Watchdog — auto-reboot on hang
apt install -y watchdog
cat >> /etc/watchdog.conf << 'EOF'
watchdog-device = /dev/watchdog
watchdog-timeout = 60
interval = 10
max-load-1 = 24          # Reboot if 1-min load > 24 (6-core: > 4x)
min-memory = 1           # Reboot if less than 1 page free
EOF
systemctl enable --now watchdog

# softlockup / hardlockup
# These appear in dmesg when a CPU is stuck for >20s / >60s
dmesg | grep -i "lockup\|hung task"
```

---

## 11.6 Step-by-Step Debugging Workflows

### Application not starting

```bash
# 1. Check service status
systemctl status myapp -l

# 2. Check recent logs
journalctl -u myapp -n 100 --no-pager

# 3. Try starting manually (often reveals errors not in logs)
sudo -u myapp /opt/myapp/bin/server --config /etc/myapp/config.yaml

# 4. Check dependencies
ldd /opt/myapp/bin/server       # Missing shared libraries?
strace /opt/myapp/bin/server 2>&1 | head -50  # Syscall trace

# 5. Check permissions
ls -la /opt/myapp/
ls -la /etc/myapp/config.yaml
ls -la /var/log/myapp/

# 6. Check ports
ss -tlnp | grep :8080            # Is port already in use?
fuser 8080/tcp                   # Who's using port 8080?

# 7. Check resources
ulimit -a                        # Current limits
cat /proc/$(pgrep myapp)/limits  # Per-process limits
```

### High CPU — find the cause

```bash
# 1. Identify the process
top                              # Look at %CPU column
ps aux --sort=-%cpu | head -5

# 2. Find what the process is doing
PID=$(pgrep -n myapp)
strace -p $PID -c -e trace=all  # Syscall summary over 10 seconds & Ctrl+C

# 3. Profile at symbol level
perf record -g -p $PID sleep 30
perf report

# 4. Check for runaway threads
top -H -p $PID                  # Show threads
ps -eLf | grep myapp            # All threads

# 5. Check if CPU wait is actually I/O wait
iostat 1 5                      # Is disk saturated?
iotop                           # Which process is doing I/O?
```

### Performance degradation over time

```bash
# 1. Collect baseline metrics
sar -u 1 60 > /tmp/cpu.txt      # 60 seconds of CPU
sar -r 1 60 > /tmp/mem.txt
sar -n DEV 1 60 > /tmp/net.txt
iostat -xz 1 60 > /tmp/io.txt

# 2. Check for gradual resource leaks
# Memory: is MemAvailable slowly decreasing?
watch -n 30 'date; grep MemAvailable /proc/meminfo'

# 3. Check for connection leaks
watch -n 10 'ss -s'             # Is ESTABLISHED count growing?
watch -n 10 'ss -s | grep TIME-WAIT'

# 4. Check database
# For PostgreSQL:
psql -U postgres -c "SELECT pid, query, query_start, state FROM pg_stat_activity WHERE state='active' ORDER BY query_start;"
psql -U postgres -c "SELECT relname, n_dead_tup, last_autovacuum FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 10;"

# 5. Correlation: what changed around the time it got slow?
journalctl --since "2 hours ago" | grep -E "started|stopped|Updated|upgrade"
last                            # Recent logins
git log --since="2 hours ago"  # If code deployed
```

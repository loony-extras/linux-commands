# Section 12 — Kernel & Low-Level Systems

## 12.1 Linux Kernel Architecture

```
User Space
  ┌─────────────────────────────────────────────────────┐
  │  Applications (nginx, postgres, bash, python, ...)   │
  └────────────────────┬────────────────────────────────┘
                       │ System Calls (glibc/syscall interface)
  ─────────────────────▼─────────────────────── (ring 0/3 boundary)
Kernel Space
  ┌─────────────────────────────────────────────────────┐
  │  System Call Interface                               │
  ├──────────────┬──────────────┬───────────────────────┤
  │  VFS         │  Networking  │  IPC                  │
  │  (ext4,xfs)  │  Stack       │  (pipes,sockets,shm)  │
  ├──────────────┴──────────────┴───────────────────────┤
  │  Process / Thread Management (scheduler, signals)    │
  ├────────────────────────────────────────────────────┤
  │  Memory Management (VM, mmap, SLUB allocator, OOM)  │
  ├────────────────────────────────────────────────────┤
  │  Device Drivers (block, char, network, USB, ...)    │
  ├────────────────────────────────────────────────────┤
  │  Hardware Abstraction Layer                         │
  └────────────────────────────────────────────────────┘
                       │
  ─────────────────────▼───────────────────────
Hardware: CPU, RAM, Disk, NIC, GPU, ...
```

### Key Kernel Subsystems

| Subsystem | Function |
|-----------|----------|
| Scheduler | CFS (Completely Fair Scheduler) — assigns CPU time to tasks |
| Memory | Virtual memory, page tables, swap, huge pages, SLUB allocator |
| VFS | Virtual Filesystem Switch — unified interface over all filesystems |
| Network | TCP/IP stack, netfilter, socket layer |
| IPC | Pipes, message queues, semaphores, shared memory |
| Signals | Asynchronous notifications between processes |
| Device drivers | Character, block, network; loadable as modules |
| cgroups | Resource control (used by systemd, Docker, Kubernetes) |
| namespaces | Isolation (pid, net, mnt, uts, ipc, user — Linux containers) |
| eBPF | Safe kernel programmability without modules |

---

## 12.2 Kernel Modules

Modules are dynamically loadable pieces of kernel code (device drivers, filesystems, etc).

```bash
# List loaded modules
lsmod
lsmod | grep -i nvidia
lsmod | wc -l                   # Count loaded modules

# Module information
modinfo tcp_bbr                 # Description, parameters, depends
modinfo ext4
modinfo vfat

# Load a module
modprobe tcp_bbr                # Loads tcp_bbr + dependencies
insmod /lib/modules/$(uname -r)/kernel/net/ipv4/tcp_bbr.ko  # Direct load (no deps)

# Remove a module
modprobe -r tcp_bbr             # Remove + unused dependencies
rmmod tcp_bbr                   # Direct remove

# Load module parameters
modprobe usbhid quirks=0x413c:0x2107:0x04

# Make module load at boot
echo "tcp_bbr" > /etc/modules-load.d/bbr.conf

# Pass parameters at boot time
cat > /etc/modprobe.d/mymodule.conf << 'EOF'
options mymodule param1=value1 param2=value2
EOF

# Blacklist a module (prevent loading)
cat > /etc/modprobe.d/blacklist-nouveau.conf << 'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
update-initramfs -u             # Rebuild initrd after blacklist changes

# Find module for a device
modprobe $(ls /sys/bus/usb/devices/1-1/driver/ | head -1)

# Debug module loading
modprobe -v tcp_bbr             # Verbose
dmesg | grep -i "module\|taint" | tail -20
```

---

## 12.3 sysctl Tuning (Reference)

```bash
# View all sysctl parameters
sysctl -a 2>/dev/null | wc -l   # Count of all parameters

# Categories of interest
sysctl -a | grep ^kernel        # Kernel params
sysctl -a | grep ^net           # Network params
sysctl -a | grep ^vm            # VM/memory params
sysctl -a | grep ^fs            # Filesystem params

# Commonly tuned — production web server
cat > /etc/sysctl.d/99-production.conf << 'EOF'
# =====================================
# KERNEL
# =====================================
kernel.panic = 10                      # Reboot 10s after panic
kernel.panic_on_oops = 1              # Panic on kernel oops
kernel.randomize_va_space = 2         # Full ASLR
kernel.dmesg_restrict = 1            # Only root can read dmesg
kernel.kptr_restrict = 2             # Hide kernel pointers

# =====================================
# VM / MEMORY
# =====================================
vm.swappiness = 10                    # Prefer RAM over swap
vm.dirty_ratio = 15                  # Start sync writes at 15% dirty
vm.dirty_background_ratio = 5       # Start bg writes at 5% dirty
vm.vfs_cache_pressure = 50           # Keep inode/dentry cache longer
vm.overcommit_memory = 1             # Allow overcommit (needed for Java/fork)
vm.overcommit_ratio = 80

# =====================================
# NETWORK
# =====================================
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# =====================================
# FILESYSTEM
# =====================================
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.suid_dumpable = 0
EOF

sysctl -p /etc/sysctl.d/99-production.conf
```

---

## 12.4 /proc Filesystem

```bash
# Process information
ls /proc/<PID>/
cat /proc/<PID>/cmdline | tr '\0' ' '   # Process command line
cat /proc/<PID>/status                   # Detailed status
cat /proc/<PID>/maps                     # Memory address map
cat /proc/<PID>/fd/                      # Open file descriptors (ls -la)
cat /proc/<PID>/net/tcp                  # TCP connections (hex)
cat /proc/<PID>/oom_adj                  # OOM adjustment
cat /proc/<PID>/cgroup                   # cgroup membership

# System-wide
cat /proc/cpuinfo                        # CPU details
cat /proc/meminfo                        # Memory stats
cat /proc/uptime                         # Uptime in seconds
cat /proc/loadavg                        # Load average
cat /proc/version                        # Kernel version
cat /proc/cmdline                        # Boot command line
cat /proc/filesystems                    # Registered filesystems
cat /proc/mounts                         # Current mounts
cat /proc/partitions                     # Block device partitions
cat /proc/swaps                          # Swap usage
cat /proc/net/arp                        # ARP table
cat /proc/net/route                      # Routing table (hex)
cat /proc/net/sockstat                   # Socket stats
cat /proc/net/dev                        # Interface stats
cat /proc/sys/                           # sysctl parameters (same as sysctl -a)
cat /proc/irq/                           # Interrupt assignments
cat /proc/buddyinfo                      # Memory fragmentation
cat /proc/slabinfo                       # Kernel slab allocator stats
```

---

## 12.5 /sys Filesystem

```bash
# Block devices
ls /sys/block/                           # All block devices
cat /sys/block/sda/size                  # Size in 512-byte sectors
cat /sys/block/sda/queue/scheduler       # I/O scheduler
cat /sys/block/sda/queue/rotational      # 1=HDD, 0=SSD
cat /sys/block/sda/queue/nr_requests     # Queue depth
cat /sys/block/sda/stat                  # I/O statistics

# Network interfaces
ls /sys/class/net/
cat /sys/class/net/eth0/speed            # Link speed
cat /sys/class/net/eth0/duplex          # full/half
cat /sys/class/net/eth0/carrier          # 1=link up, 0=down
cat /sys/class/net/eth0/address          # MAC address
cat /sys/class/net/eth0/statistics/rx_bytes
cat /sys/class/net/eth0/statistics/tx_bytes
cat /sys/class/net/eth0/statistics/rx_dropped
cat /sys/class/net/eth0/statistics/tx_errors

# CPU
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/present      # Available CPUs
cat /sys/devices/system/cpu/online       # Online CPUs

# Power management
cat /sys/class/power_supply/BAT0/capacity  # Battery %
cat /sys/class/power_supply/AC/online      # AC connected?

# Hardware sensors (via hwmon)
ls /sys/class/hwmon/
cat /sys/class/hwmon/hwmon0/temp1_input   # Temperature in milliCelsius
echo $(($(cat /sys/class/hwmon/hwmon0/temp1_input) / 1000))  # In Celsius

# Kernel MM
cat /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
```

---

## 12.6 Compiling a Custom Kernel

> This is advanced. Only do this if you need specific patches or config not available in distribution kernels.

```bash
# Install build dependencies
apt install -y build-essential libncurses-dev bison flex libssl-dev \
  libelf-dev bc pahole dwarves zstd

# Download kernel source
KERNEL_VERSION="6.6.30"
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
tar -xf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}

# Start from current kernel config
cp /boot/config-$(uname -r) .config
make olddefconfig             # Resolve new options with defaults
# OR: make menuconfig         # Interactive config menu
# OR: make localmodconfig     # Config based on currently loaded modules (minimal)

# Customize (disable unused drivers, enable new features)
make menuconfig

# Build (this takes 30+ minutes on a modern machine)
make -j$(nproc) 2>&1 | tee build.log
# Or for Debian packaging:
make -j$(nproc) bindeb-pkg

# Install
sudo make modules_install     # Install kernel modules
sudo make install             # Copy kernel to /boot
sudo update-grub              # Update bootloader

# Alternatively, install the .deb package:
dpkg -i ../linux-image-${KERNEL_VERSION}_*.deb
dpkg -i ../linux-headers-${KERNEL_VERSION}_*.deb

# Verify new kernel appears in GRUB
grep "menuentry" /boot/grub/grub.cfg | head -5

# Clean up build artifacts
make clean                    # Remove object files (keep .config)
make mrproper                 # Full clean (removes .config too)
```

### Key Kernel Config Options for Production

```
# Security
CONFIG_SECURITY_YAMA=y          # Yama LSM (ptrace restriction)
CONFIG_HARDENED_USERCOPY=y      # Harden copy_to/from_user
CONFIG_INIT_ON_ALLOC_DEFAULT_ON=y  # Zero memory on allocation
CONFIG_FORTIFY_SOURCE=y
CONFIG_STACKPROTECTOR_STRONG=y  # Stack canaries

# Networking
CONFIG_TCP_CONG_BBR=m           # BBR congestion control
CONFIG_NET_SCH_FQ=m             # FQ qdisc (for BBR)
CONFIG_BPF_SYSCALL=y            # eBPF
CONFIG_CGROUPS=y                # Required for containers

# Storage
CONFIG_MD=y                     # MD RAID
CONFIG_BLK_DEV_DM=y            # Device mapper (LVM)

# Performance
CONFIG_HZ_1000=y                # 1000Hz timer (better latency)
CONFIG_NO_HZ_FULL=y            # Tickless kernel (HPC)
CONFIG_NUMA=y                   # NUMA support (multi-socket)
```

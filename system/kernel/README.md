# Kernel

Kernel architecture, modules, /proc, /sys, custom builds.

---

## Files

- [examples.sh](examples.sh)

---

## Kernel Version Management

```bash
# Check current kernel
uname -r

# List installed kernels
dpkg -l 'linux-image-*' | grep ^ii

# Install a specific kernel version
apt install linux-image-6.5.0-35-generic

# Remove an old kernel
apt purge linux-image-5.15.0-100-generic

# Pin the kernel (prevent auto-upgrade)
apt-mark hold linux-image-$(uname -r)

# Switch default kernel in GRUB
# Edit /etc/default/grub, set GRUB_DEFAULT to the entry number or title
# Then: sudo update-grub
```


---

## Linux Kernel Architecture

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

## Kernel Modules

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

## /proc Filesystem

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

## /sys Filesystem

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

## Compiling a Custom Kernel

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

#!/usr/bin/env bash
# =============================================================================
# Kernel — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### /proc — process and kernel information (virtual filesystem)
# ---------------------------------------------------------------------------
cat /proc/cpuinfo                       # CPU model, cores, flags, MHz
cat /proc/meminfo                       # Detailed memory breakdown
cat /proc/version                       # Kernel version string
cat /proc/uptime                        # Seconds since boot + idle time
cat /proc/loadavg                       # Load avg + runqueue + last PID
cat /proc/filesystems                   # Registered filesystems
cat /proc/mounts                        # Current mounts
cat /proc/partitions                    # Block device partitions
cat /proc/swaps                         # Swap file/partition usage
cat /proc/interrupts                    # IRQ statistics per CPU
cat /proc/softirqs                      # Software interrupt statistics
cat /proc/net/arp                        # ARP table
cat /proc/net/route                     # Routing table (hex)
cat /proc/net/tcp                       # TCP connections (hex)
cat /proc/net/udp                       # UDP sockets (hex)
cat /proc/net/sockstat                  # Socket summary statistics
cat /proc/net/dev                       # Network interface statistics
cat /proc/mdstat                        # RAID array status
cat /proc/buddyinfo                     # Memory fragmentation
cat /proc/slabinfo                      # Kernel slab allocator
cat /proc/1/status                      # Init/systemd process status
cat /proc/1/cgroup                      # cgroup membership
cat /proc/self/fd/ | ls -la            # Current process's open FDs
cat /proc/self/limits                   # Current process limits
echo $(($(cat /proc/uptime | awk '{print int($1)}') / 86400)) # Uptime in days

# ---------------------------------------------------------------------------
### /sys — hardware and subsystem interfaces
# ---------------------------------------------------------------------------
cat /sys/block/sda/queue/scheduler      # I/O scheduler for sda
echo mq-deadline > /sys/block/sda/queue/scheduler  # Change I/O scheduler
cat /sys/block/sda/queue/rotational     # 1=HDD, 0=SSD
cat /sys/class/net/eth0/speed           # Link speed in Mbps
cat /sys/class/net/eth0/duplex         # full or half
cat /sys/class/net/eth0/carrier         # 1=link up, 0=no link
cat /sys/class/net/eth0/address         # MAC address
cat /sys/class/net/eth0/statistics/rx_bytes  # Bytes received
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor  # CPU governor
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/enabled  # Disable THP

# ---------------------------------------------------------------------------
### dmesg — kernel ring buffer
# ---------------------------------------------------------------------------
dmesg                                   # All kernel messages
dmesg -T                                # Human-readable timestamps
dmesg -H                                # Human-readable + colors (if supported)
dmesg -l err                            # Error level only
dmesg -l warn,err,crit,alert,emerg     # Multiple levels
dmesg -f kern                           # Kernel facility only
dmesg --follow                          # Live stream (like tail -f)
dmesg | grep -i "oom\|killed"           # OOM events
dmesg | grep -i "error\|fail"           # Hardware errors
dmesg | grep -i "link\|carrier"         # Network link events
dmesg | grep "sda"                      # Disk events
dmesg | grep "EXT4-fs\|XFS"            # Filesystem events
dmesg | grep "Call Trace"               # Kernel oops/panics

# ---------------------------------------------------------------------------
### modprobe — kernel module management
# ---------------------------------------------------------------------------
lsmod                                   # List loaded modules
lsmod | grep kvm                        # Check if KVM is loaded
modinfo tcp_bbr                         # Module description, params, depends
modprobe tcp_bbr                        # Load module (+ dependencies)
modprobe -r tcp_bbr                     # Remove module (+ unused dependencies)
modprobe -v tcp_bbr                     # Verbose load
modprobe --show-depends tcp_bbr         # Show what would be loaded
insmod /path/to/module.ko               # Direct insert (no dependency resolution)
rmmod module_name                       # Direct remove
echo "tcp_bbr" > /etc/modules-load.d/bbr.conf  # Load at boot
echo "options iwlwifi 11n_disable=1" > /etc/modprobe.d/iwlwifi.conf  # Module params
echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf     # Blacklist

# ---------------------------------------------------------------------------
### Hardware information tools
# ---------------------------------------------------------------------------
lshw                                    # List hardware (apt install lshw)
lshw -short                             # Compact view
lshw -class memory                      # Memory info only
lshw -class network                     # Network hardware
lspci                                   # PCI devices
lspci -v                                # Verbose PCI info
lspci -k                                # Show kernel driver
lsusb                                   # USB devices
lsusb -v                                # Verbose USB info
lscpu                                   # CPU architecture information
lsblk                                   # Block devices tree
lsblk -f                                # With filesystem info
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,UUID
dmidecode -t memory                     # Memory DIMMs (requires root)
dmidecode -t bios                       # BIOS information
dmidecode -t system                     # System info (manufacturer, model)
sensors                                 # CPU/GPU temperatures (apt install lm-sensors)
smartctl -H /dev/sda                    # Disk SMART health (apt install smartmontools)

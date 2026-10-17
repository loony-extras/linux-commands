# Performance

CPU, memory, disk and network analysis and tuning.

---

## Files

- [examples.sh](examples.sh)
- [system-monitor.sh](system-monitor.sh)

---

## Usage

```bash
bash monitoring/performance/system-monitor.sh

# Every 5 minutes via cron:
echo "*/5 * * * * root bash /opt/linux-toolkit/monitoring/performance/system-monitor.sh" \
  > /etc/cron.d/system-monitor
```

`system-monitor.sh` checks CPU, memory, disk, swap, services, failed units, OOM, FDs and
network, and alerts by email on threshold breaches.

---

## CPU Monitoring and Analysis

```bash
# Real-time CPU usage
top                            # Basic (press 1 to expand per-CPU)
htop                           # Better (install: apt install htop)
mpstat -P ALL 1 5              # Per-CPU stats, 1s interval, 5 samples
mpstat 1                       # Overall CPU stats

# Load average interpretation
# uptime output: load average: 1.23, 0.89, 0.45 (1m, 5m, 15m)
# On a 4-core system:
#   4.0 = 100% utilized
#   2.0 = 50% utilized
#   8.0 = 200% (queue building — problem!)

# CPU-intensive process identification
ps aux --sort=-%cpu | head -10
pidstat 1 5                    # Per-process CPU (from sysstat)
pidstat -p ALL 1               # All processes

# Context switches and interrupts
vmstat 1 5                     # cs=context switches, in=interrupts
sar -u 1 5                     # CPU stats from sar

# CPU throttling / frequency
cpufreq-info                   # CPU frequency info
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
cat /proc/cpuinfo | grep MHz

# Isolate CPU hogs with perf
perf top -p $(pgrep myapp)     # Live symbol-level profiling
perf stat -p $(pgrep myapp) sleep 30
```


---

## Memory Monitoring

```bash
# Memory overview
free -h                        # Quick summary
cat /proc/meminfo              # Detailed memory info

# Key fields in /proc/meminfo:
# MemTotal    = Total physical RAM
# MemFree     = Completely free
# MemAvailable = Available for new processes (free + reclaimable cache)
# Buffers     = I/O buffer cache
# Cached      = Page cache (can be reclaimed)
# SwapTotal   = Total swap
# SwapFree    = Free swap
# Dirty       = Memory waiting to be written to disk

# Per-process memory
ps aux --sort=-%mem | head -10
pidstat -r 1 5                 # Per-process memory stats

# Memory maps for a process
pmap -x $(pgrep myapp | head -1)   # Detailed memory map
cat /proc/$(pgrep myapp | head -1)/status | grep -i vm

# OOM (Out of Memory) Killer events
grep "Out of memory" /var/log/kern.log
dmesg | grep -i "oom\|killed"
journalctl -k | grep -i "oom\|killed process"

# Swap usage
swapon --show                  # Swap partitions/files
vmstat 1 | awk '{print $7,$8}' # si=swap-in, so=swap-out per second
# High si/so = you're heavily using swap = add RAM or tune vm.swappiness

# Tune swap aggressiveness
sysctl vm.swappiness           # Default 60; 10=prefer RAM, 1=minimum swap
sysctl -w vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.d/99-memory.conf

# Memory leak detection
valgrind --leak-check=full ./myprogram   # For C/C++ programs

# smem — better memory report (accounts for shared memory)
apt install -y smem
smem -r -k -s uss | head -20   # Sort by USS (unique/private memory)
```


---

## Disk Monitoring

```bash
# Disk usage
df -h                          # Filesystem usage
df -ih                         # Inode usage
du -sh /var/*                  # Directory sizes
du -sh * | sort -rh | head -20 # Largest items in current dir
ncdu /var                      # Interactive disk usage (apt install ncdu)

# I/O performance
iostat -xz 1 5                 # Extended stats
# Key columns:
# %util = disk busy percentage (>80% = saturated)
# await = average I/O wait time in ms (<10ms good, >50ms concerning)
# r/s, w/s = reads/writes per second
# rMB/s, wMB/s = throughput

# Per-process I/O
iotop                          # Real-time (apt install iotop)
iotop -o                       # Only processes doing I/O
pidstat -d 1 5                 # I/O from pidstat

# Block device saturation
cat /sys/block/sda/stat        # Raw stats (field 10 = ms in I/O)

# Find I/O-heavy processes
lsof +d /var/lib/postgresql    # What's accessing this directory?

# SMART disk health (physical disks)
apt install -y smartmontools
smartctl -H /dev/sda           # Health check
smartctl -A /dev/sda           # Full attribute table
smartctl -t short /dev/sda     # Run short self-test
smartd                         # Daemon for continuous monitoring

# Tune I/O scheduler
cat /sys/block/sda/queue/scheduler
echo mq-deadline > /sys/block/sda/queue/scheduler   # Better for SSDs
echo none > /sys/block/sda/queue/scheduler           # NVMe SSD (no scheduler)
```


---

## Network Monitoring

```bash
# Interface statistics
ip -s link show eth0           # RX/TX bytes, errors, drops
ifstat 1 5                     # Simple bandwidth per interface

# Connection monitoring
ss -s                          # Socket summary
ss -tnp                        # TCP connections + PIDs
netstat -s                     # Protocol statistics
nstat                          # Kernel network counters (sysstat)

# Bandwidth monitoring
iftop -i eth0                  # Per-host bandwidth (apt install iftop)
nethogs eth0                   # Per-process bandwidth (apt install nethogs)
bmon                           # Bar-chart bandwidth monitor

# Packet loss / latency
ping -c 100 -q gateway         # Quick packet loss check
mtr --report-cycles 100 8.8.8.8  # Path latency report

# Capture and analyze traffic
tcpdump -i eth0 -n -c 1000 -w /tmp/capture.pcap
# Analyze with tshark:
tshark -r /tmp/capture.pcap -q -z io,stat,1  # I/O stats per second
tshark -r /tmp/capture.pcap -T fields -e ip.src -e ip.dst | sort | uniq -c
```


---

## Performance Tuning

### CPU Tuning

```bash
# Set CPU governor (performance mode for servers)
apt install -y cpufrequtils
cpupower frequency-set -g performance

# Disable CPU throttling for consistent benchmarks
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > "$cpu"
done

# Isolate CPUs for critical processes (requires kernel boot param isolcpus=2,3)
taskset -c 2,3 ./critical-app     # Pin process to CPUs 2 and 3

# NUMA topology (multi-socket servers)
numactl --hardware               # Show NUMA topology
numactl --cpunodebind=0 --membind=0 ./myapp  # Run on NUMA node 0
```

### Memory Tuning

```bash
# Reduce swappiness (prefer RAM over swap)
echo "vm.swappiness=10" >> /etc/sysctl.d/99-memory.conf

# Tune dirty page writeback
cat >> /etc/sysctl.d/99-memory.conf << 'EOF'
vm.dirty_ratio = 15             # % RAM before blocking writes (sync flush)
vm.dirty_background_ratio = 5  # % RAM before background writeback starts
vm.dirty_expire_centisecs = 1500  # 15s before dirty pages must be written
EOF

# Disable Transparent Huge Pages (recommended for Redis, MySQL, MongoDB)
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# Enable THP for HPC/batch workloads
echo always > /sys/kernel/mm/transparent_hugepage/enabled

# Tune OOM killer
# OOM score: higher = killed first
echo -100 > /proc/$(pgrep postgres)/oom_score_adj   # Protect postgres from OOM
echo 500 > /proc/$(pgrep myapp)/oom_score_adj       # Prefer to kill myapp
```

### Network Tuning (high-throughput servers)

```bash
cat >> /etc/sysctl.d/99-network-perf.conf << 'EOF'
# Socket buffers — larger for high-bandwidth
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# More connections in TIME_WAIT
net.ipv4.tcp_max_orphans = 65536

# Connection queue
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535

# Port range
net.ipv4.ip_local_port_range = 1024 65535

# BBR congestion control (Linux 4.9+)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Enable keepalives (detect dead connections)
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
EOF
sysctl -p /etc/sysctl.d/99-network-perf.conf
```

### Disk I/O Tuning

```bash
# Read-ahead (larger for sequential workloads like database)
blockdev --setra 8192 /dev/sda     # 8192 * 512 bytes = 4MB read-ahead
# Persistent via /etc/udev/rules.d/60-ioscheduler.rules

# I/O scheduler
# SSDs/NVMe: none or mq-deadline
# HDDs: bfq (fairness) or mq-deadline
echo mq-deadline > /sys/block/sda/queue/scheduler
echo none > /sys/block/nvme0n1/queue/scheduler

# Queue depth (for SSDs/NVMe — default may be too low)
echo 64 > /sys/block/sda/queue/nr_requests

# ext4 mount options for better write performance
# Add to fstab: noatime,barrier=0,data=writeback
# WARNING: data=writeback reduces crash safety; use only with UPS
```

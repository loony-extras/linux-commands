# Section 10 — Monitoring & Performance

## 10.1 CPU Monitoring and Analysis

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

## 10.2 Memory Monitoring

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

## 10.3 Disk Monitoring

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

## 10.4 Network Monitoring

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

## 10.5 Prometheus + Grafana Setup

### Prometheus (metrics collector)

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: production
    datacenter: dc1

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  # Prometheus self-monitoring
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (system metrics)
  - job_name: node
    static_configs:
      - targets:
          - web-01:9100
          - web-02:9100
          - db-01:9100
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance

  # Nginx metrics (nginx-prometheus-exporter)
  - job_name: nginx
    static_configs:
      - targets: ['web-01:9113', 'web-02:9113']

  # PostgreSQL metrics
  - job_name: postgres
    static_configs:
      - targets: ['db-01:9187']

  # Docker containers via cAdvisor
  - job_name: cadvisor
    static_configs:
      - targets: ['localhost:8080']

  # Custom application metrics
  - job_name: myapp
    metrics_path: /metrics
    static_configs:
      - targets: ['app-01:8080', 'app-02:8080']
    basic_auth:
      username: metrics
      password: secretpass
```

### Alert Rules

```yaml
# monitoring/prometheus/rules/alerts.yml
groups:
  - name: node
    rules:
      - alert: NodeDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.instance }} is down"

      - alert: HighCPU
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}: {{ $value }}%"

      - alert: HighMemory
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory on {{ $labels.instance }}: {{ $value }}%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_free_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Disk space critical on {{ $labels.instance }}: {{ $value }}% free"

      - alert: HighDiskIO
        expr: rate(node_disk_io_time_seconds_total[5m]) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk {{ $labels.device }} near saturation on {{ $labels.instance }}"

      - alert: NetworkErrors
        expr: rate(node_network_receive_errs_total[5m]) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Network errors on {{ $labels.instance }}"
```

### Node Exporter Installation

```bash
# monitoring/node-exporter.sh
#!/bin/bash
set -euo pipefail

NODE_EXPORTER_VERSION="1.7.0"
ARCH="linux-amd64"

wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

# Create system user
useradd -r -s /usr/sbin/nologin node_exporter

# systemd unit
cat > /etc/systemd/system/node-exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes \
  --collector.interrupts \
  --collector.perf \
  --web.listen-address=:9100

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node-exporter
echo "Node Exporter running on :9100"
```

---

## 10.6 Log Analysis

```bash
# journalctl log analysis (see also Section 04)
journalctl --since "1 hour ago" | grep -c ERROR
journalctl -u nginx --since today -o json | jq '.MESSAGE' | grep -c "502"

# nginx access log analysis
LOG=/var/log/nginx/access.log

# Top 20 IPs by request count
awk '{print $1}' $LOG | sort | uniq -c | sort -rn | head -20

# Top URLs
awk '{print $7}' $LOG | sort | uniq -c | sort -rn | head -20

# HTTP status code distribution
awk '{print $9}' $LOG | sort | uniq -c | sort -rn

# Average response size
awk '{sum += $10; count++} END {print sum/count " bytes avg"}' $LOG

# Requests per minute
awk '{print $4}' $LOG | cut -d: -f1-3 | sort | uniq -c | tail -60

# Bandwidth by status code
awk '{status[$9] += $10} END {for (s in status) printf "%s: %.1f MB\n", s, status[s]/1048576}' $LOG

# GoAccess — real-time web log analyzer
apt install -y goaccess
goaccess /var/log/nginx/access.log -c          # Interactive TUI
goaccess /var/log/nginx/access.log \
  --log-format=COMBINED \
  -o /var/www/html/report.html \
  --real-time-html                             # Live HTML report

# logwatch — daily log summary email
apt install -y logwatch
logwatch --output mail --mailto admin@company.com --detail high --range today
```

---

## 10.7 Performance Tuning

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

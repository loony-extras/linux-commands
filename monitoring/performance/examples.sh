#!/usr/bin/env bash
# =============================================================================
# Performance — annotated command examples
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### System Monitoring — vmstat, iostat, free, uptime, sar
# ---------------------------------------------------------------------------
## vmstat — virtual memory statistics
vmstat                          # Single snapshot
vmstat 1                        # Update every 1 second (continuous)
vmstat 1 10                     # 1-second interval, 10 samples
vmstat -s                       # Summary table (all counters)
vmstat -d                       # Disk statistics
vmstat -p /dev/sda1             # Specific partition stats
vmstat -a                       # Active/inactive memory breakdown
vmstat -m                       # Slab allocator info
vmstat -t 1 5                   # Include timestamps
# Columns: r=runqueue, b=blocked, swpd=swap, free, buff, cache
# si=swap-in/s, so=swap-out/s (nonzero = memory pressure)
# us=user%, sy=system%, id=idle%, wa=iowait%, st=stolen(VM)%

## iostat — I/O statistics
iostat                          # CPU + disk summary
iostat -x                       # Extended disk stats (most useful)
iostat -xz 1 5                  # Extended, skip idle, 1s interval, 5 samples
iostat -d /dev/sda              # Specific device only
iostat -d -p /dev/sda           # Per-partition breakdown
iostat -k                       # Kilobytes (instead of blocks)
iostat -m                       # Megabytes
iostat -c                       # CPU stats only
iostat -t 1 5                   # Include timestamps
# Key columns: tps=transactions/s, kB_read/s, kB_wrtn/s
# %util=disk busy%, await=avg I/O wait ms, r_await, w_await
# svctm=avg service time, avgrq-sz=avg request size, avgqu-sz=avg queue length

## free — memory usage
free                            # Default (bytes on some systems)
free -h                         # Human-readable (K, M, G)
free -m                         # Megabytes
free -g                         # Gigabytes
free -k                         # Kilobytes
free -s 2                       # Refresh every 2 seconds
free -s 2 -c 5                  # Refresh 5 times then exit
free -t                         # Show totals row
free -w                         # Wide output (separate buffers and cache)
# Key columns:
# total: Physical RAM installed
# used: used = total - free - buff/cache
# free: completely unused
# shared: tmpfs
# buff/cache: kernel buffer + page cache (RECLAIMABLE)
# available: usable for new allocations = free + reclaimable cache

## uptime — system load and uptime
uptime                          # One-liner: time, users, 1/5/15min load
uptime -p                       # Human-readable: "up 3 days, 4 hours"
uptime -s                       # Start time: "2024-01-15 09:30:00"
# Load averages: number of processes wanting CPU
# On N-core system: load > N means queue is building up

## sar — system activity reporter (from sysstat)
sar                             # Default: CPU usage (reads collected data)
sar 1 5                         # Real-time: 1s interval, 5 samples
sar -u 1 5                      # CPU utilization
sar -r 1 5                      # Memory utilization
sar -d 1 5                      # Disk I/O per device
sar -n DEV 1 5                  # Network statistics per interface
sar -n EDEV 1 5                 # Network errors
sar -n SOCK 1 5                 # Socket statistics
sar -q 1 5                      # Queue length and load average
sar -W 1 5                      # Swapping statistics
sar -b 1 5                      # I/O and transfer rate
sar -A 1 5                      # All statistics
sar -f /var/log/sysstat/sa01    # Historical data from file
sar -u -f /var/log/sysstat/sa$(date +%d)  # Today's CPU data

## Additional monitoring tools
watch -n 2 'df -h'              # Run command every 2 seconds
watch -d -n 1 'ss -s'          # -d: highlight differences
dstat                           # Combined stats (apt install dstat)
dstat -cdngy                    # CPU, disk, net, page, system stats
nload eth0                      # Network bandwidth bar chart
glances                         # All-in-one monitor (apt install glances)

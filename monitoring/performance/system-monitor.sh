#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — System Monitor Script
# =============================================================================
# Lightweight monitoring: logs metrics and alerts on thresholds.
# Run via cron every 5 minutes or as a systemd service.
#
# Usage: bash system-monitor.sh [--alert-email admin@company.com]
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ALERT_EMAIL="${ALERT_EMAIL:-root}"
LOG_DIR="${LOG_DIR:-/var/log/monitor}"
LOG_FILE="$LOG_DIR/system-$(date +%Y%m%d).log"
ALERT_LOG="$LOG_DIR/alerts.log"

# Thresholds
CPU_WARN=80           # % — warning
CPU_CRIT=95           # % — critical
MEM_WARN=85           # % used — warning
MEM_CRIT=95           # % used — critical
DISK_WARN=80          # % used — warning
DISK_CRIT=90          # % used — critical
LOAD_WARN=4.0         # 1-min load average
SWAP_WARN=50          # % swap used

mkdir -p "$LOG_DIR"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
ts()    { date +'%Y-%m-%d %H:%M:%S'; }
log()   { echo "$(ts) $*" | tee -a "$LOG_FILE"; }
alert() {
  local level="$1" msg="$2"
  echo "$(ts) [$level] $msg" | tee -a "$ALERT_LOG"
  echo "Subject: [$level] $(hostname): $msg
From: monitor@$(hostname)

$(ts)
Host: $(hostname -f)
$msg

--- System Snapshot ---
$(collect_snapshot)
" | sendmail "$ALERT_EMAIL" 2>/dev/null || true
}

collect_snapshot() {
  echo "Uptime:  $(uptime)"
  echo "CPU:     $(top -bn1 | awk '/^%Cpu/{print $2}')% user"
  echo "Memory:  $(free -h | awk '/^Mem/{print $3"/"$2}')"
  echo "Disk:    $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"
  echo "Load:    $(cat /proc/loadavg)"
}

# ---------------------------------------------------------------------------
# CPU Check
# ---------------------------------------------------------------------------
check_cpu() {
  local cpu_idle cpu_used
  cpu_idle=$(top -bn2 | awk '/^%Cpu/{val=$8} END{print val}')
  cpu_used=$(echo "100 - $cpu_idle" | bc | cut -d. -f1)

  log "CPU: ${cpu_used}%"

  if (( cpu_used >= CPU_CRIT )); then
    alert "CRITICAL" "CPU usage critical: ${cpu_used}%"
  elif (( cpu_used >= CPU_WARN )); then
    alert "WARNING" "CPU usage high: ${cpu_used}%"
  fi
}

# ---------------------------------------------------------------------------
# Memory Check
# ---------------------------------------------------------------------------
check_memory() {
  local mem_total mem_avail mem_used_pct swap_total swap_used swap_pct

  mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
  mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
  mem_used_pct=$(( (mem_total - mem_avail) * 100 / mem_total ))

  swap_total=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
  swap_free=$(awk '/SwapFree/{print $2}' /proc/meminfo)

  log "Memory: ${mem_used_pct}% used ($(( mem_avail / 1024 ))MB available)"

  if (( mem_used_pct >= MEM_CRIT )); then
    alert "CRITICAL" "Memory usage critical: ${mem_used_pct}%"
  elif (( mem_used_pct >= MEM_WARN )); then
    alert "WARNING" "Memory usage high: ${mem_used_pct}%"
  fi

  if (( swap_total > 0 )); then
    swap_pct=$(( (swap_total - swap_free) * 100 / swap_total ))
    log "Swap: ${swap_pct}% used"
    if (( swap_pct >= SWAP_WARN )); then
      alert "WARNING" "Swap usage high: ${swap_pct}%"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Disk Check
# ---------------------------------------------------------------------------
check_disk() {
  while IFS= read -r line; do
    local pct mount
    pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')

    log "Disk $mount: ${pct}%"

    if (( pct >= DISK_CRIT )); then
      alert "CRITICAL" "Disk $mount usage critical: ${pct}%"
    elif (( pct >= DISK_WARN )); then
      alert "WARNING" "Disk $mount usage high: ${pct}%"
    fi
  done < <(df -h | awk 'NR>1 && $1 ~ /^\/dev/ {print}')

  # Inode check
  while IFS= read -r line; do
    local pct mount
    pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    if (( pct >= DISK_WARN )); then
      alert "WARNING" "Inode usage high on $mount: ${pct}%"
    fi
  done < <(df -i | awk 'NR>1 && $1 ~ /^\/dev/ && $5 != "-" {print}')
}

# ---------------------------------------------------------------------------
# Load Average Check
# ---------------------------------------------------------------------------
check_load() {
  local load1
  load1=$(awk '{print $1}' /proc/loadavg)
  local load_int=${load1%.*}

  log "Load: $load1 ($(nproc) CPUs)"

  # Use bc for float comparison
  if (( $(echo "$load1 >= $LOAD_WARN" | bc -l) )); then
    alert "WARNING" "Load average high: $load1 ($(nproc) CPUs)"
  fi
}

# ---------------------------------------------------------------------------
# Service Health Check
# ---------------------------------------------------------------------------
check_services() {
  local services=("ssh" "fail2ban" "ufw")

  # Add more services if they exist
  for svc in nginx apache2 postgresql mysql redis-server docker; do
    if systemctl is-enabled "$svc" &>/dev/null; then
      services+=("$svc")
    fi
  done

  for svc in "${services[@]}"; do
    if ! systemctl is-active --quiet "$svc"; then
      alert "CRITICAL" "Service DOWN: $svc"
    fi
  done

  log "Services: all checked"
}

# ---------------------------------------------------------------------------
# Failed systemd Units
# ---------------------------------------------------------------------------
check_failed_units() {
  local failed
  failed=$(systemctl --failed --no-legend --no-pager | awk '{print $1}' | tr '\n' ' ')
  if [[ -n "$failed" ]]; then
    alert "WARNING" "Failed systemd units: $failed"
  fi
}

# ---------------------------------------------------------------------------
# OOM Events (since last check)
# ---------------------------------------------------------------------------
check_oom() {
  if journalctl -k --since "5 minutes ago" | grep -q "Out of memory"; then
    local victims
    victims=$(journalctl -k --since "5 minutes ago" | grep "Killed process" | awk '{print $NF}')
    alert "CRITICAL" "OOM killer fired! Killed: $victims"
  fi
}

# ---------------------------------------------------------------------------
# Open File Descriptors (system-wide)
# ---------------------------------------------------------------------------
check_fds() {
  local fd_used fd_max fd_pct
  fd_used=$(awk '{print $1}' /proc/sys/fs/file-nr)
  fd_max=$(awk '{print $3}' /proc/sys/fs/file-nr)
  fd_pct=$(( fd_used * 100 / fd_max ))

  log "File descriptors: $fd_used/$fd_max (${fd_pct}%)"
  if (( fd_pct >= 80 )); then
    alert "WARNING" "File descriptor usage high: ${fd_pct}%"
  fi
}

# ---------------------------------------------------------------------------
# Network Checks
# ---------------------------------------------------------------------------
check_network() {
  # Check for high packet drop rate
  while IFS= read -r iface; do
    local rx_drop tx_drop
    rx_drop=$(cat "/sys/class/net/$iface/statistics/rx_dropped" 2>/dev/null || echo 0)
    tx_drop=$(cat "/sys/class/net/$iface/statistics/tx_errors" 2>/dev/null || echo 0)
    if (( rx_drop > 1000 || tx_drop > 100 )); then
      alert "WARNING" "Network errors on $iface: rx_drop=$rx_drop tx_errors=$tx_drop"
    fi
  done < <(ls /sys/class/net/ | grep -v lo)

  # Check DNS
  if ! nslookup google.com >/dev/null 2>&1; then
    alert "WARNING" "DNS resolution failing"
  fi

  log "Network: OK"
}

# ---------------------------------------------------------------------------
# Run all checks
# ---------------------------------------------------------------------------
log "=== Monitor run: $(hostname) ==="
check_cpu
check_memory
check_disk
check_load
check_services
check_failed_units
check_oom
check_fds
check_network
log "=== Monitor run complete ==="

# Rotate logs older than 30 days
find "$LOG_DIR" -name "system-*.log" -mtime +30 -delete

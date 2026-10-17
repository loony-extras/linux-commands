#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Log Analyzer Script
# =============================================================================
# Analyzes common log files and outputs structured security and performance reports.
# Designed to run daily via cron or systemd timer.
#
# Usage: bash log-analyzer.sh [--since "1 hour ago"] [--output /var/log/analysis.log]
# =============================================================================

set -euo pipefail

SINCE="${SINCE:-yesterday}"
OUTPUT="${OUTPUT:-/var/log/loony-analysis-$(date +%Y%m%d).log}"
EMAIL="${EMAIL:-}"

exec > >(tee -a "$OUTPUT") 2>&1

hr() { printf '\n%s\n' "$(printf '=%.0s' {1..65})"; }
h2() { printf '\n--- %s ---\n' "$*"; }

hr
echo " LOG ANALYSIS REPORT: $(hostname -f)"
echo " Generated: $(date)"
echo " Period: $SINCE → now"
hr

# ---------------------------------------------------------------------------
h2 "1. Authentication Events"
# ---------------------------------------------------------------------------
echo ""
echo "[Successful SSH logins]"
journalctl --since "$SINCE" -u ssh -u sshd 2>/dev/null | \
  grep "Accepted" | \
  awk '{print $1,$2,$3, "user="$9, "from="$11}' | \
  sort -k4 | uniq -c | sort -rn | head -20 || \
  grep "Accepted" /var/log/auth.log 2>/dev/null | tail -20

echo ""
echo "[Failed SSH attempts — top IPs]"
journalctl --since "$SINCE" -u ssh -u sshd 2>/dev/null | \
  grep "Failed password" | \
  awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -20 || \
  grep "Failed password" /var/log/auth.log 2>/dev/null | \
  awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -20

echo ""
echo "[sudo commands]"
journalctl --since "$SINCE" 2>/dev/null | grep "COMMAND=" | \
  awk -F'COMMAND=' '{print $1, "CMD:"$2}' | tail -30 || \
  grep "COMMAND=" /var/log/auth.log 2>/dev/null | tail -30

echo ""
echo "[Account changes]"
ausearch --start "$SINCE" -k identity 2>/dev/null | grep -E "type=|^---" | tail -40 || \
  journalctl --since "$SINCE" 2>/dev/null | grep -E "useradd|userdel|usermod|passwd" | tail -20

# ---------------------------------------------------------------------------
h2 "2. Nginx Access Log Analysis"
# ---------------------------------------------------------------------------
if [[ -f /var/log/nginx/access.log ]]; then
  LOG=/var/log/nginx/access.log

  echo ""
  echo "[Top 10 IPs by request count]"
  awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -10

  echo ""
  echo "[HTTP status code distribution]"
  awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn

  echo ""
  echo "[Top 10 requested URLs]"
  awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -10

  echo ""
  echo "[5xx errors (last 50)]"
  awk '$9 ~ /^5/' "$LOG" | \
    awk '{print $4, $7, $9}' | sed 's/\[//' | tail -50

  echo ""
  echo "[Potential scanner activity — 404 storms]"
  awk '$9 == "404"' "$LOG" | awk '{print $1}' | \
    sort | uniq -c | sort -rn | head -10 | \
    awk '$1 > 20 {print "  SCAN:", $1, "404s from", $2}'
else
  echo "nginx access log not found"
fi

# ---------------------------------------------------------------------------
h2 "3. System Resource Events"
# ---------------------------------------------------------------------------
echo ""
echo "[OOM Killer events]"
dmesg | grep -i "Out of memory\|Killed process" | tail -20 || echo "  None found"

echo ""
echo "[Disk I/O errors]"
dmesg | grep -iE "error|I/O error|SCSI error|ata.*failed" | tail -20 || echo "  None found"

echo ""
echo "[Hardware errors (MCE)]"
dmesg | grep -i "Machine Check\|mce\|hardware error" | tail -10 || echo "  None found"

echo ""
echo "[Filesystem errors]"
journalctl --since "$SINCE" -k 2>/dev/null | \
  grep -iE "ext4-fs|xfs.*error|btrfs.*error|filesystem.*error" | tail -20 || echo "  None found"

# ---------------------------------------------------------------------------
h2 "4. Security Events"
# ---------------------------------------------------------------------------
echo ""
echo "[AppArmor denials]"
journalctl --since "$SINCE" 2>/dev/null | grep "DENIED" | tail -20 || \
  grep "DENIED" /var/log/kern.log 2>/dev/null | tail -20 || echo "  None"

echo ""
echo "[Fail2ban bans in period]"
journalctl --since "$SINCE" -u fail2ban 2>/dev/null | grep "Ban " | tail -20 || \
  grep "Ban " /var/log/fail2ban.log 2>/dev/null | tail -20 || echo "  None"

echo ""
echo "[Firewall drops (nftables)]"
journalctl --since "$SINCE" -k 2>/dev/null | \
  grep "nft-drop\|nftables" | \
  awk '{for(i=1;i<=NF;i++) if($i~/SRC=/) print $i}' | \
  sort | uniq -c | sort -rn | head -20 || echo "  None"

# ---------------------------------------------------------------------------
h2 "5. Service Health Summary"
# ---------------------------------------------------------------------------
echo ""
echo "[Failed systemd units]"
systemctl --failed --no-legend --no-pager 2>/dev/null || echo "  None"

echo ""
echo "[Service restarts in period]"
journalctl --since "$SINCE" 2>/dev/null | \
  grep -E "Started|start request|Stopping" | \
  grep -v "journald\|logrotate\|systemd-tmpfiles" | tail -20

# ---------------------------------------------------------------------------
h2 "6. Package and System Changes"
# ---------------------------------------------------------------------------
echo ""
echo "[Package installs/removals (dpkg log)]"
if [[ -f /var/log/dpkg.log ]]; then
  grep -E "install|remove|upgrade" /var/log/dpkg.log | \
    grep "$(date +%Y-%m-%d)" | tail -20
fi

echo ""
echo "[Kernel ring buffer errors (last 24h)]"
dmesg -T | grep -iE "error|warn|fail|critical" | \
  grep -v "acpi\|BIOS\|ACPI" | tail -20 || echo "  None"

# ---------------------------------------------------------------------------
h2 "7. Current System Snapshot"
# ---------------------------------------------------------------------------
echo ""
echo "[Uptime and load]"
uptime

echo ""
echo "[Memory]"
free -h

echo ""
echo "[Disk]"
df -h | grep -v tmpfs | grep -v "^udev"

echo ""
echo "[Top 5 processes by CPU]"
ps aux --sort=-%cpu | awk 'NR<=6{printf "%-10s %6s %6s %s\n", $1, $3, $4, $11}'

echo ""
echo "[Open ports]"
ss -tlnp | awk 'NR>1{print "  "$1, $4, $6}'

hr
echo " ANALYSIS COMPLETE: $OUTPUT"
hr

# Email report if configured
if [[ -n "$EMAIL" ]]; then
  mail -s "Log Analysis: $(hostname) $(date +%Y-%m-%d)" "$EMAIL" < "$OUTPUT"
fi

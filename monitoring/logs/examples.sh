#!/usr/bin/env bash
# =============================================================================
# Log Analysis — annotated command examples
# Tier: 4 (Expert)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### Log Parsing Pipelines
# ---------------------------------------------------------------------------
## nginx access log analysis
LOG=/var/log/nginx/access.log
# Top 20 IPs by request count
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -20
# HTTP status distribution
awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn
# Top requested URLs
awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -20
# Total bandwidth served (bytes)
awk '{sum += $10} END {printf "Total: %.2f GB\n", sum/1073741824}' "$LOG"
# 5xx errors with URL and timestamp
awk '$9 ~ /^5[0-9][0-9]/ {print $4, $7, $9}' "$LOG" | sed 's/\[//'
# Requests per minute
awk '{print $4}' "$LOG" | cut -d: -f1-3 | sort | uniq -c

## /var/log/auth.log analysis
AUTH=/var/log/auth.log
# Failed SSH login attempts by IP
grep "Failed password" "$AUTH" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
# Successful logins
grep "Accepted" "$AUTH" | awk '{print $9, $11}' | sort | uniq -c
# sudo commands
grep "COMMAND=" "$AUTH" | awk -F'COMMAND=' '{print $2}' | sort | uniq -c | sort -rn

## Syslog / journald analysis
# Count log entries by priority
journalctl --since "1 hour ago" -o json | jq -r '.PRIORITY' | sort | uniq -c
# Services with most errors
journalctl -p err --since today | grep -oP '_SYSTEMD_UNIT=\K[^\s]+' | sort | uniq -c | sort -rn
# Kernel errors only
journalctl -k -p warning --since "1 day ago" | grep -v "ACPI"

## Application log analysis
# Count errors vs warnings
grep -cE "^.*ERROR" app.log; grep -cE "^.*WARN" app.log
# Error messages by type (frequency)
grep "ERROR" app.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -20
# Average response time from structured logs
grep "duration=" app.log | grep -oP 'duration=\K[0-9.]+' | \
  awk '{sum+=$1; count++} END {printf "Avg: %.2fms\n", sum/count}'
# Find the slowest requests
grep "duration=" app.log | grep -oP '.*duration=\K[0-9.]+ .*' | sort -rn | head -10
# Errors per 5-minute window
grep "ERROR" app.log | awk '{print $1, $2}' | cut -d: -f1-2 | \
  awk '{gsub(/:/, " "); m=int($4/5)*5; printf "%s %s:%02d\n", $1, $3, m}' | \
  sort | uniq -c

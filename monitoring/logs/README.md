# Log Analysis

Log parsing pipelines and reports.

---

## Files

- [examples.sh](examples.sh)
- [log-analyzer.sh](log-analyzer.sh)

---

## Usage

```bash
bash monitoring/logs/log-analyzer.sh
```

Structured report: auth events, nginx analysis, OOM/hardware errors, AppArmor denials,
fail2ban bans. See also [system/journald](../../system/journald/).

---

## Log Analysis

```bash
# journalctl log analysis (see also system/journald)
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


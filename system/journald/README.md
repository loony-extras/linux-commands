# journald

systemd journal logging.

---

## Journald Logging

journald collects stdout/stderr of all services, kernel messages, and syslog.

```bash
# View all logs
journalctl

# Follow live (like tail -f)
journalctl -f

# Specific service
journalctl -u nginx
journalctl -u nginx -f

# Time filters
journalctl --since "2024-01-15 08:00"
journalctl --since "1 hour ago"
journalctl --since today
journalctl --until "2024-01-15 10:00"
journalctl --since "2024-01-15 08:00" --until "2024-01-15 09:00"

# Priority filters
journalctl -p err                      # Errors and above
journalctl -p warning..err            # Warning to error
# Priorities: emerg(0), alert(1), crit(2), err(3), warning(4), notice(5), info(6), debug(7)

# Boot logs
journalctl -b                          # Current boot
journalctl -b -1                       # Previous boot
journalctl --list-boots                # All recorded boots

# Kernel messages
journalctl -k                          # Kernel messages only
journalctl -k -b                       # Kernel messages from current boot

# Output format
journalctl -u nginx -o json           # JSON format
journalctl -u nginx -o json-pretty    # Pretty JSON
journalctl -u nginx --no-pager        # No pager

# Disk usage
journalctl --disk-usage

# Configure journald
cat > /etc/systemd/journald.conf << 'EOF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemKeepFree=1G
MaxRetentionSec=30day
MaxFileSec=1week
EOF

systemctl restart systemd-journald

# Export logs
journalctl -u myapp --since "1 week ago" -o export > myapp-logs.export
```


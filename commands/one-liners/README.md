# one-liners

Expert one-liners explained.

---

## Files

- [examples.sh](examples.sh)

---

## Extreme — Expert One-Liners Explained

These look cryptic but every piece does specific work:

```bash
# Show the 10 largest files in the current directory tree
find . -type f -printf '%s %p\n' | sort -rn | head -10 | \
  awk '{printf "%8.1f MB  %s\n", $1/1024/1024, $2}'
# find: print size and path as numbers (no ls quirks)
# sort -rn: numeric reverse (largest first)
# awk: convert bytes to MB for readability

# Count open file descriptors per process (sorted)
find /proc -maxdepth 3 -name "fd" -type d 2>/dev/null | \
  while read -r dir; do
    pid="${dir%/fd}"
    pid="${pid##*/}"
    count=$(ls "$dir" 2>/dev/null | wc -l)
    echo "$count $pid $(cat /proc/$pid/comm 2>/dev/null)"
  done | sort -rn | head -20
# Reveals which processes are leaking file descriptors

# Replace a string in all files matching a pattern (safely)
grep -rl "old-hostname.internal" /etc/ | \
  xargs -I{} -P4 sed -i.bak 's/old-hostname\.internal/new-hostname.internal/g' {}
# -r: recursive; -l: filenames only; xargs -P4: 4 parallel seds
# .bak backup created automatically; restore with *.bak if needed

# Watch a file grow (with timestamps, unlike tail -f)
tail -F /var/log/syslog | ts '[%Y-%m-%d %H:%M:%S]'
# ts is from moreutils (apt install moreutils)

# Emergency: which process is eating all your RAM?
smem -r -k -s uss 2>/dev/null | head -15 || \
  ps aux --sort=-%rss | awk 'NR<=10 {printf "%-10s %8s MB  %s\n", $1, int($6/1024), $11}'

# Detect if a process has crashed and restart it (poor man's supervisor)
while true; do
  pgrep myapp || (echo "$(date): restarting myapp" >> /var/log/watchdog.log && \
    systemctl start myapp)
  sleep 30
done &
# In production: use systemd Restart=on-failure instead
```


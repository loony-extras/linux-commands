# Section 03 — Core Command-Line Toolkit

This section is a companion to [scripts/commands/command-library.sh](../scripts/commands/command-library.sh),
which contains every command as runnable, copy-pasteable blocks. This doc explains
the *why*, the patterns, and the mental models behind each tier.

---

## 3.1 Mental Model: The Unix Philosophy

Every tool does one thing well. Compose them with pipes.

```
input → filter/transform → output
stdin    command            stdout
```

The shell is a programming language where every program is a function.

---

## 3.2 Basic Commands — Muscle Memory

These must be reflexive. Learn their most important flags.

| Command | Most Useful Flag(s) | Why |
|---------|--------------------|----|
| `ls` | `-lhtr` | Long, human-readable, sorted by time, reversed (newest last) |
| `cp` | `-a` | Archive mode — preserves everything (permissions, links, timestamps) |
| `rm` | `-i` | Interactive — never regret a delete |
| `find` | `-print0 \| xargs -0` | Handle filenames with spaces safely |
| `chmod` | `-R` + octal | Set permissions recursively |

### Key Distinction: Hard Links vs Symlinks

```
Hard link: two names → same inode → same data
  ln file.txt hardlink.txt
  - Both point to same data; deleting one doesn't affect the other
  - Must be on same filesystem
  - Shows link count > 1 in ls -l

Symlink: name → path → (resolved to inode)
  ln -s /actual/path /alias
  - Can cross filesystems, can point to directories
  - Breaks if target moves; shows as dangling symlink
  - ls -l shows "-> /actual/path"
```

---

## 3.3 Intermediate — Power User Tier

### The grep / awk / sed Trinity

Think of them as a pipeline assembly line:

```
grep  = SELECT (filter rows)
awk   = TRANSFORM (restructure/compute)
sed   = SUBSTITUTE (find/replace)
```

Example: extract failed SSH attempts, count by IP, show top 10:
```bash
grep "Failed password" /var/log/auth.log \  # SELECT matching lines
  | awk '{print $(NF-3)}' \                  # TRANSFORM: extract IP field
  | sort | uniq -c | sort -rn \              # aggregate
  | head -10                                 # limit
```

### find — the most underused tool

Common mistake: using `ls | grep` instead of `find`:
```bash
# Wrong — breaks on spaces, symlinks, directories
ls /var/log | grep "\.gz$" | xargs rm

# Right — handles all edge cases
find /var/log -name "*.gz" -type f -delete
```

Key flags you must know:
```bash
-type f         # files only (not dirs, symlinks, devices)
-mtime -7       # modified in last 7 days (negative = within)
-newer file     # more recent than a reference file
-print0         # null-delimited output (safe for xargs -0)
-exec cmd {} +  # batch exec (faster than \; — groups multiple files)
```

---

## 3.4 Advanced — System Administration Tier

### Process Management Mental Model

```
PID = unique process ID
PPID = parent PID (orphans get reparented to PID 1 / systemd)
UID/GID = effective user/group (SUID changes eUID)

Signal numbers you need:
  1  SIGHUP  — reload config (nginx, sshd respect this)
  2  SIGINT  — Ctrl+C
  9  SIGKILL — force kill (uncatchable — no cleanup)
  15 SIGTERM — graceful stop (default of `kill`)
  18 SIGCONT — resume stopped process
  19 SIGSTOP — pause process (uncatchable)
```

```bash
# Find processes consuming resources, then diagnose before killing
ps aux --sort=-%cpu | head -10        # top CPU
lsof -p <PID>                         # what files it has open
strace -p <PID> -c -e trace=all       # what syscalls it's making
```

### Networking Tools: ss vs netstat

`ss` (socket statistics) is the modern replacement for `netstat`. It reads
from the kernel via netlink sockets — faster and more accurate.

```bash
# The most useful ss invocations:
ss -tlnp          # TCP Listening, Numeric, with Process
ss -s             # Summary (total connections per state)
ss -o state TIME-WAIT   # All sockets in TIME_WAIT
ss -tnp dst :443  # Connections where destination is port 443
```

### System Monitoring — What to Actually Watch

```
CPU:   %wa (iowait) > 20% → disk bottleneck, not CPU
MEM:   "available" in free -h (not "free") → what's usable for new processes
DISK:  %util in iostat > 80% → disk saturation; await > 50ms → latency problem
NET:   tx_errors in ip -s link → driver/hardware issue; rx_dropped → buffer overflow
LOAD:  load/nproc > 1.0 = backlog; load/nproc > 2.0 = serious problem
```

---

## 3.5 Expert — Bash Scripting Patterns

### Error Handling (most important pattern)

Every production script must start with:
```bash
set -euo pipefail
```
- `-e` Exit immediately if a command fails
- `-u` Treat unset variables as errors (prevents `rm -rf /$UNSET_VAR/`)
- `-o pipefail` Pipe fails if ANY command in it fails (not just the last)

### Defensive Variable Expansion

```bash
# These four operators cover every real-world case:
${VAR:-default}    # Use default if unset or empty (VAR unchanged)
${VAR:=default}    # Assign default if unset or empty (VAR changes)
${VAR:?error msg}  # Abort with error if unset or empty
${VAR:+alternate}  # Use alternate if SET (else empty)

# Path manipulation (no need for dirname/basename in many cases)
file="/var/log/nginx/access.log"
echo "${file%/*}"          # /var/log/nginx   (strip suffix from last /)
echo "${file##*/}"         # access.log        (strip prefix up to last /)
echo "${file%.log}"        # /var/log/nginx/access  (strip .log)
echo "${file##*.}"         # log               (extension only)
```

### The Retry Pattern (critical for cloud/network scripts)

```bash
retry() {
  local max=$1 delay=$2; shift 2
  local attempt=1
  while (( attempt <= max )); do
    "$@" && return 0
    echo "Attempt $attempt/$max failed, retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
  done
  echo "All $max attempts failed: $*" >&2
  return 1
}

retry 5 10 curl -f https://api.example.com/health
```

### Parallel Execution (real-world pattern)

```bash
# Run tasks in parallel, collect exit codes
MAX_PARALLEL=4
pids=()

for server in web-01 web-02 db-01 db-02; do
  # Limit parallelism
  while (( ${#pids[@]} >= MAX_PARALLEL )); do
    for i in "${!pids[@]}"; do
      kill -0 "${pids[$i]}" 2>/dev/null || unset "pids[$i]"
    done
    pids=("${pids[@]}")   # Re-index
    sleep 0.1
  done

  (ssh "admin@$server" "uptime") &
  pids+=($!)
done

# Wait for all and check results
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failed++))
done
echo "Parallel tasks done: $failed failed"
```

---

## 3.6 Extreme — Expert One-Liners Explained

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

---

## 3.7 Performance Tracing — Reading perf Output

```bash
# Record CPU profile for 30 seconds
perf record -F 99 -g -p $(pgrep myapp) sleep 30

# The report shows hottest call paths
perf report --stdio 2>&1 | head -60
```

Reading perf report:
```
Overhead  Command  Symbol
  34.12%  myapp    [.] hashmap_lookup           ← 34% of CPU time here
  18.45%  myapp    [.] parse_json
   9.23%  myapp    [k] __lock_text_start         ← k = kernel function
   7.11%  myapp    [.] malloc
```

If you see kernel lock functions (`[k]` symbols) taking significant time,
you have lock contention. If you see `malloc`, investigate memory allocation
patterns. If you see your own function, optimize it.

```bash
# flamegraph (visual call tree — needs Brendan Gregg's tools)
git clone https://github.com/brendangregg/FlameGraph
perf script | ./FlameGraph/stackcollapse-perf.pl | \
  ./FlameGraph/flamegraph.pl > /tmp/flamegraph.svg
# Open in browser — wider = more time, left = call stack depth
```

---

## 3.8 Quick Reference Cards

### File Permission Octal Quick Reference

```
7 = rwx   4 = r--   1 = --x
6 = rw-   3 = -wx   0 = ---
5 = r-x   2 = -w-

Common:
755 = rwxr-xr-x  (programs, directories)
644 = rw-r--r--  (config files, HTML)
600 = rw-------  (private keys, secrets)
640 = rw-r-----  (group-readable configs)
750 = rwxr-x---  (group-executable scripts)
```

### Signal Quick Reference

```
kill -1  (HUP)   → reload config
kill -2  (INT)   → Ctrl+C
kill -9  (KILL)  → force stop (no cleanup)
kill -15 (TERM)  → graceful stop (default)
kill -18 (CONT)  → resume stopped
kill -19 (STOP)  → pause (can't catch)
```

### Bash Exit Code Conventions

```
0    Success
1    General error
2    Misuse of shell builtins
126  Command found but not executable
127  Command not found
128  Invalid exit argument
128+ Signal received (128+9=137 = killed by SIGKILL)
130  Terminated by Ctrl+C (128+2)
```

### Useful /proc Files at a Glance

```
/proc/cpuinfo     CPU model, cores, flags
/proc/meminfo     Memory breakdown
/proc/loadavg     Load averages + run queue
/proc/net/tcp     TCP connections (hex, decode with ss)
/proc/sys/        All sysctl parameters (live read/write)
/proc/<PID>/      Per-process: maps, fd, status, cmdline
/proc/mdstat      RAID status
/proc/partitions  Block devices
```

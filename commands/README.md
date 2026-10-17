# Commands

Everyday command-line tools, text processing and shell scripting.

| Program | Description |
|---------|-------------|
| [ls](ls/) | List directory contents |
| [cd](cd/) | Change directory |
| [pwd](pwd/) | Print working directory |
| [cp](cp/) | Copy files and directories |
| [mv](mv/) | Move and rename |
| [rm](rm/) | Remove files and directories |
| [touch](touch/) | Create files, update timestamps |
| [mkdir](mkdir/) | Create directories |
| [cat](cat/) | Concatenate and display files |
| [head-tail](head-tail/) | View file beginnings and ends |
| [wc](wc/) | Count lines, words and characters |
| [less](less/) | Pager for reading files |
| [ln](ln/) | Create hard and symbolic links |
| [grep](grep/) | Pattern search in files |
| [awk](awk/) | Pattern scanning and data transformation |
| [sed](sed/) | Stream editor: find, replace, transform |
| [find](find/) | Search for files in directory trees |
| [xargs](xargs/) | Build and run commands from stdin |
| [tar](tar/) | Pack and unpack archives |
| [compression](compression/) | gzip, bzip2, xz and zstd |
| [zip](zip/) | Cross-platform zip archives |
| [bash](bash/) | Shell setup, scripting, pipes and redirection |
| [job-control](job-control/) | bg, fg, nohup, disown, wait, tmux |
| [one-liners](one-liners/) | Expert one-liners explained |
| [history](history/) | Shell history |
| [ffmpeg](ffmpeg/) | Audio and video conversion |

---

## Everyday Commands at a Glance

---

### 📂 File & Directory Management

- `ls` – list files (`ls -la` is used constantly)
- `cd` – navigate directories
- `pwd` – show current directory
- `mkdir` – create folders
- `rm` – delete files (`rm -rf` ⚠️ powerful)
- `cp` – copy files
- `mv` – move/rename files
- `tree` – view directory structure (very useful for projects)

---

### 📄 File Viewing & Editing

- `cat` – display file contents
- `less` / `more` – scroll through files (better than `cat` for large files)
- `head` / `tail` – view start/end of files
- `tail -f` – live log monitoring (very common)
- `nano` / `vim` – terminal editors

---

### 🔍 Text Processing (very powerful combo tools)

- `awk` – pattern scanning & processing
- `sed` – stream editing (search/replace)
- `cut` – extract columns
- `sort` – sort lines
- `uniq` – remove duplicates
- `wc` – count lines/words

👉 Example:

```bash
cat file.txt | grep error | sort | uniq -c
```

---

### ⚙️ Process & System Monitoring

- `top` / `htop` – monitor system processes
- `ps` – show running processes
- `kill` / `killall` – stop processes
- `df` – disk usage
- `du` – folder size
- `free` – memory usage
- `uptime` – system load

---

### 🌐 Networking

- `curl` – make HTTP requests (super important for devs)
- `wget` – download files
- `ping` – test connectivity
- `netstat` / `ss` – network stats
- `ssh` – remote login
- `scp` / `rsync` – transfer files

---

### 📦 Package & System Management

(Depends on distro)

- `apt`, `apt-get` – Debian/Ubuntu
- `yum` / `dnf` – RHEL/Fedora
- `pacman` – Arch

---

### 🔐 Permissions & Ownership

- `chmod` – change permissions
- `chown` – change ownership

---

### 🧠 Shell Productivity Boosters

- `alias` – create shortcuts
- `clear` – clear terminal
- `xargs` – pass output as arguments
- `watch` – run command repeatedly
- `which` – locate a command
- `whereis` – find binaries

---

### 🔥 Very Common Power Combos

- Pipes: `|`
- Redirect:
  - `>` overwrite
  - `>>` append

- Background jobs: `&`
- Command chaining:
  - `&&` (run if success)
  - `||` (run if fail)

---

### 🧑‍💻 Developer-Focused Essentials

- `git` – version control (you’ll use this daily)
- `make` – build automation
- `tar` / `zip` / `unzip` – archives
- `env` / `export` – environment variables

---

### 💡 Underrated but VERY Useful

- `fzf` – fuzzy finder (huge productivity boost)
- `bat` – better `cat` with syntax highlighting
- `exa` / `eza` – modern `ls`
- `ripgrep (rg)` – faster `grep`

---

If you want, I can give you a **“top 20 commands every developer actually uses daily”** or a **cheat sheet tailored for backend/devops work**.

---

## Mental Model: The Unix Philosophy

Every tool does one thing well. Compose them with pipes.

```
input → filter/transform → output
stdin    command            stdout
```

The shell is a programming language where every program is a function.


---

## Basic Commands — Muscle Memory

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

## Intermediate — Power User Tier

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

## Advanced — System Administration Tier

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

## Quick Reference Cards

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

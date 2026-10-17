# Search & Navigation — search.sh

The entire toolkit is searchable from a single script: **`search.sh`**

```
./search.sh                     Interactive menu (numbered choices)
./search.sh <keyword>           Search everywhere for a keyword
./search.sh -t <tool>           Show all examples for a specific tool
./search.sh -c <tool>           Show tool + every doc mention combined
./search.sh -s <1-5>            Browse a section (1=Basic … 5=Extreme)
./search.sh -d <topic>          Open a documentation guide
./search.sh -f <word>           Find every file related to a topic
./search.sh -l                  List all tools, docs, and scripts
./search.sh -a                  Map of all headings across every file
./search.sh -h                  Show help
```

## Search Examples

```bash
# Find every mention of nginx across all files
./search.sh nginx

# Show the full grep reference (flags, patterns, real-world pipelines)
./search.sh -t grep

# Show all awk examples
./search.sh -t awk

# Show all curl flags and usage patterns
./search.sh -t curl

# Show all strace / lsof / perf debugging examples (Section 5)
./search.sh -s 5

# Open the networking documentation guide
./search.sh -d networking

# Open the security hardening guide
./search.sh -d security

# Open the kernel / sysctl / /proc reference
./search.sh -d kernel

# Find every file related to "firewall"
./search.sh -f firewall

# Find every file related to "backup"
./search.sh -f backup

# List every documented tool, every guide, every script
./search.sh -l

# See the full map: all section and subsection headings
./search.sh -a
```

## `-d` Doc Name Aliases

The `-d` flag accepts short friendly names — no need to remember filenames:

| You type | Opens |
|----------|-------|
| `install`, `disk`, `lvm`, `grub`, `boot` | `docs/01-installation.md` |
| `filesystem`, `fs`, `fstab`, `raid`, `permissions` | `docs/02-filesystem.md` |
| `commands`, `cmd`, `cli` | `docs/03-commands.md` |
| `process`, `systemd`, `service`, `journald` | `docs/04-process-management.md` |
| `user`, `users`, `pam`, `sudo`, `apparmor` | `docs/05-user-management.md` |
| `networking`, `network`, `firewall`, `ssh`, `dns` | `docs/06-networking.md` |
| `security`, `harden`, `hardening`, `fail2ban`, `audit` | `docs/07-security.md` |
| `package`, `apt`, `dpkg`, `build` | `docs/08-package-management.md` |
| `devops`, `ansible`, `docker`, `kubernetes`, `k8s` | `docs/09-automation-devops.md` |
| `monitoring`, `prometheus`, `grafana`, `performance` | `docs/10-monitoring.md` |
| `troubleshoot`, `debug`, `trouble` | `docs/11-troubleshooting.md` |
| `kernel`, `sysctl`, `proc`, `module` | `docs/12-kernel.md` |
| `project`, `template`, `production` | `docs/13-project-template.md` |
| `best`, `practices`, `migration`, `backup`, `dr` | `docs/15-best-practices.md` |

## Command Library Sections

The command library (`scripts/commands/command-library.sh`) is split into 5 sections:

| Section | Contents |
|---------|----------|
| `./search.sh -s 1` | **Basic** — ls, cd, pwd, cp, mv, rm, touch, mkdir, cat, head/tail, wc, less, ln |
| `./search.sh -s 2` | **Intermediate** — grep, awk, sed, find, xargs, tar, gzip/bzip2/xz/zstd, zip |
| `./search.sh -s 3` | **Advanced** — ps/top/htop/kill, ss/ip/curl/wget, vmstat/iostat/free, pipes & FDs |
| `./search.sh -s 4` | **Expert** — bash scripting, job control, cron/at, log parsing pipelines |
| `./search.sh -s 5` | **Extreme** — one-liners, strace/ltrace/lsof, perf/bpftrace/flamegraph, kernel tools |

Cheatsheets under `cheatsheets/` are included in `<keyword>`, `-t`/`-c`, `-f`, `-l` and `-a`.
Any doc in `docs/` can also be opened by partial filename, e.g. `./search.sh -d toolkit`.

# Loony Linux — Production-Grade Linux System Guide & Toolkit

A complete, real-world Linux reference and automation toolkit for systems engineers,
DevOps architects, and security professionals. Every script is runnable. Every config
is production-tested.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Search & Navigation](#search--navigation)
- [Repository Layout](#repository-layout)
- [Documentation Guides](#documentation-guides)
- [Cheatsheets](#cheatsheets)
- [Scripts Reference](#scripts-reference)
- [Config Files](#config-files)
- [systemd Services](#systemd-services)
- [Monitoring Stack](#monitoring-stack)
- [Security](#security)
- [Docker](#docker)
- [Ansible](#ansible)
- [Kubernetes](#kubernetes)
- [Compatibility](#compatibility)

---

## Quick Start

```bash
# Clone and make all scripts executable
git clone <repo>
cd loony-linux
find scripts security monitoring -name "*.sh" -exec chmod +x {} \;
chmod +x search.sh

# Add a shortcut alias (optional but recommended)
echo "alias lls='bash ~/ai_projects/loony-linux/search.sh'" >> ~/.bashrc
source ~/.bashrc

# Provision a fresh Ubuntu 22.04 / 24.04 server (run as root)
sudo bash scripts/setup/initial-setup.sh

# Harden the system (run after initial setup)
sudo bash scripts/security/harden.sh

# Set up firewall
sudo bash scripts/networking/firewall-setup.sh --profile web
```

---

## Search & Navigation

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

### Search Examples

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

### `-d` Doc Name Aliases

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

### Command Library Sections

The command library (`scripts/commands/command-library.sh`) is split into 5 sections:

| Section | Contents |
|---------|----------|
| `./search.sh -s 1` | **Basic** — ls, cd, pwd, cp, mv, rm, touch, mkdir, cat, head/tail, wc, less, ln |
| `./search.sh -s 2` | **Intermediate** — grep, awk, sed, find, xargs, tar, gzip/bzip2/xz/zstd, zip |
| `./search.sh -s 3` | **Advanced** — ps/top/htop/kill, ss/ip/curl/wget, vmstat/iostat/free, pipes & FDs |
| `./search.sh -s 4` | **Expert** — bash scripting, job control, cron/at, log parsing pipelines |
| `./search.sh -s 5` | **Extreme** — one-liners, strace/ltrace/lsof, perf/bpftrace/flamegraph, kernel tools |

---

## Repository Layout

```
loony-linux/
│
├── search.sh                        ← Search & navigate the entire toolkit
│
├── docs/                            ← Deep-dive reference guides
│   ├── 01-installation.md           Partitioning, LVM, GRUB, apt, shell setup
│   ├── 02-filesystem.md             FHS, fstab, fdisk/parted, LVM ops, RAID, ACLs
│   ├── 03-commands.md               Mental models for every command tier
│   ├── 04-process-management.md     systemd units, timers, journald, cgroups
│   ├── 05-user-management.md        useradd/mod, PAM, sudo, AppArmor, SELinux
│   ├── 06-networking.md             ip/netplan, DNS, routing, UFW/nftables, SSH
│   ├── 07-security.md               sysctl hardening, fail2ban, auditd, AIDE, rkhunter
│   ├── 08-package-management.md     apt/dpkg deep dive, source builds, version pinning
│   ├── 09-automation-devops.md      Bash, Ansible, Docker, Kubernetes, CI/CD
│   ├── 10-monitoring.md             Prometheus, Grafana, log analysis, perf tuning
│   ├── 11-troubleshooting.md        Boot recovery, network debug, disk/memory/crash
│   ├── 12-kernel.md                 Architecture, modules, sysctl, /proc, /sys
│   ├── 13-project-template.md       End-to-end production server provisioning
│   └── 15-best-practices.md         Checklists, anti-patterns, scaling, DR
│
├── cheatsheets/                     ← Quick per-tool command references
│   ├── README.md                    Everyday commands at a glance
│   ├── find.md, grep.md, history.md
│   ├── ffmpeg/                      ffmpeg basics, social media, dev use cases
│   ├── networking/                  ssh, scp, curl, netstat
│   └── permissions/                 chmod, chown
│
├── scripts/
│   ├── commands/
│   │   └── command-library.sh       1,673-line annotated command reference (5 sections)
│   ├── setup/
│   │   ├── initial-setup.sh         Full server provisioning (idempotent)
│   │   ├── disk-setup.sh            GPT partition creation with safety confirmation
│   │   └── lvm-setup.sh             LVM layout (server / db / desktop profiles)
│   ├── security/
│   │   └── harden.sh                Deep security hardening (SUID, /tmp, /proc, cron)
│   ├── networking/
│   │   └── firewall-setup.sh        nftables firewall (web / db / bastion profiles)
│   ├── monitoring/
│   │   ├── system-monitor.sh        Threshold alerts: CPU, mem, disk, services
│   │   └── log-analyzer.sh          Auth, nginx, syslog, OOM, security event reports
│   ├── backup/
│   │   └── backup.sh                Incremental rsync + DB dumps + S3/remote sync
│   └── user-management/
│       └── user-setup.sh            Create / lock / audit / rotate-keys / report
│
├── configs/                         Drop-in production configuration files
│   ├── sshd_config                  SSH server hardening config
│   ├── sysctl.conf                  Kernel tuning (security + performance)
│   ├── fstab.example                Annotated fstab with security mount options
│   ├── auditd.rules                 CIS-aligned audit rules
│   └── fail2ban/
│       └── jail.local               fail2ban jails (SSH, nginx, recidive)
│
├── services/                        systemd unit files
│   ├── myapp.service                Production app service (hardened)
│   ├── backup.service               Backup oneshot service
│   └── backup.timer                 Daily backup timer (2 AM + random delay)
│
├── monitoring/
│   ├── node-exporter.sh             Prometheus Node Exporter installer
│   ├── prometheus/
│   │   ├── prometheus.yml           Full scrape config (node, nginx, pg, redis, app)
│   │   └── alerts.yml               Complete alert ruleset (CPU/mem/disk/net/SSL/app)
│   └── grafana/
│       └── dashboard.json           Importable system overview dashboard
│
├── security/
│   ├── nftables.conf                Production nftables ruleset with rate-limit sets
│   ├── iptables-rules.sh            Legacy iptables equivalent (--dry-run supported)
│   └── rkhunter-setup.sh            Rootkit detection baseline + weekly cron
│
├── docker/
│   ├── Dockerfile.base              Multi-stage Go build → distroless runtime
│   └── docker-compose.yml           Full stack: app + postgres + redis + nginx + monitoring
│
├── ansible/
│   ├── inventory/hosts.yml          Inventory with bastion jump host config
│   ├── playbooks/site.yml           Master playbook (common → security → web/db/mon)
│   └── roles/
│       ├── common/                  Packages, sysctl, users, UFW, unattended-upgrades
│       ├── security/                SSH, nftables, fail2ban, auditd, sysctl, AIDE
│       └── monitoring/              Node Exporter, Prometheus deployment
│
└── kubernetes/
    ├── namespace.yml                Namespace definition
    ├── deployment.yml               Deployment + HPA + PDB + PVC + security contexts
    └── service.yml                  ClusterIP + Ingress + NetworkPolicy
```

---

## Documentation Guides

| # | Guide | Key Topics |
|---|-------|------------|
| 01 | [Installation & System Setup](docs/01-installation.md) | GPT vs MBR, LVM, GRUB password, apt, unattended-upgrades, shell env |
| 02 | [Filesystem & Storage](docs/02-filesystem.md) | FHS, mount options, fstab, fdisk/parted, LVM snapshots, RAID (mdadm), ACLs, inodes |
| 03 | [Core Command-Line Toolkit](docs/03-commands.md) | Mental models, regex patterns, parallel execution, bash error handling |
| 04 | [Process Management & systemd](docs/04-process-management.md) | Unit file types, drop-ins, timers, journald, cgroups, resource limits |
| 05 | [User Management & Permissions](docs/05-user-management.md) | useradd/mod, chage, PAM modules, sudo drop-ins, AppArmor profiles, SELinux |
| 06 | [Networking](docs/06-networking.md) | Netplan, nmcli, Bind9 DNS, routing policy, UFW/iptables/nftables, SSH hardening |
| 07 | [Security Hardening](docs/07-security.md) | sysctl hardening, fail2ban, auditd (CIS), AIDE, rkhunter, privilege escalation |
| 08 | [Package Management & Build Systems](docs/08-package-management.md) | apt/dpkg internals, PPA, version pinning, building from source, pyenv/nvm |
| 09 | [Automation & DevOps](docs/09-automation-devops.md) | Bash patterns, Ansible playbooks/roles, Docker compose, K8s, GitHub Actions CI/CD |
| 10 | [Monitoring & Performance](docs/10-monitoring.md) | CPU/mem/disk/net analysis, Prometheus+Grafana, log analysis, sysctl tuning |
| 11 | [Troubleshooting Guide](docs/11-troubleshooting.md) | GRUB recovery, OSI network debug ladder, disk repair, OOM, kernel crash analysis |
| 12 | [Kernel & Low-Level Systems](docs/12-kernel.md) | Kernel architecture, modules, sysctl, /proc, /sys, custom kernel compile |
| 13 | [Real-World Project Template](docs/13-project-template.md) | Full provisioning workflow, security baseline verification, monitoring integration |
| 15 | [Best Practices & Anti-Patterns](docs/15-best-practices.md) | Checklists, common mistakes, scaling, bare-metal→cloud migration, DR planning |

---

## Cheatsheets

Short, example-first references for individual tools (merged from the former
`linux-commands` repo). Start at [cheatsheets/README.md](cheatsheets/README.md).

| Topic | Files |
|-------|-------|
| Search & history | [find](cheatsheets/find.md), [grep](cheatsheets/grep.md), [history](cheatsheets/history.md) |
| Networking | [ssh](cheatsheets/networking/ssh.md), [ssh dev workflow](cheatsheets/networking/ssh_dev_workflow.md), [scp](cheatsheets/networking/scp.md), [curl](cheatsheets/networking/curl.md), [netstat](cheatsheets/networking/netstat.md) |
| Permissions | [chmod](cheatsheets/permissions/chmod.md), [chown](cheatsheets/permissions/chown.md), [chmod + chown](cheatsheets/permissions/chmod_chown.md) |
| ffmpeg | [ffmpeg](cheatsheets/ffmpeg/ffmpeg.md), [social media](cheatsheets/ffmpeg/social_media.md), [dev use cases](cheatsheets/ffmpeg/dev_usecases.md) |

Cheatsheets are included in `./search.sh <keyword>`, `-t`/`-c`, `-f`, `-l` and `-a`.

---

## Scripts Reference

### Setup Scripts

| Script | Usage | What it does |
|--------|-------|--------------|
| `scripts/setup/initial-setup.sh` | `sudo bash scripts/setup/initial-setup.sh --hostname web-01 --admin-user deploy` | Packages, hostname, timezone, admin user, SSH hardening, UFW, fail2ban, auditd, sysctl, unattended-upgrades |
| `scripts/setup/disk-setup.sh` | `sudo bash scripts/setup/disk-setup.sh --disk /dev/sdb --efi` | GPT partitioning: EFI + boot + LVM raw partition |
| `scripts/setup/lvm-setup.sh` | `sudo bash scripts/setup/lvm-setup.sh --pv /dev/sdb3 --profile server` | LVM layout: PV → VG → LVs (server / db / desktop profiles), auto-generates fstab entries |

```bash
# Profiles for lvm-setup.sh:
# server  → root 30G, home 10G, var 15G, var/log 8G, tmp 4G, swap=RAM
# db      → root 20G, var 40G (WAL space), var/log 10G, /data=remainder
# desktop → root 25G, home=remainder, var 10G, swap 8G
```

### Security Scripts

| Script | Usage | What it does |
|--------|-------|--------------|
| `scripts/security/harden.sh` | `sudo bash scripts/security/harden.sh` | /tmp noexec, SUID removal, core dump disable, /proc hidepid, cron restrict, password policy, SSH key-only enforcement |

### Networking Scripts

| Script | Usage | What it does |
|--------|-------|--------------|
| `scripts/networking/firewall-setup.sh` | `sudo bash scripts/networking/firewall-setup.sh --profile web --ssh-port 22` | nftables firewall with dynamic rate-limit sets |

```bash
# Profiles:
# web     → SSH (rate-limited) + HTTP/HTTPS + node_exporter
# db      → SSH + PostgreSQL/MySQL/Redis (internal CIDR only) + node_exporter
# bastion → SSH only
# minimal → SSH only
```

### Monitoring Scripts

| Script | Usage | What it does |
|--------|-------|--------------|
| `scripts/monitoring/system-monitor.sh` | `bash scripts/monitoring/system-monitor.sh` | Checks CPU, memory, disk, swap, services, failed units, OOM, FDs, network — alerts by email on threshold breach |
| `scripts/monitoring/log-analyzer.sh` | `bash scripts/monitoring/log-analyzer.sh` | Structured report: auth events, nginx analysis, OOM/hardware errors, AppArmor denials, fail2ban bans |

```bash
# Run system-monitor.sh every 5 minutes via cron:
echo "*/5 * * * * root bash /opt/loony-linux/scripts/monitoring/system-monitor.sh" \
  > /etc/cron.d/loony-monitor
```

### Backup Script

| Script | Usage | What it does |
|--------|-------|--------------|
| `scripts/backup/backup.sh` | `sudo bash scripts/backup/backup.sh` | Incremental rsync (hardlink deltas), PostgreSQL/MySQL/Redis dump, optional S3 and remote SSH sync, 30-day retention |

```bash
# Environment variables:
BACKUP_ROOT=/var/backup          # Local backup destination
REMOTE_DEST=user@host:/backups   # SSH remote (optional)
S3_BUCKET=s3://mybucket/backups  # S3 destination (optional)
RETENTION_DAYS=30
GPG_RECIPIENT=admin@company.com  # Encrypt backups (optional)
```

### User Management Script

| Script | Usage | What it does |
|--------|-------|--------------|
| `scripts/user-management/user-setup.sh` | `sudo bash scripts/user-management/user-setup.sh --action <action>` | create, add-key, rotate-keys, lock, unlock, audit, report |

```bash
# Examples:
sudo bash scripts/user-management/user-setup.sh \
  --action create --username john --groups docker,sudo

sudo bash scripts/user-management/user-setup.sh \
  --action add-key --username john --key-file ~/.ssh/id_ed25519.pub

sudo bash scripts/user-management/user-setup.sh --action audit

sudo bash scripts/user-management/user-setup.sh --action report
```

---

## Config Files

| File | Deploy to | Purpose |
|------|-----------|---------|
| `configs/sshd_config` | `/etc/ssh/sshd_config.d/99-hardening.conf` | SSH server hardening: no root, no password auth, ciphers, timeouts |
| `configs/sysctl.conf` | `/etc/sysctl.d/99-production.conf` | Kernel tuning: security + network performance (BBR, somaxconn, syncookies) |
| `configs/fstab.example` | Reference for `/etc/fstab` | Annotated production fstab with noatime, noexec, nosuid, separate /tmp |
| `configs/auditd.rules` | `/etc/audit/rules.d/99-custom.rules` | CIS-aligned audit rules: identity, sudo, SUID, modules, cron, SSH config changes |
| `configs/fail2ban/jail.local` | `/etc/fail2ban/jail.local` | SSH (3 tries/1h ban), nginx, recidive (7-day repeat-offender ban) |

---

## systemd Services

| File | Install to | Purpose |
|------|-----------|---------|
| `services/myapp.service` | `/etc/systemd/system/myapp.service` | Production app unit: non-root user, PrivateTmp, ProtectSystem, MemoryMax, resource limits |
| `services/backup.service` | `/etc/systemd/system/backup.service` | Oneshot backup unit with IOSchedulingClass=idle and 4-hour timeout |
| `services/backup.timer` | `/etc/systemd/system/backup.timer` | Daily at 02:00, RandomizedDelaySec=1800, Persistent=true |

```bash
# Install and enable backup timer:
cp services/backup.service services/backup.timer /etc/systemd/system/
cp scripts/backup/backup.sh /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
systemctl daemon-reload
systemctl enable --now backup.timer

# Verify:
systemctl list-timers backup.timer
```

---

## Monitoring Stack

### Node Exporter (install on every server)

```bash
sudo bash monitoring/node-exporter.sh
# Installs as systemd service on :9100
# Includes textfile collector for custom metrics
# Adds backup success metric automatically
```

### Prometheus

```bash
# Config: monitoring/prometheus/prometheus.yml
# Scrapes: node_exporter, nginx, postgres, redis, cadvisor, blackbox, app metrics

# Alert rules: monitoring/prometheus/alerts.yml
# Covers: TargetDown, SSL expiry, CPU, memory, disk, I/O, network, PostgreSQL, app errors
```

### Grafana

```bash
# Import: monitoring/grafana/dashboard.json
# Grafana → Dashboards → Import → Upload JSON
# Panels: CPU%, memory%, disk%, network I/O, load average, disk I/O util, uptime
# Variables: instance (multi-select, auto-populated from Prometheus)
```

### Full monitoring stack via Docker Compose

```bash
docker compose --profile monitoring up -d prometheus grafana
# Prometheus → http://localhost:9090
# Grafana    → http://localhost:3000  (admin / $GRAFANA_PASSWORD)
```

---

## Security

| File | Purpose |
|------|---------|
| `security/nftables.conf` | Production ruleset: dynamic SSH rate-limit sets, HTTP flood protection, auto-block set |
| `security/iptables-rules.sh` | Legacy iptables equivalent; `--dry-run` flag shows rules without applying |
| `security/rkhunter-setup.sh` | Install rkhunter, create baseline, configure weekly scan + email |

```bash
# Apply nftables ruleset:
sudo cp security/nftables.conf /etc/nftables.conf
sudo nft -c -f /etc/nftables.conf    # validate
sudo systemctl restart nftables

# Run iptables (legacy):
sudo bash security/iptables-rules.sh --dry-run   # preview
sudo bash security/iptables-rules.sh             # apply
```

---

## Docker

```bash
cd docker/

# Build multi-stage image (Go → distroless)
docker build -f Dockerfile.base --target production -t myapp:latest .

# Start full stack (app + postgres + redis + nginx)
cp .env.example .env   # fill DB_PASSWORD, REDIS_PASSWORD
docker compose up -d

# Start with monitoring (adds prometheus + grafana)
docker compose --profile monitoring up -d

# View logs
docker compose logs -f app
docker compose logs -f nginx
```

The compose stack includes:
- **app** — binds to `127.0.0.1:8080` (nginx proxies externally)
- **db** — PostgreSQL 16 with health check
- **cache** — Redis 7 with AOF persistence and maxmemory policy
- **nginx** — reverse proxy with Let's Encrypt volume mounts
- **certbot** — auto-renewal sidecar
- **prometheus + grafana** — optional monitoring profile

---

## Ansible

```bash
cd ansible/

# Syntax check (no changes made)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check

# Dry run (shows what would change)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check --diff

# Apply to all hosts
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Apply to one host
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit web-01

# Run only security role
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags security

# Ad-hoc commands
ansible web -i inventory/hosts.yml -m shell -a "uptime" --become
ansible all -i inventory/hosts.yml -m ping
```

Roles included:

| Role | Tasks |
|------|-------|
| `common` | Packages, timezone, sysctl, unattended-upgrades, admin user, SSH keys, UFW, disable unused services |
| `security` | SSH hardening, nftables, fail2ban, auditd, sysctl security params, core dump disable, /tmp noexec, AIDE |
| `monitoring` | Node Exporter install + systemd service, Prometheus config + alert rules |

---

## Kubernetes

```bash
cd kubernetes/

# Apply all manifests
kubectl apply -f namespace.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml

# Or all at once
kubectl apply -f .

# Check rollout
kubectl rollout status deployment/myapp -n myapp

# Scale
kubectl scale deployment myapp --replicas=5 -n myapp

# View events
kubectl get events -n myapp --sort-by='.lastTimestamp'
```

The manifests include:
- **Deployment** — rolling update, topology spread, security context (non-root, readOnlyRootFilesystem, drop ALL capabilities)
- **HPA** — autoscale 2–10 replicas on CPU 70% / memory 80%
- **PDB** — minimum 2 replicas available during node maintenance
- **NetworkPolicy** — deny all except ingress controller → app and app → postgres/redis/DNS/HTTPS
- **Ingress** — TLS via cert-manager, nginx rate limiting

---

## Compatibility

| Distribution | Status |
|-------------|--------|
| Ubuntu 22.04 LTS | Fully tested |
| Ubuntu 24.04 LTS | Fully tested |
| Debian 12 | Fully tested |
| Any systemd Linux | Most scripts work |

- Kernel: 5.15+ required, 6.x recommended
- Shell: bash 4.3+ (associative arrays, namerefs)
- Ansible: 2.12+
- Docker: 24+
- kubectl: 1.28+

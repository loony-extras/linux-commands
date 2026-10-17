# systemd

Units, timers, dependencies and cgroups.

---

## Files

- [myapp.service](myapp.service)

---

## Usage

`myapp.service` is a hardened production app unit (`/etc/systemd/system/`): non-root user,
PrivateTmp, ProtectSystem, MemoryMax and resource limits. For a timer example see
[system/backup](../backup/).

---

## systemd Architecture

systemd is PID 1 on all modern Debian/Ubuntu systems. It manages:
- Service lifecycle (start/stop/restart)
- Logging (journald)
- Timers (cron replacement)
- Sockets, devices, mounts, targets
- Resource control via cgroups

```
systemd (PID 1)
    │
    ├── Units: service, socket, timer, mount, device, target, path, scope, slice
    │
    ├── Targets (milestones): multi-user.target, graphical.target, rescue.target
    │
    └── Dependencies: Wants=, Requires=, After=, Before=, BindsTo=
```

### systemctl — main control tool

```bash
# Service lifecycle
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx           # Reload config without restart (if supported)
systemctl reload-or-restart nginx

# Persistence
systemctl enable nginx           # Enable at boot (creates symlink)
systemctl disable nginx          # Disable at boot
systemctl enable --now nginx     # Enable + start immediately
systemctl mask nginx             # Prevent from starting (even manually)
systemctl unmask nginx

# Status and inspection
systemctl status nginx
systemctl status nginx -l        # Full output (no truncation)
systemctl is-active nginx        # Returns 0 if active
systemctl is-enabled nginx       # Returns 0 if enabled
systemctl is-failed nginx

# List units
systemctl list-units                          # All active units
systemctl list-units --type=service           # Services only
systemctl list-units --state=failed           # Failed units
systemctl list-unit-files --type=service      # All installed services

# System state
systemctl isolate rescue.target    # Switch to rescue mode
systemctl default                  # Return to default target
systemctl get-default              # Show default target
systemctl set-default multi-user.target

# Reload systemd after editing unit files
systemctl daemon-reload

# Power management
systemctl poweroff
systemctl reboot
systemctl halt
systemctl suspend
```


---

## Custom systemd Unit Files

Unit files live in:
- `/lib/systemd/system/` — distro-provided (don't edit)
- `/etc/systemd/system/` — admin overrides (edit here)
- `/etc/systemd/system/<name>.d/` — drop-in overrides

### Simple Service Unit

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application Server
Documentation=https://github.com/myorg/myapp
After=network.target network-online.target
Wants=network-online.target
# Hard dependency — if postgresql fails, so does this
Requires=postgresql.service
After=postgresql.service

[Service]
Type=simple
# Run as this user/group (never run as root unless necessary)
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp

# The main process to run
ExecStart=/opt/myapp/bin/server --config /etc/myapp/config.yaml
# Reload command (sent on SIGHUP or `systemctl reload`)
ExecReload=/bin/kill -HUP $MAINPID
# Pre-start setup
ExecStartPre=/opt/myapp/bin/validate-config

# Environment
Environment=NODE_ENV=production
EnvironmentFile=-/etc/myapp/env    # - means: ignore if file missing

# Restart policy
Restart=on-failure
RestartSec=5s
StartLimitBurst=5
StartLimitIntervalSec=60s

# Logging (journald captures stdout/stderr automatically)
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/myapp /var/log/myapp

# Resource limits
LimitNOFILE=65536
MemoryMax=512M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
```

### Service Types

| Type | Behavior |
|------|----------|
| `simple` | Main process is ExecStart; ready immediately |
| `exec` | Like simple, but ready when exec succeeds |
| `forking` | Process forks; parent exits; systemd tracks child |
| `oneshot` | Runs to completion, then done (ExecStart exits) |
| `notify` | Process sends sd_notify() when ready |
| `dbus` | Ready when D-Bus name acquired |
| `idle` | Delays until all active jobs are dispatched |

### Forking service (traditional daemon)

```ini
[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
```

### Oneshot (scripts, migration, bootstrap tasks)

```ini
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/setup-network.sh
ExecStop=/usr/local/bin/teardown-network.sh
```

### Drop-in Overrides (without editing the original unit)

```bash
# Generate drop-in directory and open editor
systemctl edit nginx

# Or manually:
mkdir -p /etc/systemd/system/nginx.service.d/
cat > /etc/systemd/system/nginx.service.d/override.conf << 'EOF'
[Service]
# Increase open file limit for nginx
LimitNOFILE=100000
# Add environment variable
Environment=EXTRA_OPTS="-c /etc/nginx/nginx-extra.conf"
EOF

systemctl daemon-reload
systemctl restart nginx
```


---

## Systemd Timers (Cron Replacement)

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Daily Backup Job

[Service]
Type=oneshot
User=backup
ExecStart=/usr/local/bin/backup.sh
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily at 2 AM

[Timer]
# OnCalendar format: DayOfWeek Year-Month-Day Hour:Minute:Second
OnCalendar=*-*-* 02:00:00
# Randomize up to 30 minutes to avoid thundering herd
RandomizedDelaySec=1800
# Run immediately if missed (machine was off)
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl enable --now backup.timer
systemctl list-timers                  # Show all timers with next run time
systemctl status backup.timer
```


---

## Service Dependency Management

```
Wants=         soft dependency (continue even if dep fails)
Requires=      hard dependency (fail if dep fails)
Requisite=     dep must already be running (don't start it)
BindsTo=       stop this when dep stops
PartOf=        restart/stop with dep
Conflicts=     cannot run together
After=         ordering only (start after)
Before=        ordering only (start before)
```

```bash
# View dependency graph
systemctl list-dependencies nginx
systemctl list-dependencies nginx --reverse     # What depends on nginx?
systemctl list-dependencies multi-user.target   # Target dependencies

# Check what will start at boot
systemctl list-units --state=enabled --type=service
```


---

## Resource Control with cgroups

systemd uses cgroups v2 for resource accounting and limiting:

```ini
[Service]
# CPU
CPUQuota=25%              # Max 25% of one CPU core
CPUWeight=100             # Relative weight (default 100, range 1-10000)

# Memory
MemoryMax=512M            # Hard limit (OOM kill if exceeded)
MemoryHigh=400M           # Soft limit (throttle, but don't kill)
MemorySwapMax=0           # Disable swap for this service

# I/O
IOWeight=100              # Relative I/O weight
IOReadBandwidthMax=/dev/sda 50M   # Max 50MB/s read from /dev/sda
IOWriteBandwidthMax=/dev/sda 20M

# Tasks (threads/processes)
TasksMax=100
```

```bash
# Check resource usage
systemctl status myapp    # Shows CPU and memory usage
systemd-cgtop             # Live cgroup resource monitor
cat /sys/fs/cgroup/system.slice/myapp.service/memory.current
```

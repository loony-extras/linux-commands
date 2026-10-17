# sysctl

Kernel parameter tuning for security and performance.

---

## Files

- [examples.sh](examples.sh)
- [sysctl.conf](sysctl.conf)

---

## Usage

`sysctl.conf` deploys to `/etc/sysctl.d/99-production.conf`: security plus network
performance (BBR, somaxconn, syncookies).

```bash
sudo cp system/sysctl/sysctl.conf /etc/sysctl.d/99-production.conf
sudo sysctl --system
```

---

## Kernel Security Parameters (sysctl)

```bash
cat > /etc/sysctl.d/99-security.conf << 'EOF'
# =======================================================
# NETWORK SECURITY
# =======================================================

# Disable IP forwarding (enable only if this is a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing (prevent IP spoofing)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Enable reverse path filtering (anti-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log suspicious packets (martians)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP broadcast ping (smurf attack)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection (SYN cookies)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# TIME_WAIT protection
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1

# Disable TCP timestamps (reduces info leakage about uptime)
net.ipv4.tcp_timestamps = 0

# IPv6 (disable if not used)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# =======================================================
# KERNEL SECURITY
# =======================================================

# Restrict kernel logs to root only
kernel.dmesg_restrict = 1

# Restrict kernel pointer exposure (/proc/kallsyms)
kernel.kptr_restrict = 2

# Restrict ptrace (prevent process injection)
kernel.yama.ptrace_scope = 2

# Disable magic SysRq key (potential security risk)
kernel.sysrq = 0

# Protect hardlinks and symlinks (prevent symlink attacks in /tmp)
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Randomize memory layout (ASLR — Address Space Layout Randomization)
kernel.randomize_va_space = 2

# Disable core dumps (prevent sensitive info in dumps)
fs.suid_dumpable = 0
kernel.core_pattern = |/bin/false

# =======================================================
# PERFORMANCE / RELIABILITY
# =======================================================

# Increase file descriptor limit
fs.file-max = 2097152

# Reboot automatically on kernel panic
kernel.panic = 10
kernel.panic_on_oops = 1

# =======================================================
# NETWORK PERFORMANCE (production servers)
# =======================================================
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_orphans = 65535
net.ipv4.ip_local_port_range = 1024 65535

# BBR congestion control (if supported)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl -p /etc/sysctl.d/99-security.conf
```


---

## sysctl Tuning (Reference)

```bash
# View all sysctl parameters
sysctl -a 2>/dev/null | wc -l   # Count of all parameters

# Categories of interest
sysctl -a | grep ^kernel        # Kernel params
sysctl -a | grep ^net           # Network params
sysctl -a | grep ^vm            # VM/memory params
sysctl -a | grep ^fs            # Filesystem params

# Commonly tuned — production web server
cat > /etc/sysctl.d/99-production.conf << 'EOF'
# =====================================
# KERNEL
# =====================================
kernel.panic = 10                      # Reboot 10s after panic
kernel.panic_on_oops = 1              # Panic on kernel oops
kernel.randomize_va_space = 2         # Full ASLR
kernel.dmesg_restrict = 1            # Only root can read dmesg
kernel.kptr_restrict = 2             # Hide kernel pointers

# =====================================
# VM / MEMORY
# =====================================
vm.swappiness = 10                    # Prefer RAM over swap
vm.dirty_ratio = 15                  # Start sync writes at 15% dirty
vm.dirty_background_ratio = 5       # Start bg writes at 5% dirty
vm.vfs_cache_pressure = 50           # Keep inode/dentry cache longer
vm.overcommit_memory = 1             # Allow overcommit (needed for Java/fork)
vm.overcommit_ratio = 80

# =====================================
# NETWORK
# =====================================
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# =====================================
# FILESYSTEM
# =====================================
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.suid_dumpable = 0
EOF

sysctl -p /etc/sysctl.d/99-production.conf
```


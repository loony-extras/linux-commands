# Section 07 — Security Hardening

## 7.1 System Hardening Checklist

```
[ ] Disable unused services
[ ] Apply all security updates (unattended-upgrades)
[ ] Configure firewall (ufw/nftables)
[ ] SSH key-only auth, disable root login
[ ] Set strong password policies (pam_pwquality)
[ ] Configure fail2ban
[ ] Enable and configure auditd
[ ] Enable AppArmor/SELinux
[ ] Set secure kernel parameters (sysctl)
[ ] Remove SUID/SGID on unnecessary binaries
[ ] Restrict /tmp and /var/tmp with noexec
[ ] Enable and review logging (journald, rsyslog)
[ ] File integrity monitoring (AIDE/rkhunter)
[ ] Disable IPv6 if not used
[ ] Configure secure file permissions
[ ] Limit cron access
[ ] Disable core dumps
[ ] Set banner/MOTD for legal notice
[ ] Review open ports regularly
[ ] Enable process accounting
```

---

## 7.2 SSH Hardening (see also Section 06)

```bash
# Regenerate SSH host keys (after OS install from image)
rm /etc/ssh/ssh_host_*
ssh-keygen -A             # Regenerate all host key types
systemctl restart sshd

# Add legal banner
cat > /etc/ssh/banner.txt << 'EOF'
***************************************************************************
                        AUTHORIZED ACCESS ONLY
This system is for authorized users only. All activity is monitored and
logged. Unauthorized access attempts will be prosecuted to the full extent
of the law. Disconnect immediately if you are not an authorized user.
***************************************************************************
EOF
```

---

## 7.3 Kernel Security Parameters (sysctl)

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

## 7.4 fail2ban Setup

fail2ban monitors logs and bans IPs that show signs of brute-force attacks.

```bash
apt install -y fail2ban

# /etc/fail2ban/jail.local — override defaults (never edit jail.conf)
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban time (10 minutes)
bantime = 600
# Window to count failures in
findtime = 600
# Number of failures before ban
maxretry = 5
# Email alerts (configure sendmail/postfix)
destemail = admin@company.com
sendername = Fail2Ban
mta = sendmail
action = %(action_mwl)s      # Ban + email with log lines

# Backend to use for log monitoring
backend = systemd

# Ignore these IPs (management IPs, VPN ranges)
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 10.0.0.0/8

# ========================
# SERVICE-SPECIFIC JAILS
# ========================

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 3600              # 1 hour ban for SSH

[sshd-ddos]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 10
findtime = 10               # 10 attempts in 10 seconds = flood
bantime = 86400             # 24 hour ban

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[postfix]
enabled = true
port = smtp,465,submission
logpath = %(postfix_log)s

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s

[wordpress]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
filter = wordpress
EOF

systemctl enable --now fail2ban

# fail2ban management
fail2ban-client status                  # Overall status
fail2ban-client status sshd            # SSH jail status
fail2ban-client set sshd banip 1.2.3.4  # Manually ban
fail2ban-client set sshd unbanip 1.2.3.4  # Unban
fail2ban-client get sshd banlist       # List banned IPs
fail2ban-client reload                 # Reload config
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf  # Test filter
```

---

## 7.5 Intrusion Detection — auditd

auditd logs security-relevant system calls and file access at the kernel level.

```bash
apt install -y auditd audispd-plugins

# /etc/audit/rules.d/99-custom.rules
cat > /etc/audit/rules.d/99-custom.rules << 'EOF'
# Remove any existing rules
-D

# Buffer size (increase if seeing "backlog limit exceeded")
-b 8192

# Failure action: 2=kernel panic, 1=printk (use 1 to avoid DoS)
-f 1

# ========================
# IDENTITY CHANGES
# ========================
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# ========================
# SESSION TRACKING
# ========================
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
-w /var/run/utmp -p wa -k session

# ========================
# PRIVILEGE ESCALATION
# ========================
# Monitor SUID/SGID execution
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k setuid
-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k setuid

# sudo usage
-w /usr/bin/sudo -p x -k sudo
-w /usr/bin/su -p x -k su

# ========================
# SYSTEM CALLS
# ========================
# Module loading/unloading
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# Process injection attempts
-a always,exit -F arch=b64 -S ptrace -k ptrace

# ========================
# FILE INTEGRITY
# ========================
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /var/spool/cron/ -p wa -k cron

# Binary directories
-w /usr/bin -p wa -k binaries
-w /usr/sbin -p wa -k binaries
-w /usr/local/bin -p wa -k binaries

# ========================
# NETWORK CONFIG
# ========================
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_config
-w /etc/hosts -p wa -k network_config
-w /etc/network/ -p wa -k network_config
-w /etc/netplan/ -p wa -k network_config

# ========================
# MAKE RULES IMMUTABLE
# (requires reboot to change — stops attackers from disabling audit)
# ========================
-e 2
EOF

systemctl enable --now auditd
augenrules --load                      # Load rules

# Query audit log
ausearch -k identity                   # Events tagged 'identity'
ausearch -k sshd_config -i            # Human-readable
ausearch -ts today -k sudo            # Today's sudo usage
ausearch -ua www-data                  # Activity by user/uid
ausearch -p 1234                       # By PID
aureport                               # Summary report
aureport --auth                        # Authentication report
aureport --failed                      # Failed events
aureport --summary                     # Overview
```

---

## 7.6 File Integrity Monitoring — AIDE

```bash
apt install -y aide aide-common

# Configure AIDE — /etc/aide/aide.conf
cat > /etc/aide/aide.conf << 'EOF'
# AIDE configuration
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
database_new=file:/var/lib/aide/aide.db.new
gzip_dbout=yes

# Default check: permissions, inode, user, group, size, mtime, ctime, md5, sha256
NORMAL = p+i+u+g+s+m+c+md5+sha256

# Config files — check content, not mtime
CONTENT = p+u+g+md5+sha256

# Logs — allow size and mtime to change
LOGS = p+u+g

# What to monitor
/etc NORMAL
/bin NORMAL
/sbin NORMAL
/usr/bin NORMAL
/usr/sbin NORMAL
/usr/local/bin NORMAL
/boot NORMAL
/lib NORMAL
/lib64 NORMAL

# Exclude frequently changing paths
!/proc
!/sys
!/dev
!/run
!/tmp
!/var/log
!/var/cache
!/var/lib/apt
!/var/lib/dpkg
EOF

# Initialize database (first run)
aide --init
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Check for changes
aide --check

# Update database after legitimate changes
aide --update
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Daily cron check
cat > /etc/cron.d/aide << 'EOF'
0 3 * * * root /usr/bin/aide --check 2>&1 | /usr/bin/mail -s "AIDE Report: $(hostname)" admin@company.com
EOF
```

### rkhunter — rootkit detection

```bash
apt install -y rkhunter

# Update signatures and properties
rkhunter --update
rkhunter --propupd             # Baseline (run after every legitimate change)

# Scan
rkhunter --check               # Interactive
rkhunter --check --skip-keypress --report-warnings-only  # For cron

# Configure
sed -i 's/UPDATE_MIRRORS=0/UPDATE_MIRRORS=1/' /etc/rkhunter.conf
sed -i 's/MIRRORS_MODE=1/MIRRORS_MODE=0/' /etc/rkhunter.conf
sed -i 's/MAIL-ON-WARNING=""/MAIL-ON-WARNING="admin@company.com"/' /etc/rkhunter.conf

# Weekly cron
cat > /etc/cron.weekly/rkhunter << 'EOF'
#!/bin/bash
rkhunter --update --nocolors --skip-keypress
rkhunter --check --nocolors --skip-keypress --report-warnings-only 2>&1 \
  | mail -s "rkhunter report: $(hostname)" admin@company.com
EOF
chmod +x /etc/cron.weekly/rkhunter
```

---

## 7.7 Common Attack Vectors & Prevention

### Privilege Escalation Prevention

```bash
# 1. SUID/SGID binary audit — only known binaries should have these
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null > /tmp/suid_list
# Compare with a known-good list; investigate unknowns

# 2. Writable directories with sticky bit checks
find / -xdev -type d -perm -o+w 2>/dev/null | grep -v -E '^(/proc|/sys|/dev|/tmp|/var/tmp)'

# 3. PATH manipulation prevention
# Ensure no . in PATH for root
grep "PATH=.*\." /root/.bashrc /root/.profile /etc/environment

# 4. Remove unnecessary SUID bits
chmod u-s /usr/bin/at           # Example — remove SUID if at not needed
chmod u-s /usr/bin/newgrp       # Remove if not needed

# 5. Restrict cron
echo "root" > /etc/cron.allow   # Only root can use cron
chmod 600 /etc/cron.allow

# 6. Disable Ctrl+Alt+Del reboot
systemctl mask ctrl-alt-del.target

# 7. Restrict compiler access (prevent on-server compilation by attackers)
chmod 750 /usr/bin/gcc /usr/bin/g++ /usr/bin/cc 2>/dev/null || true
chown root:security /usr/bin/gcc 2>/dev/null || true

# 8. Disable USB storage (high-security environments)
cat > /etc/modprobe.d/disable-usb-storage.conf << 'EOF'
install usb-storage /bin/false
EOF
```

### Log Monitoring Strategy

```bash
# Key log files to monitor
# /var/log/auth.log    — authentication (SSH, sudo, su)
# /var/log/syslog      — general system
# /var/log/kern.log    — kernel messages
# /var/log/fail2ban.log — ban events
# /var/log/audit/audit.log — auditd events
# /var/log/nginx/       — web access/error
# journalctl            — systemd journal (all of the above + more)

# Real-time monitoring script
watch_auth_log() {
  journalctl -f -u ssh -u sudo \
    --output=short-iso \
    | grep -E "Failed|Accepted|COMMAND|session opened"
}

# Alert on new root logins
grep "Accepted.*root" /var/log/auth.log | tail -20

# Count failed SSH attempts by IP
grep "Failed password" /var/log/auth.log \
  | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -20

# Detect port scans in firewall logs
grep "\[nftables-drop\]" /var/log/kern.log \
  | awk '{print $NF}' | grep "SRC=" \
  | sed 's/SRC=//' | sort | uniq -c | sort -rn | head -20
```

---

## 7.8 Disable Unnecessary Services

```bash
# List all enabled services
systemctl list-unit-files --type=service --state=enabled

# Common services to disable on servers
services_to_disable=(
  avahi-daemon          # mDNS discovery
  cups                  # Printing
  bluetooth             # Bluetooth
  ModemManager          # Modem
  accounts-daemon       # AccountsService
  whoopsie              # Error reporting
  apport                # Crash reporting
)

for svc in "${services_to_disable[@]}"; do
  if systemctl is-enabled "$svc" &>/dev/null; then
    systemctl disable --now "$svc"
    echo "Disabled: $svc"
  fi
done
```

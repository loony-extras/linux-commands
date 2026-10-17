# System Hardening

Hardening checklist, attack vectors and service minimisation.

---

## Files

- [harden.sh](harden.sh)

---

## Usage

```bash
sudo bash security/hardening/harden.sh
```

/tmp noexec, SUID removal, core dump disable, /proc hidepid, cron restriction,
password policy and SSH key-only enforcement. Run after
[system/installation](../../system/installation/).

---

## System Hardening Checklist

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

## Common Attack Vectors & Prevention

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

## Disable Unnecessary Services

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

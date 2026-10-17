#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Security Hardening Script
# =============================================================================
# Run AFTER initial-setup.sh. Applies deeper security controls.
# Idempotent — safe to run multiple times.
# =============================================================================

set -euo pipefail

log()     { echo "[$(date +'%H:%M:%S')] $*"; }
error()   { echo "[ERROR] $*" >&2; exit 1; }
section() { echo -e "\n===== $* ====="; }

[[ $EUID -eq 0 ]] || error "Must run as root"

# ---------------------------------------------------------------------------
section "1. Secure /tmp and /var/tmp"
# ---------------------------------------------------------------------------
# Add noexec/nosuid/nodev to /tmp in fstab if not already set
if ! grep -q "/tmp.*noexec" /etc/fstab; then
  echo "tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,size=1G 0 0" >> /etc/fstab
  mount -o remount /tmp 2>/dev/null || true
  log "/tmp secured with noexec,nosuid,nodev"
fi

# Bind-mount /var/tmp to /tmp (same restrictions)
if ! grep -q "var/tmp" /etc/fstab; then
  echo "/tmp /var/tmp none bind 0 0" >> /etc/fstab
  log "/var/tmp bound to /tmp"
fi

# ---------------------------------------------------------------------------
section "2. Remove Unnecessary SUID/SGID Bits"
# ---------------------------------------------------------------------------
# Audit SUID/SGID binaries — only strip ones that are clearly unnecessary
SUID_TO_STRIP=(
  /usr/bin/at
  /usr/bin/rcp
  /usr/bin/rlogin
  /usr/bin/rsh
  /usr/sbin/uucp
  /usr/sbin/uux
)

for binary in "${SUID_TO_STRIP[@]}"; do
  if [[ -u "$binary" ]] 2>/dev/null; then
    chmod u-s "$binary"
    log "Removed SUID from: $binary"
  fi
done

log "Current SUID binaries:"
find / -xdev -perm -4000 -type f 2>/dev/null | sort | tee /var/log/suid-audit.log

# ---------------------------------------------------------------------------
section "3. Disable Core Dumps"
# ---------------------------------------------------------------------------
cat >> /etc/security/limits.d/99-disable-coredump.conf << 'EOF'
* soft core 0
* hard core 0
EOF

echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/99-security.conf
echo "kernel.core_pattern = |/bin/false" >> /etc/sysctl.d/99-security.conf
sysctl -p /etc/sysctl.d/99-security.conf
log "Core dumps disabled"

# ---------------------------------------------------------------------------
section "4. Restrict cron access"
# ---------------------------------------------------------------------------
# Only root can use cron by default
if [[ ! -f /etc/cron.allow ]]; then
  echo "root" > /etc/cron.allow
  chmod 600 /etc/cron.allow
  rm -f /etc/cron.deny
  log "cron.allow restricted to root"
fi

# Restrict at
if command -v at &>/dev/null; then
  echo "root" > /etc/at.allow
  chmod 600 /etc/at.allow
  rm -f /etc/at.deny
fi

# ---------------------------------------------------------------------------
section "5. Secure /proc Mounts"
# ---------------------------------------------------------------------------
if ! grep -q "hidepid" /etc/fstab; then
  # hidepid=2: users can only see their own processes in /proc
  echo "proc /proc proc defaults,hidepid=2 0 0" >> /etc/fstab
  mount -o remount,hidepid=2 /proc 2>/dev/null || true
  log "/proc hardened with hidepid=2"
fi

# ---------------------------------------------------------------------------
section "6. Password and Account Policies"
# ---------------------------------------------------------------------------
# Enforce SHA-512 password hashing
sed -i 's/ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' /etc/login.defs
sed -i 's/SHA_CRYPT_MIN_ROUNDS.*/SHA_CRYPT_MIN_ROUNDS 65536/' /etc/login.defs

# Password aging defaults
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs

log "Password policies set: max=90d, min=7d, warn=14d, SHA512"

# ---------------------------------------------------------------------------
section "7. SSH Final Hardening"
# ---------------------------------------------------------------------------
# Ensure PasswordAuthentication is off (assumes keys are deployed)
if [[ -f /root/.ssh/authorized_keys ]] || find /home -name authorized_keys 2>/dev/null | grep -q .; then
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' \
    /etc/ssh/sshd_config.d/99-hardening.conf
  sshd -t && systemctl reload sshd
  log "SSH PasswordAuthentication disabled (keys detected)"
else
  log "WARNING: No authorized_keys found — keeping PasswordAuthentication yes"
fi

# Regenerate host keys (remove any default/image-baked keys)
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
ssh-keygen -A
log "SSH host keys regenerated"

# ---------------------------------------------------------------------------
section "8. World-Writable Files Audit"
# ---------------------------------------------------------------------------
log "Scanning for world-writable files (excluding /proc /sys /dev)..."
find / -xdev -type f -perm -o+w \
  ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" \
  2>/dev/null | tee /var/log/world-writable-audit.log | head -20

WW_COUNT=$(wc -l < /var/log/world-writable-audit.log)
log "Found $WW_COUNT world-writable files — review /var/log/world-writable-audit.log"

# ---------------------------------------------------------------------------
section "9. Log Monitoring Setup"
# ---------------------------------------------------------------------------
# logwatch daily digest
if command -v logwatch &>/dev/null; then
  cat > /etc/logwatch/conf/logwatch.conf << 'EOF'
Output = mail
Format = html
MailTo = root
MailFrom = logwatch@localhost
Range = Yesterday
Detail = High
Service = All
EOF
  log "logwatch configured for daily reports"
fi

# ---------------------------------------------------------------------------
section "10. Final rkhunter Baseline"
# ---------------------------------------------------------------------------
rkhunter --update --nocolors 2>/dev/null || true
rkhunter --propupd --nocolors 2>/dev/null || true
log "rkhunter baseline updated"

echo
echo "============================================================"
echo " HARDENING COMPLETE"
echo " Review logs:"
echo "   /var/log/suid-audit.log"
echo "   /var/log/world-writable-audit.log"
echo "============================================================"

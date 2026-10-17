# auditd

Kernel audit rules and intrusion detection.

---

## Files

- [auditd.rules](auditd.rules)

---

## Usage

`auditd.rules` deploys to `/etc/audit/rules.d/99-custom.rules`: CIS-aligned rules for
identity, sudo, SUID, modules, cron and SSH config changes.

---

## Intrusion Detection — auditd

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


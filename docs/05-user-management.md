# Section 05 — User Management & Permissions

## 5.1 User and Group Management

### Core Files
- `/etc/passwd` — user accounts (name, UID, GID, home, shell)
- `/etc/shadow` — hashed passwords and aging policy
- `/etc/group` — group definitions
- `/etc/gshadow` — group passwords (rarely used)

```bash
# /etc/passwd format:
# username:x:UID:GID:GECOS:home:shell
# x means password is in /etc/shadow
# UID 0 = root; 1-999 = system accounts; 1000+ = regular users

# useradd — create user
useradd -m -s /bin/bash -c "John Doe" john         # Normal user
useradd -m -s /bin/bash -G sudo,docker john         # With group membership
useradd -r -s /usr/sbin/nologin myservice           # System account (no login)
useradd -u 1500 -g users john                       # Specific UID and primary group
useradd -d /opt/myapp myapp                         # Custom home directory
useradd -e 2024-12-31 contractor                    # Account expiry date

# Set or change password
passwd john                                          # Prompt for new password
echo "john:newpassword" | chpasswd                  # Non-interactive
openssl rand -base64 12 | tee /dev/tty | passwd --stdin john  # Random password

# usermod — modify user
usermod -aG docker john                  # Add to group (-a = append, don't remove others)
usermod -aG sudo,docker,www-data john   # Add to multiple groups
usermod -s /bin/zsh john                # Change shell
usermod -d /new/home -m john            # Move home directory
usermod -l newname oldname              # Rename user
usermod -L john                         # Lock account (! prefix in shadow)
usermod -U john                         # Unlock account
usermod -e 2025-06-01 contractor        # Set account expiry
usermod -e "" john                      # Remove expiry (never expires)

# userdel — delete user
userdel john                            # Delete user (keep home dir)
userdel -r john                         # Delete user AND home directory
userdel -f john                         # Force (even if logged in — dangerous)

# Query user info
id john                                  # UID, GID, groups
id                                       # Current user
who                                      # Who is logged in
w                                        # Logged-in users with activity
last                                     # Login history
lastb                                    # Failed login history
lastlog                                  # Last login for all users
finger john                             # User info (if finger installed)

# groupadd — create group
groupadd developers
groupadd -g 2000 devops                 # Specific GID
groupadd -r systemgroup                 # System group (GID < 1000)

# groupmod — modify group
groupmod -n newname oldname             # Rename group
groupmod -g 2100 developers             # Change GID

# groupdel — delete group
groupdel developers                     # Group must not be anyone's primary group

# gpasswd — manage group membership
gpasswd -a john developers              # Add user to group
gpasswd -d john developers              # Remove user from group
gpasswd -M john,jane developers         # Set exact member list
newgrp developers                       # Switch primary group in current session
```

---

## 5.2 Password Policies

```bash
# /etc/shadow format:
# user:$algorithm$salt$hash:lastchange:min:max:warn:inactive:expire:reserved
# $6$ = SHA-512 (default), $5$ = SHA-256, $2y$ = bcrypt

# chage — password aging
chage -l john                           # List aging info
chage -M 90 john                        # Max password age (days)
chage -m 7 john                         # Minimum age (prevent immediate reuse)
chage -W 14 john                        # Warning days before expiry
chage -I 30 john                        # Inactive days after expiry before lock
chage -E 2025-12-31 john               # Account expiry date
chage -d 0 john                         # Force password change on next login

# Global password policy (PAM pam_pwquality)
apt install -y libpam-pwquality

cat > /etc/security/pwquality.conf << 'EOF'
# Minimum password length
minlen = 14
# Require at least N character classes (upper,lower,digit,special)
minclass = 3
# Maximum number of same consecutive characters
maxrepeat = 2
# Maximum number of same consecutive characters in same class
maxclassrepeat = 4
# Check against username
usercheck = 1
# Dictionary check
dictcheck = 1
# Number of characters that must change from old password
difok = 6
EOF

# /etc/login.defs — system-wide defaults for useradd/passwd
grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE|UID_MIN|UID_MAX" /etc/login.defs
# Edit to enforce:
# PASS_MAX_DAYS 90
# PASS_MIN_DAYS 7
# PASS_WARN_AGE 14
```

---

## 5.3 sudo Configuration

```bash
# Edit sudoers safely (uses visudo, validates syntax)
visudo                                  # Edit /etc/sudoers
visudo -f /etc/sudoers.d/myconf         # Edit a drop-in file

# /etc/sudoers syntax:
# who  where=(as_whom) what
# user ALL=(ALL:ALL) ALL              # User can run anything as anyone
# %group ALL=(ALL) NOPASSWD: ALL      # Group, no password

# Best practice: drop-in files in /etc/sudoers.d/
cat > /etc/sudoers.d/90-developers << 'EOF'
# Developers can restart app services without a password
%developers ALL=(root) NOPASSWD: /bin/systemctl restart myapp, \
                                   /bin/systemctl restart nginx, \
                                   /bin/systemctl status *

# Deploy user: only specific commands
deploy ALL=(root) NOPASSWD: /usr/bin/rsync, \
                              /bin/systemctl reload nginx

# Sysadmins: full sudo (with password)
%sysadmins ALL=(ALL:ALL) ALL
EOF

chmod 440 /etc/sudoers.d/90-developers

# sudo configuration options
# Defaults env_reset                  # Reset environment on sudo
# Defaults mail_badpass               # Email on wrong password
# Defaults logfile="/var/log/sudo.log"
# Defaults log_input, log_output      # Log all I/O (forensics)
# Defaults timestamp_timeout=5        # Minutes before re-prompting
# Defaults requiretty                 # Must have TTY (prevents cron sudo)

# Check what a user can do with sudo
sudo -l -U john

# Run as specific user
sudo -u www-data ls /var/www

# Run as specific user and group
sudo -u www-data -g www-data id

# sudoreplay (if log_input/output enabled)
sudoreplay -l                          # List sessions
sudoreplay <session-id>               # Replay session
```

---

## 5.4 PAM (Pluggable Authentication Modules)

PAM controls how authentication works for services (ssh, sudo, su, login).

### Key files
- `/etc/pam.d/` — per-service PAM config
- `/lib/security/` or `/usr/lib/x86_64-linux-gnu/security/` — modules
- `/etc/security/` — module config files

### PAM config format
```
type  control  module  arguments
```

- **type**: `auth` | `account` | `password` | `session`
- **control**: `required` | `requisite` | `sufficient` | `optional` | `[success=N]`

```
required   — must succeed; failure continues (to hide which module failed)
requisite  — must succeed; failure stops immediately
sufficient — if succeeds, skip remaining (if none required failed)
optional   — failure doesn't matter unless it's the only module
```

```bash
# /etc/pam.d/sshd example — add these BEFORE other lines
# Deny login if /etc/nologin exists
auth    required  pam_nologin.so

# Rate-limit failed attempts (fail2ban alternative in PAM)
auth    required  pam_faillock.so preauth silent deny=5 unlock_time=900
auth    [default=die] pam_faillock.so authfail deny=5 unlock_time=900
auth    sufficient pam_faillock.so authsucc

# /etc/pam.d/common-password — password strength
password required pam_pwquality.so retry=3

# Lock screen after N failed attempts using faillock
# Check lock status
faillock --user john
# Unlock
faillock --user john --reset

# /etc/pam.d/common-session — run scripts after login
session optional pam_exec.so /usr/local/bin/post-login.sh

# Time-based access restriction (/etc/security/time.conf)
# Format: service;ttys;users;times
cat >> /etc/security/time.conf << 'EOF'
# Block SSH access outside business hours for contractors
sshd;*;contractor;Al0800-1800
EOF
# In /etc/pam.d/sshd: account required pam_time.so

# Two-factor auth with Google Authenticator
apt install -y libpam-google-authenticator
# Add to /etc/pam.d/sshd: auth required pam_google_authenticator.so
# In /etc/ssh/sshd_config: ChallengeResponseAuthentication yes
```

---

## 5.5 File Permission Model (recap + advanced)

```bash
# umask — default permission mask
umask                              # Show current (e.g., 0022)
# umask 0022 means:
#   files: 666 - 022 = 644 (rw-r--r--)
#   dirs:  777 - 022 = 755 (rwxr-xr-x)
umask 0027                         # More restrictive: files=640, dirs=750
# Set globally in /etc/profile or /etc/pam.d/common-session:
# session optional pam_umask.so umask=0027

# Find files with dangerous permissions
find / -xdev -perm -4000 -type f 2>/dev/null    # SUID files
find / -xdev -perm -2000 -type f 2>/dev/null    # SGID files
find / -xdev -perm -o+w -type f 2>/dev/null     # World-writable files
find / -xdev -nouser 2>/dev/null                 # Files with no owner
find / -xdev -nogroup 2>/dev/null               # Files with no group

# Restrict access to sensitive files
chmod 600 /etc/ssh/ssh_host_*_key    # Private SSH host keys
chmod 640 /etc/shadow                # Shadow file
chmod 440 /etc/sudoers               # sudoers
chmod 700 /root                      # Root's home
chmod 711 /home                      # Home base dir
chmod 750 /home/john                 # User's home
```

---

## 5.6 SELinux / AppArmor Basics

### AppArmor (Ubuntu default)

AppArmor restricts what individual programs can do, even if compromised.

```bash
# Check AppArmor status
apparmor_status
aa-status

# AppArmor modes
# enforcing — policy is enforced (violations denied and logged)
# complain  — violations logged but allowed (learning mode)
# disabled  — no policy applied

# Manage profiles
aa-enforce /etc/apparmor.d/usr.sbin.nginx    # Set to enforce
aa-complain /etc/apparmor.d/usr.sbin.nginx  # Set to complain mode
aa-disable /etc/apparmor.d/usr.sbin.nginx   # Disable profile

# Reload all profiles
systemctl reload apparmor
apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# Simple profile example
cat > /etc/apparmor.d/usr.local.bin.myapp << 'EOF'
#include <tunables/global>

/usr/local/bin/myapp {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Capabilities
  capability net_bind_service,

  # Read access
  /etc/myapp/** r,
  /usr/local/lib/myapp/** r,

  # Read/write access
  /var/lib/myapp/** rw,
  /var/log/myapp/** rw,

  # Network
  network tcp,

  # Deny everything else
  deny /etc/shadow r,
  deny /proc/*/mem rw,
}
EOF
apparmor_parser -r /etc/apparmor.d/usr.local.bin.myapp

# Investigate violations
journalctl | grep DENIED | grep myapp
grep DENIED /var/log/kern.log
```

### SELinux (on RHEL/CentOS — install on Debian/Ubuntu with `apt install selinux-basics`)

```bash
# Check status
getenforce                   # Enforcing / Permissive / Disabled
sestatus                     # Detailed status

# Modes
setenforce 0                 # Permissive (log but don't deny) — for debugging
setenforce 1                 # Enforcing

# Persistent mode in /etc/selinux/config:
# SELINUX=enforcing

# Check file context
ls -Z /var/www/html
ls -lZ /etc/passwd

# Set file context
chcon -t httpd_sys_content_t /var/www/html/index.html
restorecon -Rv /var/www/html/           # Restore default contexts

# View AVC denials
ausearch -m avc -ts recent
audit2why < /var/log/audit/audit.log    # Explain denials
audit2allow -a                          # Suggest policy to allow

# Boolean — toggle common behaviors
getsebool -a                            # List all booleans
getsebool httpd_can_network_connect     # Check one
setsebool -P httpd_can_network_connect on   # Set persistent
```

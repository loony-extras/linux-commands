# Users & Groups

Accounts, groups and password policy.

---

## Files

- [user-setup.sh](user-setup.sh)

---

## Usage

```bash
sudo bash system/users/user-setup.sh --action <create|add-key|rotate-keys|lock|unlock|audit|report>

sudo bash system/users/user-setup.sh --action create --username john --groups docker,sudo
sudo bash system/users/user-setup.sh --action add-key --username john --key-file ~/.ssh/id_ed25519.pub
sudo bash system/users/user-setup.sh --action audit
sudo bash system/users/user-setup.sh --action report
```

---

## User and Group Management

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

## Password Policies

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


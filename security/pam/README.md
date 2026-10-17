# PAM

Pluggable Authentication Modules.

---

## PAM (Pluggable Authentication Modules)

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


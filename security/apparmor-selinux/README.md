# AppArmor & SELinux

Mandatory access control.

---

## SELinux / AppArmor Basics

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

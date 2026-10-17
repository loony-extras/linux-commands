# sudo

Privilege delegation.

---

## sudo Configuration

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


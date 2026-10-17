# AIDE

File integrity monitoring.

---

## File Integrity Monitoring — AIDE

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


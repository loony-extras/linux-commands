# apt & dpkg

Debian package management.

---

## Package Management (apt / dpkg)

```bash
# Update package index
apt update

# Upgrade all packages
apt upgrade -y

# Full upgrade (handles dependency changes)
apt full-upgrade -y

# Install a package
apt install -y nginx

# Remove package (keep config)
apt remove nginx

# Remove package AND config
apt purge nginx

# Remove unused deps
apt autoremove

# Search for a package
apt search "web server"

# Show package details
apt show nginx

# List installed packages
dpkg -l

# Find which package owns a file
dpkg -S /usr/bin/vim

# List files installed by a package
dpkg -L vim

# Install a local .deb file
dpkg -i package.deb

# Hold a package at current version (prevent upgrades)
apt-mark hold nginx

# Unhold
apt-mark unhold nginx

# List held packages
apt-mark showhold
```

### Unattended Upgrades (security patches only)

```bash
apt install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Enable the timer
systemctl enable --now unattended-upgrades
```


---

## apt Deep Dive

### The apt stack
```
apt                     ← high-level CLI (you use this)
apt-get / apt-cache     ← lower-level (scripting)
libapt-pkg              ← library
dpkg                    ← lowest level (installs .deb files)
```

### Repository Management

```bash
# /etc/apt/sources.list — main repo list
# /etc/apt/sources.list.d/*.list — drop-in repos (preferred)

# Modern sources.list format (one-line deb822 format for Ubuntu 24.04+):
# /etc/apt/sources.list.d/ubuntu.sources

# Add a third-party repo (example: Docker)
# Step 1: Add GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker.gpg
chmod a+r /usr/share/keyrings/docker.gpg

# Step 2: Add repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list

apt update

# PPA (Personal Package Archive) — Ubuntu only
add-apt-repository ppa:deadsnakes/ppa
apt update
apt install python3.12

# Remove PPA
add-apt-repository --remove ppa:deadsnakes/ppa

# List configured repos
apt-cache policy                        # All repos
cat /etc/apt/sources.list.d/*.list
```

### Version Pinning and Package Priority

```bash
# /etc/apt/preferences.d/ — control which versions get installed

# Pin a package to a specific version
cat > /etc/apt/preferences.d/pin-nginx << 'EOF'
Package: nginx
Pin: version 1.24.*
Pin-Priority: 1001      # >1000 = install even if not the latest
EOF

# Pin a package to a specific release
cat > /etc/apt/preferences.d/pin-backports << 'EOF'
Package: *
Pin: release a=focal-backports
Pin-Priority: 400        # Lower than default (500), so not auto-installed
EOF

# Show available versions of a package
apt-cache madison nginx
apt-cache policy nginx

# Install specific version
apt install nginx=1.24.0-1ubuntu1

# Hold package at current version
apt-mark hold nginx
apt-mark unhold nginx
apt-mark showhold

# Show what would be upgraded without actually doing it
apt list --upgradable
apt upgrade --dry-run
```

### apt-cache — query package metadata

```bash
apt-cache show nginx                    # Full package details
apt-cache showpkg nginx                 # Reverse dependencies
apt-cache depends nginx                 # Dependencies
apt-cache rdepends nginx               # Reverse dependencies
apt-cache search "web server"          # Search descriptions
apt-cache stats                         # Repository statistics
apt-cache dump | grep "Package:" | wc -l  # Count available packages
```


---

## dpkg Deep Dive

```bash
# Install local .deb file
dpkg -i package.deb

# Install and resolve dependencies (combines dpkg + apt)
apt install ./package.deb

# Remove (keep config files)
dpkg -r package

# Remove + config files
dpkg -P package              # or dpkg --purge

# List installed packages
dpkg -l                      # All packages
dpkg -l 'nginx*'            # Wildcard
dpkg -l | grep ^ii          # Only installed (ii = installed/installed)
dpkg -l | grep ^rc          # Removed but config files remain

# Package status codes (first two letters of dpkg -l):
# ii = installed
# rc = removed (config files remain)
# un = unknown/not installed
# hi = hold/installed
# di = deinstall requested

# Query
dpkg -s nginx               # Package status and info
dpkg -L nginx               # Files installed by package
dpkg -S /usr/sbin/nginx     # Which package owns this file

# Reconfigure
dpkg-reconfigure tzdata     # Re-run package setup wizard
dpkg-reconfigure locales

# Fix broken installs
dpkg --configure -a         # Configure all unconfigured packages
apt install -f              # Fix broken dependencies

# Extract .deb without installing
dpkg-deb -x package.deb /tmp/extracted/
dpkg-deb -I package.deb     # Show package info
dpkg-deb -c package.deb     # List contents

# Create a .deb package
mkdir -p mypackage/DEBIAN
cat > mypackage/DEBIAN/control << 'EOF'
Package: myapp
Version: 1.0.0
Architecture: amd64
Maintainer: Admin <admin@company.com>
Description: My custom application
Depends: python3, nginx
EOF
dpkg-deb --build mypackage
```


---

## Dependency Resolution

```bash
# See why a package is installed (reverse deps)
apt-cache rdepends --installed nginx

# Show install reason
apt-mark showmanual           # Manually installed packages
apt-mark showauto             # Auto-installed (pulled in as deps)

# Change install reason
apt-mark manual python3-requests   # Mark as manually installed
apt-mark auto python3-requests     # Mark as auto (will be autoremoved)

# Simulate install to see what would change
apt install --dry-run mypackage

# Resolve conflicts manually
apt install -f               # Fix broken packages
dpkg --configure -a          # Configure unconfigured packages

# Deborphan — find orphaned packages
apt install -y deborphan
deborphan                    # List orphaned lib packages
deborphan --guess-all        # All orphaned packages (not just libs)
apt purge $(deborphan)       # Remove them
```


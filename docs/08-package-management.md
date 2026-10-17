# Section 08 — Package Management & Build Systems

## 8.1 apt Deep Dive

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

## 8.2 dpkg Deep Dive

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

## 8.3 Building from Source

```bash
# General pattern for autotools (./configure, make)
# 1. Get source
wget https://example.com/myapp-1.0.tar.gz
tar -xzf myapp-1.0.tar.gz
cd myapp-1.0

# 2. Install build dependencies
apt install -y build-essential libssl-dev libpcre3-dev zlib1g-dev

# 3. Configure (check for required deps, set install paths)
./configure \
  --prefix=/usr/local \
  --bindir=/usr/local/bin \
  --sysconfdir=/etc/myapp \
  --with-ssl \
  --without-debug

# Read ./configure --help for all options

# 4. Build (use all CPUs)
make -j$(nproc)

# 5. Run tests (if available)
make check
make test

# 6. Install
sudo make install

# 7. Update dynamic linker cache
sudo ldconfig

# Uninstall (if make uninstall is supported)
sudo make uninstall

# CMake projects
mkdir build && cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SSL=ON
make -j$(nproc)
sudo make install

# Meson projects
meson setup build --prefix=/usr/local
cd build
ninja -j$(nproc)
sudo ninja install

# Compiling nginx from source (real example)
NGINX_VERSION="1.25.3"
apt install -y build-essential libpcre3-dev zlib1g-dev libssl-dev libgd-dev

wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}

./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_gzip_static_module \
  --with-threads \
  --with-file-aio

make -j$(nproc)
sudo make install
```

---

## 8.4 Dependency Resolution

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

---

## 8.5 Managing Multiple Python / Node Versions

```bash
# Python — use pyenv for version management
curl https://pyenv.run | bash

# Add to ~/.bashrc
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv install 3.12.0
pyenv install 3.11.5
pyenv global 3.12.0          # System default
pyenv local 3.11.5           # Per-directory (creates .python-version)
pyenv shell 3.10.0           # For current session only

# Node.js — use nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

nvm install 20               # Install Node 20 LTS
nvm install 18
nvm use 20                   # Switch to Node 20
nvm alias default 20         # Set default

# Go — official installer or goenv
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh
```

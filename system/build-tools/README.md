# Building from Source

Source builds and Python/Node version managers.

---

## Building from Source

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

## Managing Multiple Python / Node Versions

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

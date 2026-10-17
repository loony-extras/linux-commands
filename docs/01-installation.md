# Section 01 — Installation & System Setup

## 1.1 Ubuntu/Debian Minimal Server Install

### Recommended Install Profile (Ubuntu 22.04/24.04 Server)

During the installer:
- Select **Minimized** install
- Disable all snaps if possible (server use)
- Enable **OpenSSH server**
- Skip optional snaps

Post-install, strip further:

```bash
# Remove unnecessary packages
sudo apt purge --auto-remove \
  snapd \
  cloud-init \
  popularity-contest \
  apport \
  whoopsie

# Prevent snapd from being reinstalled
sudo apt-mark hold snapd

# Remove leftover snap directories
sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd
```

---

## 1.2 Disk Partitioning — MBR vs GPT

### MBR (Master Boot Record)
- Max 4 primary partitions (or 3 primary + 1 extended)
- Max disk size: 2 TB
- Use only on legacy BIOS systems

### GPT (GUID Partition Table)
- Up to 128 partitions by default
- Supports disks > 2 TB
- Required for UEFI systems
- Use for all modern installs

### Recommended Partition Layout (GPT + UEFI)

| Mount      | Size        | Type           | Filesystem |
|------------|-------------|----------------|------------|
| /boot/efi  | 512 MB      | EFI System     | FAT32      |
| /boot      | 1 GB        | Linux partition | ext4       |
| /          | 20–50 GB    | LVM or direct  | ext4/xfs   |
| /home      | Variable    | LVM            | ext4/xfs   |
| /var       | 10–20 GB    | LVM            | ext4/xfs   |
| /var/log   | 5–10 GB     | LVM            | ext4       |
| /tmp       | 2–4 GB      | LVM or tmpfs   | ext4/tmpfs |
| swap       | RAM size    | Linux swap     | swap       |

### Partitioning with parted (non-interactive)

```bash
# Replace /dev/sda with your disk
DISK=/dev/sda

parted -s "$DISK" mklabel gpt

# EFI partition (1–512MB)
parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

# /boot partition (513MB–1.5GB)
parted -s "$DISK" mkpart primary ext4 513MiB 1537MiB

# LVM partition (rest of disk)
parted -s "$DISK" mkpart primary 1537MiB 100%
parted -s "$DISK" set 3 lvm on

# Format EFI and boot
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
```

---

## 1.3 LVM Setup (Logical Volume Manager)

LVM adds a flexible abstraction layer between physical disks and filesystems, enabling
live resizing, snapshots, and striping without downtime.

```bash
# Physical Volume creation
pvcreate /dev/sda3

# Volume Group creation (name it after the server role or hostname)
vgcreate vg_system /dev/sda3

# Logical Volumes
lvcreate -L 30G  -n lv_root    vg_system
lvcreate -L 20G  -n lv_home    vg_system
lvcreate -L 15G  -n lv_var     vg_system
lvcreate -L 8G   -n lv_var_log vg_system
lvcreate -L 4G   -n lv_tmp     vg_system
lvcreate -L 4G   -n lv_swap    vg_system

# Format volumes
mkfs.ext4 /dev/vg_system/lv_root
mkfs.ext4 /dev/vg_system/lv_home
mkfs.ext4 /dev/vg_system/lv_var
mkfs.ext4 /dev/vg_system/lv_var_log
mkfs.ext4 /dev/vg_system/lv_tmp
mkswap    /dev/vg_system/lv_swap

# Activate swap
swapon /dev/vg_system/lv_swap
```

---

## 1.4 Filesystem Selection

### ext4
- Default for most Debian/Ubuntu installs
- Mature, journal-based, excellent recovery tools
- Good general-purpose choice for `/`, `/home`, `/var`
- Max file size: 16 TB; Max volume: 1 EB

### XFS
- High-performance for large files and high-throughput workloads
- Excellent parallel I/O (databases, media servers)
- Cannot shrink online (only grow)
- Preferred for `/var`, data volumes

### Btrfs
- Copy-on-write (CoW) filesystem
- Native snapshots, checksums, RAID support built in
- Use for: desktop, NAS, situations needing snapshot-based backups
- Avoid on heavy random-write databases (MySQL InnoDB, PostgreSQL)

```bash
# ext4 format with tuned options
mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 \
  -L root /dev/vg_system/lv_root

# XFS format
mkfs.xfs -L data /dev/vg_system/lv_var

# Btrfs with compression
mkfs.btrfs -L btrfs_pool /dev/sdb
mount -o compress=zstd /dev/sdb /mnt/data
```

---

## 1.5 GRUB Configuration

GRUB2 is the standard bootloader for Debian/Ubuntu.

### Key files
- `/etc/default/grub` — user-facing config
- `/etc/grub.d/` — generator scripts
- `/boot/grub/grub.cfg` — generated output (never edit directly)

```bash
# /etc/default/grub — recommended production settings
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="Production Server"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
# Security: enable auditing from boot
GRUB_CMDLINE_LINUX="audit=1 apparmor=1 security=apparmor"

# Regenerate grub config after any edit
sudo update-grub

# Reinstall grub to MBR (BIOS systems)
sudo grub-install /dev/sda

# Reinstall grub for UEFI
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu
```

### GRUB Password Protection (prevent single-user mode access)

```bash
# Generate hashed password
grub-mkpasswd-pbkdf2

# Add to /etc/grub.d/40_custom
cat >> /etc/grub.d/40_custom << 'EOF'
set superusers="grubadmin"
password_pbkdf2 grubadmin grub.pbkdf2.sha512.10000.<HASH_HERE>
EOF

sudo update-grub
```

---

## 1.6 Initial System Configuration

```bash
# Set hostname
hostnamectl set-hostname prod-server-01

# Set timezone
timedatectl set-timezone UTC

# Enable NTP sync
timedatectl set-ntp true

# Update locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Full system update
apt update && apt upgrade -y && apt autoremove -y

# Install baseline essentials
apt install -y \
  curl wget git vim tmux htop \
  net-tools nmap dnsutils \
  ufw fail2ban \
  rsync unzip \
  build-essential \
  ca-certificates gnupg \
  lsb-release \
  sysstat \
  auditd \
  apparmor apparmor-utils \
  logwatch \
  chrony
```

---

## 1.7 Package Management (apt / dpkg)

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

## 1.8 Kernel Version Management

```bash
# Check current kernel
uname -r

# List installed kernels
dpkg -l 'linux-image-*' | grep ^ii

# Install a specific kernel version
apt install linux-image-6.5.0-35-generic

# Remove an old kernel
apt purge linux-image-5.15.0-100-generic

# Pin the kernel (prevent auto-upgrade)
apt-mark hold linux-image-$(uname -r)

# Switch default kernel in GRUB
# Edit /etc/default/grub, set GRUB_DEFAULT to the entry number or title
# Then: sudo update-grub
```

---

## 1.9 Shell Environment Setup

### /etc/environment — system-wide environment variables

```bash
cat >> /etc/environment << 'EOF'
EDITOR=vim
VISUAL=vim
PAGER=less
LANG=en_US.UTF-8
EOF
```

### /etc/profile.d/ — drop-in scripts for login shells

```bash
# Create a custom system-wide profile
cat > /etc/profile.d/99-custom.sh << 'EOF'
# Unlimited core dumps for debugging (remove on hardened systems)
# ulimit -c unlimited

# Increase open file descriptor limit
ulimit -n 65536

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Prompt with hostname and path
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
```

### ~/.bashrc — per-user interactive shell

```bash
# Useful aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias top='htop'
alias ..='cd ..'
alias ...='cd ../..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git pull'

# Networking
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me'

# System info
alias sysinfo='echo "CPU: $(nproc) cores | RAM: $(free -h | awk "/^Mem/{print \$2}") | Disk: $(df -h / | awk "NR==2{print \$3}")/$(df -h / | awk "NR==2{print \$2}")"'
```

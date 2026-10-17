# Installation & Initial Setup

Minimal server install and first-boot configuration.

---

## Files

- [initial-setup.sh](initial-setup.sh)

---

## Usage

Run from the repo root on a fresh Ubuntu 22.04/24.04 server:

```bash
sudo bash system/installation/initial-setup.sh --hostname web-01 --admin-user deploy
```

Installs packages and sets hostname, timezone, admin user, SSH hardening, UFW, fail2ban,
auditd, sysctl and unattended-upgrades. Idempotent. Follow up with
[security/hardening](../../security/hardening/) and [networking/firewall](../../networking/firewall/).

---

## Ubuntu/Debian Minimal Server Install

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

## Initial System Configuration

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


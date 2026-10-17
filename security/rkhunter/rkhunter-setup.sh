#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — rkhunter Setup and Configuration
# =============================================================================

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Must run as root"; exit 1; }

log() { echo "[$(date +'%H:%M:%S')] $*"; }

log "Installing rkhunter"
apt-get install -y -q rkhunter

# ---------------------------------------------------------------------------
# Configure rkhunter
# ---------------------------------------------------------------------------
CONF=/etc/rkhunter.conf

# Email alerts
sed -i "s|^#MAIL-ON-WARNING=.*|MAIL-ON-WARNING=root|" "$CONF"
sed -i "s|^MAIL_CMD=.*|MAIL_CMD=mail -s \"[rkhunter] Warning found on \$(hostname)\" \$MAILTO|" "$CONF"

# Auto-update signatures
sed -i "s|^UPDATE_MIRRORS=0|UPDATE_MIRRORS=1|" "$CONF"
sed -i "s|^MIRRORS_MODE=1|MIRRORS_MODE=0|" "$CONF"

# Allow common Ubuntu/Debian paths that rkhunter may flag
cat >> "$CONF" << 'EOF'

# Ubuntu/Debian-specific whitelisting
SCRIPTWHITELIST=/usr/bin/egrep
SCRIPTWHITELIST=/usr/bin/fgrep
SCRIPTWHITELIST=/usr/bin/which
ALLOWHIDDENDIR=/dev/.udev
ALLOWHIDDENDIR=/dev/.static
ALLOWHIDDENDIR=/dev/.initramfs
ALLOWDEVFILE=/dev/.udev/rules.d/root.rules

# Allow preloaded libraries (common on Ubuntu)
ALLOWPROCDELETED=1
EOF

# ---------------------------------------------------------------------------
# Initialize / update and baseline
# ---------------------------------------------------------------------------
log "Updating rkhunter signatures"
rkhunter --update --nocolors 2>&1 | tail -5

log "Creating baseline (propupd)"
rkhunter --propupd --nocolors 2>&1 | tail -5

# ---------------------------------------------------------------------------
# Weekly cron job
# ---------------------------------------------------------------------------
cat > /etc/cron.weekly/rkhunter << 'CRON'
#!/bin/bash
rkhunter --update --nocolors --skip-keypress --quiet
rkhunter --check --nocolors --skip-keypress --report-warnings-only 2>&1 \
  | mail -s "[rkhunter] Weekly scan: $(hostname)" root
CRON
chmod +x /etc/cron.weekly/rkhunter

log "rkhunter configured. Weekly scan will mail root."
log "Run a manual scan: rkhunter --check --nocolors"

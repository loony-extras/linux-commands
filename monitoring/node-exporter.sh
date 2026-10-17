#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Prometheus Node Exporter Install
# =============================================================================
# Installs node_exporter as a systemd service.
# Runs as a dedicated low-privilege user.
#
# Usage: sudo bash monitoring/node-exporter.sh [--version 1.7.0]
# =============================================================================

set -euo pipefail

VERSION="${1:-1.7.0}"
ARCH="linux-amd64"
INSTALL_DIR="/usr/local/bin"
LOG_FILE="/var/log/node-exporter-install.log"

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[ERROR] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "Must run as root"

# Handle --version flag
if [[ "${1:-}" == "--version" ]]; then
  VERSION="$2"
fi

log "Installing Prometheus Node Exporter v$VERSION"

# Create system user
if ! id node_exporter &>/dev/null; then
  useradd -r -s /usr/sbin/nologin -d /var/lib/node_exporter node_exporter
  mkdir -p /var/lib/node_exporter
  chown node_exporter:node_exporter /var/lib/node_exporter
  log "Created user: node_exporter"
fi

# Download and verify
TMPDIR=$(mktemp -d)
trap 'rm -rf $TMPDIR' EXIT

TARBALL="node_exporter-${VERSION}.${ARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${TARBALL}"

log "Downloading: $URL"
curl -fsSL "$URL" -o "$TMPDIR/$TARBALL"
curl -fsSL "${URL}.sha256sums" -o "$TMPDIR/sha256sums"

# Verify checksum
cd "$TMPDIR"
grep "$TARBALL" sha256sums | sha256sum -c - || error "Checksum verification failed"
log "Checksum verified"

# Extract and install binary
tar -xzf "$TARBALL"
install -m 755 -o root -g root \
  "node_exporter-${VERSION}.${ARCH}/node_exporter" \
  "$INSTALL_DIR/node_exporter"

log "Installed: $INSTALL_DIR/node_exporter"

# ---------------------------------------------------------------------------
# Custom collector scripts directory (textfile collector)
# ---------------------------------------------------------------------------
mkdir -p /var/lib/node_exporter/textfile_collector
chown -R node_exporter:node_exporter /var/lib/node_exporter

# Example custom metric script (backup success tracking)
cat > /usr/local/bin/backup-metrics.sh << 'BACKUP_METRICS'
#!/bin/bash
# Run from cron; writes metrics for node_exporter textfile collector
OUTFILE=/var/lib/node_exporter/textfile_collector/backup.prom

BACKUP_LOG=/var/log/loony-backup.log
LAST_SUCCESS=0

if [[ -f "$BACKUP_LOG" ]]; then
  LAST_LINE=$(grep "Backup complete" "$BACKUP_LOG" | tail -1)
  if [[ -n "$LAST_LINE" ]]; then
    LAST_SUCCESS=$(date -d "$(echo "$LAST_LINE" | awk '{print $1,$2}')" +%s 2>/dev/null || echo 0)
  fi
fi

cat > "$OUTFILE" << EOF
# HELP backup_last_success_timestamp Unix timestamp of last successful backup
# TYPE backup_last_success_timestamp gauge
backup_last_success_timestamp $LAST_SUCCESS
EOF
BACKUP_METRICS
chmod +x /usr/local/bin/backup-metrics.sh

# Add to daily cron
echo "0 3 * * * root /usr/local/bin/backup-metrics.sh" \
  > /etc/cron.d/backup-metrics

# ---------------------------------------------------------------------------
# systemd service
# ---------------------------------------------------------------------------
cat > /etc/systemd/system/node-exporter.service << 'SERVICE'
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter

ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes \
  --collector.interrupts \
  --collector.tcpstat \
  --collector.nfs \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \
  --web.listen-address=:9100 \
  --web.telemetry-path=/metrics

Restart=on-failure
RestartSec=5s

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
ReadWritePaths=/var/lib/node_exporter

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now node-exporter

# ---------------------------------------------------------------------------
# UFW rule (allow from monitoring server)
# ---------------------------------------------------------------------------
if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
  MONITORING_IP="${MONITORING_IP:-}"
  if [[ -n "$MONITORING_IP" ]]; then
    ufw allow from "$MONITORING_IP" to any port 9100 comment "Prometheus node_exporter"
    log "UFW: allowed port 9100 from $MONITORING_IP"
  else
    log "Set MONITORING_IP env var to add UFW rule for node_exporter"
  fi
fi

log "Node Exporter installed and running on :9100"
log "Verify: curl -s http://localhost:9100/metrics | grep node_cpu"

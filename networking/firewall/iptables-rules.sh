#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — iptables Ruleset (legacy / fallback)
# =============================================================================
# For systems where nftables is not available.
# Prefer nftables on new installs (kernel 5.2+).
#
# Usage: sudo bash iptables-rules.sh [--dry-run]
# =============================================================================

set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ipt() {
  if (( DRY_RUN )); then
    echo "  [DRY] iptables $*"
  else
    iptables "$@"
  fi
}

log() { echo "[$(date +'%H:%M:%S')] $*"; }

[[ $EUID -eq 0 ]] || { echo "Must run as root"; exit 1; }

MGMT_CIDR="${MGMT_CIDR:-192.168.100.0/24}"
SSH_PORT="${SSH_PORT:-22}"

log "Applying iptables rules (dry-run=$DRY_RUN)"

# ---------------------------------------------------------------------------
# Flush and reset
# ---------------------------------------------------------------------------
log "Flushing existing rules"
ipt -F         # Flush filter chains
ipt -X         # Delete custom chains
ipt -t nat -F  # Flush NAT
ipt -t nat -X
ipt -t mangle -F
ipt -t mangle -X

# ---------------------------------------------------------------------------
# Default policies — DROP everything, selectively allow
# ---------------------------------------------------------------------------
ipt -P INPUT DROP
ipt -P FORWARD DROP
ipt -P OUTPUT ACCEPT

log "Default policies: INPUT=DROP, FORWARD=DROP, OUTPUT=ACCEPT"

# ---------------------------------------------------------------------------
# Custom chains for organization
# ---------------------------------------------------------------------------
ipt -N SSH_LIMIT    # Rate limiting for SSH
ipt -N HTTP_CHECKS  # HTTP validation

# ---------------------------------------------------------------------------
# INPUT rules (order matters — first match wins)
# ---------------------------------------------------------------------------

# Allow loopback
ipt -A INPUT -i lo -j ACCEPT

# Allow established/related connections (essential — must be early)
ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop explicitly invalid packets
ipt -A INPUT -m conntrack --ctstate INVALID -j LOG \
    --log-prefix "[ipt] INVALID: " --log-level 6
ipt -A INPUT -m conntrack --ctstate INVALID -j DROP

# Management network — full access
ipt -A INPUT -s "$MGMT_CIDR" -j ACCEPT

# ICMP (ping) — rate limited
ipt -A INPUT -p icmp --icmp-type echo-request \
    -m limit --limit 5/second --limit-burst 10 -j ACCEPT

# ---------------------------------------------------------------------------
# SSH — rate limited with recent module
# ---------------------------------------------------------------------------
ipt -A SSH_LIMIT -m recent --name SSH_BLOCK --rcheck --seconds 3600 \
    --hitcount 1 -j LOG --log-prefix "[ipt] SSH-BLOCKED: "
ipt -A SSH_LIMIT -m recent --name SSH_BLOCK --rcheck --seconds 3600 \
    --hitcount 1 -j DROP
ipt -A SSH_LIMIT -m recent --name SSH_FAIL --update --seconds 60 \
    --hitcount 10 -j SET --add-set SSH_BLOCK --mark
ipt -A SSH_LIMIT -m recent --name SSH_FAIL --update --seconds 60 \
    --hitcount 10 -j LOG --log-prefix "[ipt] SSH-RATELIMIT: "
ipt -A SSH_LIMIT -m recent --name SSH_FAIL --update --seconds 60 \
    --hitcount 10 -j DROP
ipt -A SSH_LIMIT -m recent --name SSH_FAIL --set -j ACCEPT

ipt -A INPUT -p tcp --dport "$SSH_PORT" -m conntrack --ctstate NEW \
    -j SSH_LIMIT

# ---------------------------------------------------------------------------
# Web
# ---------------------------------------------------------------------------
ipt -A INPUT -p tcp --dport 80  -m conntrack --ctstate NEW \
    -m limit --limit 200/second --limit-burst 500 -j ACCEPT
ipt -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW \
    -m limit --limit 200/second --limit-burst 500 -j ACCEPT

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
ipt -A INPUT -p tcp --dport 9100 -s "$MGMT_CIDR" -j ACCEPT  # node_exporter

# ---------------------------------------------------------------------------
# Log and drop everything else
# ---------------------------------------------------------------------------
ipt -A INPUT -m limit --limit 10/minute --limit-burst 30 \
    -j LOG --log-prefix "[ipt] DROP: " --log-level 6
ipt -A INPUT -j DROP

# ---------------------------------------------------------------------------
# Save rules
# ---------------------------------------------------------------------------
if (( ! DRY_RUN )); then
  if command -v netfilter-persistent &>/dev/null; then
    netfilter-persistent save
    log "Rules saved via netfilter-persistent"
  elif command -v iptables-save &>/dev/null; then
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4
    log "Rules saved to /etc/iptables/rules.v4"
    log "To restore at boot: apt install iptables-persistent"
  fi
fi

log "iptables rules applied:"
iptables -L -n -v --line-numbers | head -60

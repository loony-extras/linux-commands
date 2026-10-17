#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — certbot deploy hook: reload services after a renewal
# =============================================================================
# Install:  sudo install -m 755 deploy-hook.sh /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh
# Test:     sudo certbot renew --dry-run --run-deploy-hooks
#
# certbot runs it once per renewed certificate with:
#   RENEWED_LINEAGE  /etc/letsencrypt/live/<cert-name>
#   RENEWED_DOMAINS  space-separated domains in the certificate
#
# For each service in $SERVICES that is running, the config is tested first and
# the service is reloaded only if the test passes. HAProxy needs cert + key in one
# file, so a combined PEM is written to $HAPROXY_CERT_DIR/<cert-name>.pem.
#
# Environment (optional):
#   SERVICES          default: "nginx apache2 haproxy postfix dovecot"
#   HAPROXY_CERT_DIR  default: /etc/haproxy/certs
#   HOOK_DRY_RUN=1    print actions instead of running them
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SERVICES="${SERVICES:-nginx apache2 haproxy postfix dovecot}"
HAPROXY_CERT_DIR="${HAPROXY_CERT_DIR:-/etc/haproxy/certs}"
HOOK_DRY_RUN="${HOOK_DRY_RUN:-0}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() {
  echo "deploy-hook: $*"
  command -v logger &>/dev/null && logger -t certbot-deploy-hook -- "$*" || true
}
run() { if [[ "$HOOK_DRY_RUN" == 1 ]]; then echo "  [dry-run] $*"; else "$@"; fi; }

is_active() { systemctl is-active --quiet "$1" 2>/dev/null; }

# Config test command per service (empty = no test available)
config_test() {
  case "$1" in
    nginx)   nginx -t -q ;;
    apache2) apache2ctl configtest ;;
    haproxy) haproxy -c -q -f /etc/haproxy/haproxy.cfg ;;
    postfix) postfix check ;;
    dovecot) doveconf -n >/dev/null ;;
    *)       true ;;
  esac
}

write_haproxy_pem() {
  local name pem
  name=$(basename "$RENEWED_LINEAGE")
  pem="$HAPROXY_CERT_DIR/$name.pem"
  run install -d -m 700 "$HAPROXY_CERT_DIR"
  if [[ "$HOOK_DRY_RUN" == 1 ]]; then
    echo "  [dry-run] cat fullchain.pem privkey.pem > $pem"
  else
    ( umask 077; cat "$RENEWED_LINEAGE/fullchain.pem" "$RENEWED_LINEAGE/privkey.pem" > "$pem.tmp" )
    mv "$pem.tmp" "$pem"
  fi
  log "Wrote combined PEM $pem"
}

# ---------------------------------------------------------------------------
main() {
  [[ -n "${RENEWED_LINEAGE:-}" ]] || { echo "RENEWED_LINEAGE not set: run this from certbot" >&2; exit 1; }
  log "Renewed $(basename "$RENEWED_LINEAGE") (${RENEWED_DOMAINS:-?})"

  local svc failed=0
  for svc in $SERVICES; do
    is_active "$svc" || continue
    [[ "$svc" == haproxy ]] && write_haproxy_pem
    if [[ "$HOOK_DRY_RUN" == 1 ]] || config_test "$svc"; then
      run systemctl reload "$svc"
      [[ "$HOOK_DRY_RUN" == 1 ]] || log "Reloaded $svc"
    else
      log "NOT reloading $svc: config test failed (still serving the old certificate)"
      failed=1
    fi
  done
  exit "$failed"
}

main "$@"

#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — TLS certificate expiry check
# =============================================================================
# Checks remote endpoints and/or local certificate files and reports days left.
# Let's Encrypt stopped sending expiry emails in 2025: run this from cron or a
# systemd timer so a broken renewal gets noticed.
#
# Usage: bash cert-expiry-check.sh [options] TARGET...
#
# TARGET:
#   example.com            Remote, port 443 (SNI = host)
#   mail.example.com:465   Remote, custom port
#   /path/cert.pem         Local PEM file (first certificate is checked)
#   /etc/letsencrypt/live  Directory: checks every */fullchain.pem below it
#
# Options:
#   --warn N        Warn when fewer than N days remain (default: 21)
#   --crit N        Critical when fewer than N days remain (default: 7)
#   --webhook URL   POST a JSON message ({"text": ...}) when anything is not OK
#   --quiet         Print only problems
#
# Exit status: 0 all OK, 1 warning, 2 critical or unreachable (Nagios-style).
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
WARN_DAYS=21
CRIT_DAYS=7
WEBHOOK=""
QUIET=false
TIMEOUT=10
TARGETS=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() { sed -n '/^# Usage:/,/^# Exit status/p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

RED='\033[0;31m' YELLOW='\033[1;33m' GREEN='\033[0;32m' NC='\033[0m'
[[ -t 1 ]] || RED='' YELLOW='' GREEN='' NC=''

WORST=0
PROBLEMS=()

# report STATUS DAYS TARGET DETAIL
report() {
  local status="$1" days="$2" target="$3" detail="$4" color code
  case "$status" in
    OK)   color=$GREEN;  code=0 ;;
    WARN) color=$YELLOW; code=1 ;;
    *)    color=$RED;    code=2 ;;
  esac
  (( code > WORST )) && WORST=$code
  (( code > 0 )) && PROBLEMS+=("$status $target: $detail")
  if [[ "$QUIET" == false || $code -gt 0 ]]; then
    printf "${color}%-5s${NC} %6s  %-40s %s\n" "$status" "$days" "$target" "$detail"
  fi
}

# Classify an enddate string ("Jan 2 00:00:00 2027 GMT") for TARGET
classify() {
  local target="$1" enddate="$2" extra="${3:-}" end_ts days
  end_ts=$(date -d "$enddate" +%s 2>/dev/null) || { report CRIT "?" "$target" "Unparseable date: $enddate"; return; }
  days=$(( (end_ts - $(date +%s)) / 86400 ))
  local detail="expires $(date -d "$enddate" +%F)${extra:+  $extra}"
  if (( end_ts <= $(date +%s) )); then report CRIT "$days" "$target" "EXPIRED $(date -d "$enddate" +%F)"
  elif (( days < CRIT_DAYS ));    then report CRIT "$days" "$target" "$detail"
  elif (( days < WARN_DAYS ));    then report WARN "$days" "$target" "$detail"
  else                                 report OK   "$days" "$target" "$detail"
  fi
}

# ---------------------------------------------------------------------------
check_file() {
  local file="$1" enddate issuer
  if ! enddate=$(openssl x509 -in "$file" -noout -enddate 2>/dev/null); then
    report CRIT "?" "$file" "Not readable or not a certificate"; return
  fi
  issuer=$(openssl x509 -in "$file" -noout -issuer -nameopt multiline 2>/dev/null \
           | sed -n 's/^ *organizationName *= *//p' | head -1)
  classify "$file" "${enddate#notAfter=}" "${issuer:+[$issuer]}"
}

check_remote() {
  local target="$1" host port out enddate verify
  host="${target%:*}"; port="${target##*:}"
  [[ "$host" == "$target" ]] && port=443
  out=$(timeout "$TIMEOUT" openssl s_client -connect "$host:$port" -servername "$host" \
          -verify_hostname "$host" </dev/null 2>/dev/null) || true
  if ! enddate=$(openssl x509 -noout -enddate 2>/dev/null <<<"$out"); then
    report CRIT "?" "$target" "No certificate (unreachable, timeout or not TLS)"; return
  fi
  verify=$(sed -n 's/^ *Verify return code: //p' <<<"$out" | tail -1)
  # 10 = certificate has expired: report it as EXPIRED via classify, not as a chain error
  if [[ -n "$verify" && "$verify" != 0* && "$verify" != "10 "* ]]; then
    report CRIT "-" "$target" "Verification failed: $verify"; return
  fi
  classify "$target" "${enddate#notAfter=}"
}

notify() {
  [[ -n "$WEBHOOK" && ${#PROBLEMS[@]} -gt 0 ]] || return 0
  local text
  text="Certificate check on $(hostname): $(printf '%s; ' "${PROBLEMS[@]}")"
  curl -fsS --max-time 15 -X POST -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg t "$text" '{text: $t}')" "$WEBHOOK" >/dev/null \
    || echo "[!] Webhook delivery failed" >&2
}

# ---------------------------------------------------------------------------
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --warn)    WARN_DAYS="${2:?}"; shift ;;
      --crit)    CRIT_DAYS="${2:?}"; shift ;;
      --webhook) WEBHOOK="${2:?}"; shift ;;
      --quiet)   QUIET=true ;;
      -h|--help) usage 0 ;;
      -*)        echo "Unknown option: $1" >&2; usage 2 ;;
      *)         TARGETS+=("$1") ;;
    esac
    shift
  done
  [[ ${#TARGETS[@]} -gt 0 ]] || usage 2
  command -v openssl &>/dev/null || { echo "Missing: openssl" >&2; exit 2; }
  [[ -z "$WEBHOOK" ]] || command -v jq &>/dev/null || { echo "Missing: jq (needed for --webhook)" >&2; exit 2; }

  local t f
  for t in "${TARGETS[@]}"; do
    if [[ -d "$t" ]]; then
      while IFS= read -r f; do check_file "$f"; done < <(find "$t" -name fullchain.pem | sort)
    elif [[ -e "$t" || "$t" == /* || "$t" == ./* ]]; then
      check_file "$t"
    else
      check_remote "$t"
    fi
  done

  notify
  exit "$WORST"
}

main "$@"

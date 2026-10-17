#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Cloudflare Dynamic DNS
# =============================================================================
# Keeps an A (and optionally AAAA) record pointed at this host's public IP.
# Creates the record if it does not exist; does nothing if it is already current.
#
# Usage: CF_API_TOKEN=... CF_ZONE=example.com CF_RECORD=home.example.com bash cf-ddns.sh
#
# Environment (or put these in /etc/cf-ddns.env for the systemd timer):
#   CF_API_TOKEN       API token with Zone:DNS:Edit + Zone:Zone:Read on the zone
#   CF_API_TOKEN_FILE  Alternative: path to a file containing the token
#   CF_ZONE            Zone name, e.g. example.com
#   CF_RECORD          Full record name, e.g. home.example.com
#   CF_PROXIED         true|false — orange cloud (default: false)
#   CF_TTL             Seconds, or 1 for automatic (default: 1)
#   CF_IPV4            true|false — manage the A record (default: true)
#   CF_IPV6            true|false — manage the AAAA record (default: false)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
API="https://api.cloudflare.com/client/v4"
TRACE_URL="https://cloudflare.com/cdn-cgi/trace"

CF_ZONE="${CF_ZONE:-}"
CF_RECORD="${CF_RECORD:-}"
CF_PROXIED="${CF_PROXIED:-false}"
CF_TTL="${CF_TTL:-1}"
CF_IPV4="${CF_IPV4:-true}"
CF_IPV6="${CF_IPV6:-false}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
ts()    { date +'%Y-%m-%d %H:%M:%S'; }
log()   { echo "$(ts) $*"; }
error() { echo "$(ts) [ERROR] $*" >&2; exit 1; }

# Call the API; fail with Cloudflare's error message when success != true
cf() {
  local out
  out=$(curl -sS --max-time 20 \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" "$@") || error "Request to the Cloudflare API failed"
  if [[ "$(jq -r '.success' <<<"$out")" != "true" ]]; then
    error "API error: $(jq -c '.errors' <<<"$out")"
  fi
  echo "$out"
}

# Public IP as seen by Cloudflare (4 or 6)
public_ip() {
  curl -sS --max-time 10 -"$1" "$TRACE_URL" 2>/dev/null | sed -n 's/^ip=//p'
}

# ---------------------------------------------------------------------------
check_config() {
  for cmd in curl jq; do
    command -v "$cmd" &>/dev/null || error "Missing: $cmd"
  done
  if [[ -z "${CF_API_TOKEN:-}" && -n "${CF_API_TOKEN_FILE:-}" ]]; then
    [[ -r "$CF_API_TOKEN_FILE" ]] || error "Cannot read CF_API_TOKEN_FILE: $CF_API_TOKEN_FILE"
    CF_API_TOKEN=$(<"$CF_API_TOKEN_FILE")
  fi
  [[ -n "${CF_API_TOKEN:-}" ]] || error "Set CF_API_TOKEN or CF_API_TOKEN_FILE"
  [[ -n "$CF_ZONE" ]]          || error "Set CF_ZONE (e.g. example.com)"
  [[ -n "$CF_RECORD" ]]        || error "Set CF_RECORD (e.g. home.example.com)"
  [[ "$CF_PROXIED" == true || "$CF_PROXIED" == false ]] || error "CF_PROXIED must be true or false"
  [[ "$CF_TTL" =~ ^[0-9]+$ ]]  || error "CF_TTL must be a number"
  [[ "$CF_IPV4" == true || "$CF_IPV6" == true ]] || error "Both CF_IPV4 and CF_IPV6 are false — nothing to do"
}

# ---------------------------------------------------------------------------
# Create or update one record type (A or AAAA) for the given IP
# ---------------------------------------------------------------------------
sync_record() {
  local zone_id="$1" type="$2" ip="$3"
  local body existing rec_id current

  body=$(jq -nc --arg t "$type" --arg n "$CF_RECORD" --arg c "$ip" \
    --argjson p "$CF_PROXIED" --argjson ttl "$CF_TTL" \
    '{type: $t, name: $n, content: $c, proxied: $p, ttl: $ttl}')

  existing=$(cf "$API/zones/$zone_id/dns_records?type=$type&name=$CF_RECORD")
  rec_id=$(jq -r '.result[0].id // empty' <<<"$existing")
  current=$(jq -r '.result[0].content // empty' <<<"$existing")

  if [[ -z "$rec_id" ]]; then
    cf -X POST "$API/zones/$zone_id/dns_records" --data "$body" >/dev/null
    log "Created $type $CF_RECORD → $ip"
  elif [[ "$current" == "$ip" ]]; then
    log "$type $CF_RECORD already $ip — no change"
  else
    cf -X PATCH "$API/zones/$zone_id/dns_records/$rec_id" --data "$body" >/dev/null
    log "Updated $type $CF_RECORD: $current → $ip"
  fi
}

# ---------------------------------------------------------------------------
main() {
  check_config

  local zone_id
  zone_id=$(cf "$API/zones?name=$CF_ZONE" | jq -r '.result[0].id // empty')
  [[ -n "$zone_id" ]] || error "Zone not found (or token lacks Zone:Read): $CF_ZONE"

  local ip
  if [[ "$CF_IPV4" == true ]]; then
    ip=$(public_ip 4)
    [[ -n "$ip" ]] || error "Could not determine public IPv4"
    sync_record "$zone_id" A "$ip"
  fi
  if [[ "$CF_IPV6" == true ]]; then
    ip=$(public_ip 6)
    [[ -n "$ip" ]] || error "Could not determine public IPv6 (no IPv6 route?)"
    sync_record "$zone_id" AAAA "$ip"
  fi
}

main "$@"

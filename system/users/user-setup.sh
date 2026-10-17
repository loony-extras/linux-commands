#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — User Management Script
# =============================================================================
# Provides functions for creating, auditing, and managing users.
# Designed to be sourced or run standalone.
#
# Usage:
#   sudo bash user-setup.sh --action create --username john [--groups docker,sudo]
#   sudo bash user-setup.sh --action audit
#   sudo bash user-setup.sh --action rotate-keys --username john
#   sudo bash user-setup.sh --action lock --username john
#   sudo bash user-setup.sh --action report
# =============================================================================

set -euo pipefail

ACTION=""
USERNAME=""
GROUPS=""
KEY_FILE=""
LOG_FILE="/var/log/user-management.log"

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[ERROR] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "Must run as root"

while [[ $# -gt 0 ]]; do
  case $1 in
    --action)   ACTION="$2"; shift 2 ;;
    --username) USERNAME="$2"; shift 2 ;;
    --groups)   GROUPS="$2"; shift 2 ;;
    --key-file) KEY_FILE="$2"; shift 2 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

# ---------------------------------------------------------------------------
# ACTION: create — create a new user with best-practice settings
# ---------------------------------------------------------------------------
action_create() {
  [[ -n "$USERNAME" ]] || error "Provide --username"

  # Validate username
  [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || \
    error "Invalid username (lowercase letters, numbers, _, - only)"

  if id "$USERNAME" &>/dev/null; then
    log "User '$USERNAME' already exists — checking group membership"
  else
    # Generate a strong random password — user must change on first login
    local temp_pass
    temp_pass=$(openssl rand -base64 18 | tr -d '/+=' | head -c 20)

    useradd \
      -m \
      -s /bin/bash \
      -c "Created by user-setup.sh on $(date +%Y-%m-%d)" \
      "$USERNAME"

    echo "${USERNAME}:${temp_pass}" | chpasswd
    chage -d 0 "$USERNAME"    # Force password change on first login

    log "Created user: $USERNAME (temp password logged to $LOG_FILE)"
    echo "Temp password for $USERNAME: $temp_pass" >> "$LOG_FILE"
    chmod 600 "$LOG_FILE"
  fi

  # Set password aging policy
  chage -M 90 -m 7 -W 14 -I 30 "$USERNAME"

  # Group membership
  if [[ -n "$GROUPS" ]]; then
    IFS=',' read -ra group_list <<< "$GROUPS"
    for grp in "${group_list[@]}"; do
      if getent group "$grp" &>/dev/null; then
        usermod -aG "$grp" "$USERNAME"
        log "Added $USERNAME to group: $grp"
      else
        log "WARNING: Group '$grp' does not exist — skipping"
      fi
    done
  fi

  # SSH directory
  local home
  home=$(getent passwd "$USERNAME" | cut -d: -f6)
  mkdir -p "$home/.ssh"
  chmod 700 "$home/.ssh"
  touch "$home/.ssh/authorized_keys"
  chmod 600 "$home/.ssh/authorized_keys"
  chown -R "$USERNAME:$USERNAME" "$home/.ssh"

  # Install SSH public key if provided
  if [[ -n "$KEY_FILE" ]]; then
    action_add_key
  fi

  log "User '$USERNAME' setup complete"
  log "Groups: $(id -nG "$USERNAME")"
  log "Password aging: $(chage -l "$USERNAME" | grep 'Maximum\|Minimum\|Warning')"
}

# ---------------------------------------------------------------------------
# ACTION: add-key — add an SSH public key to a user
# ---------------------------------------------------------------------------
action_add_key() {
  [[ -n "$USERNAME" ]] || error "Provide --username"
  [[ -n "$KEY_FILE" ]] || error "Provide --key-file /path/to/key.pub"
  [[ -f "$KEY_FILE" ]] || error "Key file not found: $KEY_FILE"

  local home
  home=$(getent passwd "$USERNAME" | cut -d: -f6)
  local auth_keys="$home/.ssh/authorized_keys"

  local key
  key=$(cat "$KEY_FILE")

  # Validate key format
  echo "$key" | ssh-keygen -l -f /dev/stdin &>/dev/null || \
    error "Invalid SSH public key format in $KEY_FILE"

  # Check if key already exists
  if grep -qF "$key" "$auth_keys" 2>/dev/null; then
    log "Key already in authorized_keys for $USERNAME — skipping"
    return
  fi

  echo "$key" >> "$auth_keys"
  chown "$USERNAME:$USERNAME" "$auth_keys"
  log "Added SSH key to $USERNAME's authorized_keys"
}

# ---------------------------------------------------------------------------
# ACTION: rotate-keys — remove all keys and force re-registration
# ---------------------------------------------------------------------------
action_rotate_keys() {
  [[ -n "$USERNAME" ]] || error "Provide --username"

  local home
  home=$(getent passwd "$USERNAME" | cut -d: -f6)
  local auth_keys="$home/.ssh/authorized_keys"

  local key_count
  key_count=$(grep -c "ssh-" "$auth_keys" 2>/dev/null || echo 0)

  # Back up existing keys before rotation
  if [[ -s "$auth_keys" ]]; then
    local backup="$home/.ssh/authorized_keys.backup.$(date +%Y%m%d%H%M%S)"
    cp "$auth_keys" "$backup"
    log "Backed up existing keys to: $backup"
  fi

  > "$auth_keys"   # Truncate
  chown "$USERNAME:$USERNAME" "$auth_keys"
  log "Rotated SSH keys for $USERNAME ($key_count keys removed)"
  log "User must provide a new public key to regain SSH access"
}

# ---------------------------------------------------------------------------
# ACTION: lock — lock user account
# ---------------------------------------------------------------------------
action_lock() {
  [[ -n "$USERNAME" ]] || error "Provide --username"
  usermod -L "$USERNAME"
  # Also invalidate any SSH keys (move them aside)
  local home
  home=$(getent passwd "$USERNAME" | cut -d: -f6)
  if [[ -f "$home/.ssh/authorized_keys" ]]; then
    mv "$home/.ssh/authorized_keys" "$home/.ssh/authorized_keys.locked"
  fi
  log "Account LOCKED: $USERNAME"
}

# ---------------------------------------------------------------------------
# ACTION: unlock — unlock a locked account
# ---------------------------------------------------------------------------
action_unlock() {
  [[ -n "$USERNAME" ]] || error "Provide --username"
  usermod -U "$USERNAME"
  local home
  home=$(getent passwd "$USERNAME" | cut -d: -f6)
  if [[ -f "$home/.ssh/authorized_keys.locked" ]]; then
    mv "$home/.ssh/authorized_keys.locked" "$home/.ssh/authorized_keys"
  fi
  log "Account UNLOCKED: $USERNAME"
}

# ---------------------------------------------------------------------------
# ACTION: audit — security audit of all accounts
# ---------------------------------------------------------------------------
action_audit() {
  echo "==================================================================="
  echo " USER SECURITY AUDIT: $(hostname) @ $(date)"
  echo "==================================================================="

  echo ""
  echo "--- Accounts with UID 0 (root-equivalent) ---"
  awk -F: '$3 == 0 {print $1}' /etc/passwd | while read -r user; do
    echo "  ALERT: $user has UID 0"
  done

  echo ""
  echo "--- Accounts with empty passwords ---"
  awk -F: '($2 == "" || $2 == "!!" ) {print $1}' /etc/shadow 2>/dev/null | \
    while read -r user; do echo "  WARN: $user has empty/locked password"; done

  echo ""
  echo "--- Accounts that have never logged in ---"
  lastlog | awk 'NR>1 && /Never logged in/ {print "  No login: "$1}'

  echo ""
  echo "--- Users with sudo access ---"
  grep -E "^[^#].*ALL=\(ALL" /etc/sudoers 2>/dev/null || true
  ls /etc/sudoers.d/ 2>/dev/null | while read -r f; do
    echo "  sudoers.d/$f:"; grep -v "^#" "/etc/sudoers.d/$f" 2>/dev/null | grep ALL || true
  done

  echo ""
  echo "--- Password expiry status (regular users) ---"
  awk -F: '$3 >= 1000 && $7 !~ /nologin|false/ {print $1}' /etc/passwd | \
    while read -r user; do
      local max_days
      max_days=$(chage -l "$user" 2>/dev/null | awk '/Maximum number/{print $NF}')
      echo "  $user: max_days=${max_days}"
    done

  echo ""
  echo "--- Users currently logged in ---"
  who -u

  echo ""
  echo "--- SSH authorized_keys summary ---"
  awk -F: '$3 >= 1000 {print $1, $6}' /etc/passwd | \
    while read -r user home; do
      local keyfile="$home/.ssh/authorized_keys"
      if [[ -f "$keyfile" ]]; then
        local count
        count=$(grep -c "ssh-" "$keyfile" 2>/dev/null || echo 0)
        echo "  $user: $count authorized key(s)"
        # Check key types — flag weak keys
        if grep -q "ssh-dss\|ssh-rsa " "$keyfile" 2>/dev/null; then
          echo "    WARNING: $user has DSA or RSA (potentially weak) keys"
        fi
      else
        echo "  $user: no authorized_keys file"
      fi
    done

  echo ""
  echo "--- Recent failed logins (last 50) ---"
  lastb | head -50 2>/dev/null || grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20

  echo ""
  echo "--- Accounts with login shells but no home directory ---"
  awk -F: '$7 !~ /nologin|false|sync/ && $6 {if (system("test -d "$6) != 0) print $1, $6}' \
    /etc/passwd 2>/dev/null

  echo "==================================================================="
}

# ---------------------------------------------------------------------------
# ACTION: report — brief per-user status table
# ---------------------------------------------------------------------------
action_report() {
  printf "%-20s %-8s %-20s %-10s %-8s\n" "USERNAME" "UID" "LAST_LOGIN" "PASS_AGE" "STATUS"
  printf "%-20s %-8s %-20s %-10s %-8s\n" "--------" "---" "----------" "--------" "------"

  awk -F: '$3 >= 1000 && $7 !~ /nologin|false/ {print $1, $3}' /etc/passwd | \
  while read -r user uid; do
    local last_login
    last_login=$(lastlog -u "$user" 2>/dev/null | awk 'NR>1 {if ($4=="**Never") print "Never"; else print $4,$5,$6,$9}')

    local max_days
    max_days=$(chage -l "$user" 2>/dev/null | awk '/Maximum number/{print $NF}')

    local status
    if passwd -S "$user" 2>/dev/null | grep -q " L "; then
      status="LOCKED"
    elif passwd -S "$user" 2>/dev/null | grep -q " NP "; then
      status="NO_PASS"
    else
      status="active"
    fi

    printf "%-20s %-8s %-20s %-10s %-8s\n" "$user" "$uid" "${last_login:-unknown}" "${max_days}d" "$status"
  done
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "${ACTION}" in
  create)        action_create ;;
  add-key)       action_add_key ;;
  rotate-keys)   action_rotate_keys ;;
  lock)          action_lock ;;
  unlock)        action_unlock ;;
  audit)         action_audit ;;
  report)        action_report ;;
  "")            error "Provide --action: create|add-key|rotate-keys|lock|unlock|audit|report" ;;
  *)             error "Unknown action: $ACTION" ;;
esac

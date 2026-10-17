#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — LVM Setup Script
# =============================================================================
# Creates a production-grade LVM layout on a raw partition.
# Run AFTER disk-setup.sh.
#
# Usage:
#   sudo bash lvm-setup.sh --pv /dev/sdb3 --vg vg_system --profile server
#
# Profiles:
#   server  — standard web/app server layout
#   db      — database-optimized (larger /var)
#   desktop — desktop layout (larger /home)
# =============================================================================

set -euo pipefail

PV_DEVICE=""
VG_NAME="vg_system"
PROFILE="server"
LOG_FILE="/var/log/lvm-setup.log"

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[ERROR] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "Must run as root"

while [[ $# -gt 0 ]]; do
  case $1 in
    --pv)       PV_DEVICE="$2"; shift 2 ;;
    --vg)       VG_NAME="$2"; shift 2 ;;
    --profile)  PROFILE="$2"; shift 2 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

[[ -n "$PV_DEVICE" ]] || error "Usage: $0 --pv /dev/sdX3 [--vg vg_name] [--profile server|db|desktop]"
[[ -b "$PV_DEVICE" ]] || error "Not a block device: $PV_DEVICE"

# ---------------------------------------------------------------------------
# Total disk space calculation
# ---------------------------------------------------------------------------
TOTAL_MB=$(lsblk -b --output SIZE -n "$PV_DEVICE" | awk '{printf "%d", $1/1024/1024}')
log "Physical volume: $PV_DEVICE ($TOTAL_MB MB available)"

# ---------------------------------------------------------------------------
# Define layouts per profile
# ---------------------------------------------------------------------------
declare_server_layout() {
  ROOT_SIZE="30G"
  HOME_SIZE="10G"
  VAR_SIZE="15G"
  VAR_LOG_SIZE="8G"
  TMP_SIZE="4G"
  SWAP_SIZE="$(awk '/MemTotal/{printf "%dG", int($2/1024/1024)+1}' /proc/meminfo)"
  DATA_SIZE="0"       # 0 = use remaining
}

declare_db_layout() {
  ROOT_SIZE="20G"
  HOME_SIZE="5G"
  VAR_SIZE="40G"       # Larger for DB WAL and temp files
  VAR_LOG_SIZE="10G"
  TMP_SIZE="4G"
  SWAP_SIZE="$(awk '/MemTotal/{printf "%dG", int($2/1024/1024)+1}' /proc/meminfo)"
  DATA_SIZE="0"        # All remaining for /data (database files)
}

declare_desktop_layout() {
  ROOT_SIZE="25G"
  HOME_SIZE="0"        # All remaining for /home
  VAR_SIZE="10G"
  VAR_LOG_SIZE="5G"
  TMP_SIZE="4G"
  SWAP_SIZE="8G"
  DATA_SIZE="0"
}

case "$PROFILE" in
  server)   declare_server_layout ;;
  db)       declare_db_layout ;;
  desktop)  declare_desktop_layout ;;
  *) error "Unknown profile: $PROFILE. Use: server, db, desktop" ;;
esac

log "Profile: $PROFILE"

# ---------------------------------------------------------------------------
# Create Physical Volume
# ---------------------------------------------------------------------------
log "Initializing physical volume: $PV_DEVICE"
pvcreate -ff -y "$PV_DEVICE"
pvdisplay "$PV_DEVICE"

# ---------------------------------------------------------------------------
# Create Volume Group
# ---------------------------------------------------------------------------
log "Creating volume group: $VG_NAME"
vgcreate "$VG_NAME" "$PV_DEVICE"

# ---------------------------------------------------------------------------
# Create Logical Volumes
# ---------------------------------------------------------------------------
create_lv() {
  local name="$1" size="$2" vg="$3"
  if [[ "$size" == "0" ]]; then
    log "Creating LV $name (all remaining space)"
    lvcreate -l 100%FREE -n "$name" "$vg"
  else
    log "Creating LV $name ($size)"
    lvcreate -L "$size" -n "$name" "$vg"
  fi
}

create_lv lv_root    "$ROOT_SIZE"    "$VG_NAME"
create_lv lv_var     "$VAR_SIZE"     "$VG_NAME"
create_lv lv_var_log "$VAR_LOG_SIZE" "$VG_NAME"
create_lv lv_tmp     "$TMP_SIZE"     "$VG_NAME"
create_lv lv_swap    "$SWAP_SIZE"    "$VG_NAME"

if [[ "$PROFILE" == "db" ]]; then
  create_lv lv_data 0 "$VG_NAME"   # All remaining space for DB data
elif [[ "$PROFILE" == "desktop" ]]; then
  create_lv lv_home 0 "$VG_NAME"
elif [[ "$HOME_SIZE" != "0" ]]; then
  create_lv lv_home "$HOME_SIZE" "$VG_NAME"
fi

# ---------------------------------------------------------------------------
# Format Logical Volumes
# ---------------------------------------------------------------------------
log "Formatting logical volumes"

format_ext4() {
  local lv="$1" label="$2"
  mkfs.ext4 -q -L "$label" "/dev/${VG_NAME}/${lv}"
  log "  $lv → ext4 (label: $label)"
}

format_ext4 lv_root    root
format_ext4 lv_var     var
format_ext4 lv_var_log var_log
format_ext4 lv_tmp     tmp

# XFS for data volume (better for large files, databases)
if lvs "${VG_NAME}/lv_data" &>/dev/null; then
  mkfs.xfs -L data "/dev/${VG_NAME}/lv_data"
  log "  lv_data → xfs (label: data)"
fi

if lvs "${VG_NAME}/lv_home" &>/dev/null; then
  format_ext4 lv_home home
fi

# Swap
mkswap -L swap "/dev/${VG_NAME}/lv_swap"
log "  lv_swap → swap"

# ---------------------------------------------------------------------------
# Generate fstab entries
# ---------------------------------------------------------------------------
FSTAB_OUTPUT="/root/fstab-lvm-entries.txt"
log "Generating fstab entries → $FSTAB_OUTPUT"

cat > "$FSTAB_OUTPUT" << EOF
# Generated by lvm-setup.sh — append to /etc/fstab
# Profile: $PROFILE | $(date)

/dev/${VG_NAME}/lv_root     /           ext4  defaults,noatime,errors=remount-ro  0  1
/dev/${VG_NAME}/lv_var      /var        ext4  defaults,noatime,nodev               0  2
/dev/${VG_NAME}/lv_var_log  /var/log    ext4  defaults,noatime,nodev               0  2
/dev/${VG_NAME}/lv_tmp      /tmp        ext4  defaults,noatime,nodev,nosuid,noexec 0  2
/dev/${VG_NAME}/lv_swap     none        swap  sw                                    0  0
EOF

if lvs "${VG_NAME}/lv_home" &>/dev/null; then
  echo "/dev/${VG_NAME}/lv_home     /home       ext4  defaults,noatime,nodev               0  2" \
    >> "$FSTAB_OUTPUT"
fi
if lvs "${VG_NAME}/lv_data" &>/dev/null; then
  echo "/dev/${VG_NAME}/lv_data     /data       xfs   defaults,noatime,nodev               0  2" \
    >> "$FSTAB_OUTPUT"
fi

cat "$FSTAB_OUTPUT"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
log "=== LVM Layout Summary ==="
vgdisplay "$VG_NAME" | grep -E "VG Name|VG Size|Alloc|Free"
lvs "$VG_NAME"
echo ""
log "LVM setup complete."
log "Next steps:"
echo "  1. Mount the volumes manually or reboot with the new fstab"
echo "  2. Append $FSTAB_OUTPUT to /etc/fstab"
echo "  3. Run: mount -a && swapon -a"

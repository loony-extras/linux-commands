#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Backup Script
# =============================================================================
# Supports: local, SSH/rsync, S3-compatible storage
# Strategy: daily full + incremental via rsync --link-dest (hardlink deltas)
#
# Usage: bash backup.sh --target /backup/dest [--remote user@host:/backup]
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BACKUP_ROOT="${BACKUP_ROOT:-/var/backup}"
REMOTE_DEST="${REMOTE_DEST:-}"        # user@host:/path — optional
S3_BUCKET="${S3_BUCKET:-}"           # s3://bucket/path — optional
RETENTION_DAYS="${RETENTION_DAYS:-30}"
LOG_FILE="/var/log/backup.log"

# Directories to back up
INCLUDE_DIRS=(
  /etc
  /home
  /root
  /var/www
  /opt
  /srv
)

# Directories to exclude
EXCLUDE_PATTERNS=(
  "/proc"
  "/sys"
  "/dev"
  "/run"
  "/tmp"
  "/var/tmp"
  "/var/cache/apt"
  "/var/lib/docker/overlay2"
  "*.sock"
  "*.pid"
  "node_modules"
  ".git"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
ts()    { date +'%Y-%m-%d %H:%M:%S'; }
log()   { echo "$(ts) $*" | tee -a "$LOG_FILE"; }
error() { echo "$(ts) [ERROR] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

DATE=$(date +%Y%m%d)
TIME=$(date +%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"
LATEST_LINK="$BACKUP_ROOT/latest"

# Build rsync exclude args
EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  EXCLUDE_ARGS+=(--exclude="$pattern")
done

# ---------------------------------------------------------------------------
check_dependencies() {
  for cmd in rsync tar; do
    command -v "$cmd" &>/dev/null || error "Missing: $cmd"
  done
  if [[ -n "$S3_BUCKET" ]]; then
    command -v aws &>/dev/null || error "AWS CLI not found (needed for S3 backup)"
  fi
}

# ---------------------------------------------------------------------------
backup_filesystem() {
  log "Starting filesystem backup → $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"

  local rsync_opts=(
    -aAX                        # Archive, ACLs, extended attrs
    --numeric-ids               # Preserve UID/GID numbers
    --delete                    # Remove files deleted from source
    --delete-excluded
    --stats
    --no-whole-file
    "${EXCLUDE_ARGS[@]}"
  )

  # Incremental: if a previous backup exists, use it as --link-dest
  # This means unchanged files are hard-linked (no extra disk space)
  if [[ -d "$LATEST_LINK" ]]; then
    rsync_opts+=(--link-dest="$LATEST_LINK")
    log "Using incremental backup from: $(readlink -f "$LATEST_LINK")"
  fi

  for dir in "${INCLUDE_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      log "Backing up: $dir"
      rsync "${rsync_opts[@]}" "$dir/" "$BACKUP_DIR${dir}/" 2>&1 | tee -a "$LOG_FILE" || \
        log "WARNING: rsync had errors for $dir (non-zero exit)"
    else
      log "Skip (not found): $dir"
    fi
  done

  # Update the 'latest' symlink
  ln -sfn "$BACKUP_DIR" "$LATEST_LINK"
  log "Filesystem backup complete: $BACKUP_DIR"
}

# ---------------------------------------------------------------------------
backup_databases() {
  log "Starting database backups"
  local db_backup_dir="$BACKUP_DIR/databases"
  mkdir -p "$db_backup_dir"

  # PostgreSQL
  if command -v pg_dumpall &>/dev/null && systemctl is-active postgresql &>/dev/null; then
    log "Dumping PostgreSQL (all databases)"
    sudo -u postgres pg_dumpall --clean | \
      gzip -9 > "$db_backup_dir/postgresql_${DATE}.sql.gz"
    log "PostgreSQL dump: $db_backup_dir/postgresql_${DATE}.sql.gz"

    # Individual databases (faster restore)
    while IFS= read -r dbname; do
      [[ "$dbname" =~ ^(template|postgres)$ ]] && continue
      sudo -u postgres pg_dump --clean "$dbname" | \
        gzip -9 > "$db_backup_dir/pg_${dbname}_${DATE}.sql.gz"
    done < <(sudo -u postgres psql -tAc "SELECT datname FROM pg_database WHERE datistemplate=false")
  fi

  # MySQL / MariaDB
  if command -v mysqldump &>/dev/null && systemctl is-active mysql &>/dev/null; then
    log "Dumping MySQL (all databases)"
    mysqldump --all-databases --single-transaction --routines --triggers | \
      gzip -9 > "$db_backup_dir/mysql_${DATE}.sql.gz"
  fi

  # Redis RDB dump
  if command -v redis-cli &>/dev/null && systemctl is-active redis-server &>/dev/null; then
    log "Backing up Redis"
    redis-cli BGSAVE
    sleep 2
    local rdb_path
    rdb_path=$(redis-cli CONFIG GET dir | tail -1)/$(redis-cli CONFIG GET dbfilename | tail -1)
    cp "$rdb_path" "$db_backup_dir/redis_${DATE}.rdb" 2>/dev/null || true
  fi

  log "Database backups complete"
}

# ---------------------------------------------------------------------------
backup_configs() {
  log "Backing up critical config files"
  local cfg_archive="$BACKUP_DIR/system-configs-${DATE}.tar.gz"

  tar -czf "$cfg_archive" \
    --exclude='/etc/ssl/private' \
    /etc/ 2>&1 | tee -a "$LOG_FILE" || true

  log "Config archive: $cfg_archive"
}

# ---------------------------------------------------------------------------
encrypt_backup() {
  local target_dir="$1"
  local GPG_RECIPIENT="${GPG_RECIPIENT:-}"

  if [[ -z "$GPG_RECIPIENT" ]]; then
    log "GPG_RECIPIENT not set — skipping encryption"
    return
  fi

  log "Encrypting backups for: $GPG_RECIPIENT"
  find "$target_dir" -type f ! -name "*.gpg" | while read -r f; do
    gpg --batch --yes -e -r "$GPG_RECIPIENT" "$f"
    rm -f "$f"
  done
}

# ---------------------------------------------------------------------------
sync_to_remote() {
  if [[ -z "$REMOTE_DEST" ]]; then return; fi

  log "Syncing to remote: $REMOTE_DEST"
  rsync -az --delete \
    -e "ssh -o StrictHostKeyChecking=yes" \
    "$BACKUP_DIR/" "$REMOTE_DEST/$(hostname)/$DATE/" 2>&1 | tee -a "$LOG_FILE"
  log "Remote sync complete"
}

# ---------------------------------------------------------------------------
sync_to_s3() {
  if [[ -z "$S3_BUCKET" ]]; then return; fi

  log "Uploading to S3: $S3_BUCKET"
  aws s3 sync "$BACKUP_DIR/" "$S3_BUCKET/$(hostname)/$DATE/" \
    --storage-class STANDARD_IA \
    --sse AES256 \
    2>&1 | tee -a "$LOG_FILE"
  log "S3 upload complete"
}

# ---------------------------------------------------------------------------
cleanup_old_backups() {
  log "Cleaning up backups older than $RETENTION_DAYS days"
  find "$BACKUP_ROOT" -maxdepth 1 -type d -name "[0-9]*" \
    -mtime "+$RETENTION_DAYS" -exec rm -rf {} \; 2>/dev/null || true
  log "Cleanup complete"
}

# ---------------------------------------------------------------------------
verify_backup() {
  local size
  size=$(du -sh "$BACKUP_DIR" | cut -f1)
  log "Backup size: $size"

  # Verify a sample tar archive if present
  if [[ -f "$BACKUP_DIR/system-configs-${DATE}.tar.gz" ]]; then
    if tar -tzf "$BACKUP_DIR/system-configs-${DATE}.tar.gz" >/dev/null 2>&1; then
      log "Config archive integrity: OK"
    else
      error "Config archive is corrupted!"
    fi
  fi

  log "Backup verified: $BACKUP_DIR"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "=== Backup started: $(hostname) ==="

check_dependencies
backup_filesystem
backup_databases
backup_configs
verify_backup
sync_to_remote
sync_to_s3
cleanup_old_backups

log "=== Backup complete: $BACKUP_DIR ($( du -sh "$BACKUP_DIR" | cut -f1)) ==="

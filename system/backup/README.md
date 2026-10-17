# Backup

Incremental rsync and database backups on a systemd timer.

---

## Files

- [backup.service](backup.service)
- [backup.sh](backup.sh)
- [backup.timer](backup.timer)

---

## Usage

| File | Install to | Purpose |
|------|-----------|---------|
| `backup.sh` | `/usr/local/bin/backup.sh` | Incremental rsync (hardlink deltas), PostgreSQL/MySQL/Redis dumps, optional S3 and SSH sync, 30-day retention |
| `backup.service` | `/etc/systemd/system/` | Oneshot unit, IOSchedulingClass=idle, 4-hour timeout |
| `backup.timer` | `/etc/systemd/system/` | Daily at 02:00, RandomizedDelaySec=1800, Persistent=true |

```bash
# Environment variables:
BACKUP_ROOT=/var/backup          # Local backup destination
REMOTE_DEST=user@host:/backups   # SSH remote (optional)
S3_BUCKET=s3://mybucket/backups  # S3 destination (optional)
RETENTION_DAYS=30
GPG_RECIPIENT=admin@company.com  # Encrypt backups (optional)

# Install and enable the timer:
cp system/backup/backup.service system/backup/backup.timer /etc/systemd/system/
cp system/backup/backup.sh /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
systemctl daemon-reload
systemctl enable --now backup.timer
systemctl list-timers backup.timer   # verify
```

#!/usr/bin/env bash
# =============================================================================
# cron & at — annotated command examples
# Tier: 4 (Expert)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### Cron Jobs and Scheduling
# ---------------------------------------------------------------------------
## crontab syntax:
# ┌───── minute (0-59)
# │ ┌───── hour (0-23)
# │ │ ┌───── day of month (1-31)
# │ │ │ ┌───── month (1-12)
# │ │ │ │ ┌───── day of week (0=Sun, 7=Sun)
# │ │ │ │ │
# * * * * *  command

crontab -e                      # Edit current user's crontab
crontab -l                      # List current crontab
crontab -r                      # Remove crontab (careful!)
crontab -l -u www-data          # List another user's crontab (root only)
crontab -u www-data -e          # Edit another user's crontab

# Schedule examples (as crontab entries):
# 0 2 * * *      /backup/run.sh          # Daily at 2:00 AM
# */5 * * * *    /check/service.sh       # Every 5 minutes
# 0 */4 * * *    /refresh/cache.sh       # Every 4 hours
# 0 9 * * 1-5    /notify/standup.sh     # Weekdays at 9 AM
# 0 0 1 * *      /archive/monthly.sh    # 1st of each month at midnight
# 0 0 * * 0      /run/weekly.sh         # Every Sunday at midnight
# @reboot        /start/daemon.sh        # At system boot
# @daily         /cleanup/logs.sh        # Daily (alias for 0 0 * * *)
# @weekly        /run/weekly.sh          # Weekly (0 0 * * 0)
# @monthly       /archive/month.sh       # Monthly (0 0 1 * *)
# @hourly        /check/health.sh        # Hourly (0 * * * *)

# System cron directories (for root-level tasks)
ls /etc/cron.{hourly,daily,weekly,monthly}/  # Drop scripts here

# Run job and email output only on failure
# 0 2 * * * /backup.sh || echo "Backup failed" | mail -s "BACKUP FAIL" admin@co.com

## at — run once at a specific time
at 2:30 AM tomorrow            # Interactive: type commands, Ctrl+D to submit
at 14:30 < script.sh           # Run script non-interactively
at now + 5 minutes             # Relative time
at next week                   # Relative: next week
at midnight                    # Tonight at midnight
atq                            # List pending jobs
at -l                          # Same as atq
atrm 3                         # Remove job #3
at -c 3                        # Show job #3's commands

## systemd timers (modern cron alternative — see system/systemd/README.md)
systemctl list-timers          # Show all timers with next run time
systemctl start backup.timer   # Manually trigger timer

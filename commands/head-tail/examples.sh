#!/usr/bin/env bash
# =============================================================================
# head / tail — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### head / tail — View file beginnings/ends
# ---------------------------------------------------------------------------
head file.txt                   # First 10 lines (default)
head -n 20 file.txt             # First 20 lines
head -c 1024 file.txt           # First 1024 bytes
head -n -5 file.txt             # All lines EXCEPT last 5

tail file.txt                   # Last 10 lines
tail -n 20 file.txt             # Last 20 lines
tail -c 1024 file.txt           # Last 1024 bytes
tail -f file.txt                # Follow: print new lines as they appear
tail -F file.txt                # Follow by name: handles log rotation
tail -n +10 file.txt            # Start from line 10 (skip first 9)
tail -f /var/log/syslog | grep ERROR  # Live filtered log monitoring

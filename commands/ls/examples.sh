#!/usr/bin/env bash
# =============================================================================
# ls — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### ls — List directory contents
# ---------------------------------------------------------------------------
ls                              # Basic list
ls -l                           # Long format: perms, links, owner, group, size, date, name
ls -la                          # All files including hidden (dot-files)
ls -lh                          # Human-readable sizes (K, M, G)
ls -lt                          # Sort by modification time, newest first
ls -ltr                         # Sort by time, oldest first — best for log directories
ls -lS                          # Sort by file size, largest first
ls -lu                          # Sort by last access time
ls -lc                          # Sort by ctime (metadata change)
ls -R                           # Recursive — shows entire tree
ls -d */                        # List only directories in current path
ls -d /etc/*/                   # List subdirectories of /etc
ls -i                           # Show inode numbers
ls -n                           # Numeric UID/GID instead of names
ls -1                           # One entry per line (for scripts/pipes)
ls -F                           # Append type indicator: / = dir, * = exec, @ = link
ls -A                           # Almost-all: hidden files but not . and ..
ls --color=auto                 # Colorize output
ls --sort=size -lh              # Explicit sort: size, extension, version, time
ls -lhX                         # Sort by file extension
ls --time-style=full-iso -l     # ISO 8601 timestamps
ls -la /proc/1/fd/              # Open file descriptors for PID 1
ls -la /dev/disk/by-uuid/       # Disk devices by UUID

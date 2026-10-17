#!/usr/bin/env bash
# =============================================================================
# lsof — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### lsof — list open files (everything is a file in Linux)
# ---------------------------------------------------------------------------
lsof                                    # ALL open files (very long)
lsof -p 1234                            # Open files for PID
lsof -p 1234,5678                       # Multiple PIDs
lsof -u www-data                        # Files opened by user
lsof -i                                 # All network files/sockets
lsof -i :80                             # Processes using port 80
lsof -i :80 -i :443                     # Port 80 OR 443
lsof -i tcp                             # All TCP sockets
lsof -i tcp:22                          # TCP port 22 specifically
lsof -i @192.168.1.100                  # Connections to/from this IP
lsof -i 4                               # IPv4 only
lsof -i 6                               # IPv6 only
lsof +D /var/log                        # All files open under /var/log
lsof /var/log/syslog                    # Who has this file open
lsof -n                                 # No hostname resolution (faster)
lsof -P                                 # No port name resolution
lsof -nP                                # Both — fastest output
lsof -nP | grep LISTEN                  # Listening ports (like ss -tlnp)
lsof -nP | grep ESTABLISHED             # Established connections
lsof +L1                                # Deleted files still held open
                                        # (these hold disk space — find memory leaks)
lsof | awk '{print $1}' | sort | uniq -c | sort -rn | head -20  # Processes by open file count
lsof -a -u www-data -i                  # (-a = AND) user www-data AND network

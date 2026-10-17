#!/usr/bin/env bash
# =============================================================================
# Processes — annotated command examples
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### Process Management — ps, top, htop, nice, renice, kill
# ---------------------------------------------------------------------------
## ps — process snapshot
ps                              # Processes in current terminal
ps aux                          # All processes, user-oriented format
ps -ef                          # All processes, full format (PPID visible)
ps aux --sort=-%cpu             # Sort by CPU usage, highest first
ps aux --sort=-%mem             # Sort by memory usage
ps aux --sort=+pid              # Sort by PID ascending
ps -p 1234 -o pid,ppid,cmd,%cpu,%mem  # Specific PID, custom columns
ps -u www-data                  # Processes owned by user www-data
ps -C nginx                     # Processes named nginx
ps --ppid 1234                  # Child processes of PID 1234
ps -f --forest                  # Full format, process tree
ps -eLf                         # Show all threads (LWP column)
ps -o pid,ppid,pgid,sid,comm    # Process, parent, group, session, command
ps h -o pid --sort pid          # Just PIDs, sorted (for scripting)
# Key columns: PID, TTY, STAT (state), TIME, COMMAND
# STAT codes: R=running, S=sleeping, D=disk wait, Z=zombie, T=stopped

## top — interactive process monitor
top                             # Default view
top -b -n 1                     # Batch mode, single snapshot (for scripts)
top -b -n 5 -d 2                # 5 iterations, 2-second delay
top -p 1234,5678                # Monitor specific PIDs only
top -u www-data                 # Show only www-data's processes
top -H                          # Show individual threads
# Inside top (interactive keys):
# 1     = expand per-CPU stats
# P     = sort by CPU
# M     = sort by memory
# T     = sort by time
# k     = kill process (enter PID)
# r     = renice process
# q     = quit
# c     = toggle between command and full path
# V     = forest view
# l     = toggle load average line
# t     = cycle through CPU display styles
# m     = cycle through memory display styles
# f     = field management (add/remove columns)
# W     = save current settings to ~/.toprc

## htop — enhanced interactive monitor (apt install htop)
htop                            # Default (color, better UI than top)
htop -u www-data                # Filter by user
htop -p 1234,5678               # Specific PIDs
htop -d 20                      # Refresh delay in tenths of seconds
htop --sort-key=PERCENT_MEM     # Sort by memory

## nice — start process with adjusted priority
nice command                    # Default niceness: 10 (lower priority)
nice -n 10 make -j4             # Lower priority: +10 (range -20 to +19)
nice -n -5 ./critical-task      # Higher priority (negative, requires root)
nice -n 19 find / -name "*.log" # Lowest priority (barely uses CPU)

## renice — change priority of running process
renice -n 5 -p 1234             # Set niceness to 5 for PID 1234
renice -n 10 -u www-data        # Lower all www-data's processes
renice -n -5 -p 1234            # Higher priority (requires root)
renice +1 -p 1234               # Relative adjustment syntax (BSD compat)

## kill — send signals to processes
kill 1234                       # SIGTERM (15): request graceful shutdown
kill -15 1234                   # Same as above (explicit)
kill -9 1234                    # SIGKILL: force kill (no cleanup, uncatchable)
kill -1 1234                    # SIGHUP: reload config (nginx, sshd, etc.)
kill -2 1234                    # SIGINT: keyboard interrupt (like Ctrl+C)
kill -3 1234                    # SIGQUIT: quit with core dump
kill -18 1234                   # SIGCONT: continue stopped process
kill -19 1234                   # SIGSTOP: pause process (uncatchable)
kill -20 1234                   # SIGTSTP: keyboard stop (catchable, like Ctrl+Z)
kill -0 1234                    # Check if process exists (no signal sent)
kill -- -1234                   # Kill entire process group (negative PID)
kill -s TERM 1234               # Use signal name instead of number
killall nginx                   # Kill all processes named nginx
killall -9 python3              # Force kill all python3 processes
killall -u www-data             # Kill all processes by user
pkill nginx                     # Kill by name match (regex)
pkill -f "python app.py"        # Kill by full command line match
pkill -u www-data               # Kill all processes by user
pkill -g 1234                   # Kill by process group ID
pkill -9 -f "node server.js"    # Force kill by full command

## pgrep — find process IDs
pgrep nginx                     # All PIDs matching name
pgrep -f "python app.py"        # Match full command line
pgrep -l nginx                  # PID + name
pgrep -a nginx                  # PID + full command line
pgrep -u www-data               # All PIDs for user
pgrep -u www-data -l            # With names
pgrep -n nginx                  # Newest matching process only
pgrep -o nginx                  # Oldest matching process only
pgrep -c nginx                  # Count matching processes

## Process state and relationships
pstree                          # Process tree (visual)
pstree -p                       # Process tree with PIDs
pstree -u                       # Show owning user
pstree -a                       # Show command arguments
pstree 1234                     # Tree starting from PID 1234

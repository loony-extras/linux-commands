#!/usr/bin/env bash
# =============================================================================
# strace & ltrace — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### strace — system call tracer
# ---------------------------------------------------------------------------
strace ls                               # Trace all syscalls for ls
strace -p 1234                          # Attach to running process (noninvasive)
strace -c ls                            # Count syscalls: summary table
strace -e trace=network curl google.com # Network syscalls only
strace -e trace=file ls /tmp           # File-related syscalls only
strace -e trace=read,write cat file.txt # Specific syscalls
strace -e trace=open,openat,read ls    # Open + read calls
strace -T ls                            # Show time spent in each call
strace -t ls                            # Timestamps on each line
strace -tt ls                           # Microsecond timestamps
strace -r ls                            # Relative timestamps
strace -o strace.out ls                 # Write to file (keeps stdout clean)
strace -f ls                            # Follow forks (trace child processes)
strace -ff -o trace.pid ls             # Follow forks, one file per PID
strace -s 200 ls                        # Larger string size (default 32 chars)
strace -e trace=signal kill 1234        # Signal-related syscalls
strace -e trace=process ls             # Process management calls (exec, fork, etc.)
# Useful one-liner: count syscalls for a command
strace -c -f ./myprogram 2>&1 | sort -k4 -rn | head -20
# Attach to nginx worker and see what it's reading
strace -p $(pgrep -n nginx) -e trace=read,write -s 1024 2>&1 | grep -v ^close

# ---------------------------------------------------------------------------
### ltrace — library call tracer
# ---------------------------------------------------------------------------
ltrace ./myprogram                      # Trace all library calls
ltrace -e malloc,free ./myprogram       # Specific library functions
ltrace -c ./myprogram                   # Summary count
ltrace -p 1234                          # Attach to process

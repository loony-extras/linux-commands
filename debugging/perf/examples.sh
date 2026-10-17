#!/usr/bin/env bash
# =============================================================================
# perf — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### perf — Linux performance analysis tool (apt install linux-tools-common)
# ---------------------------------------------------------------------------
perf stat ls                            # Hardware event counts for a command
perf stat -d ls                         # Detailed hardware events
perf stat -a sleep 5                    # System-wide for 5 seconds
perf top                                # Real-time top by kernel/user symbol
perf top -p 1234                        # For specific PID
perf top -K                             # Kernel-only symbols
perf top -U                             # User-space only

# Recording and reporting
perf record ./myprogram                 # Record profile (saves perf.data)
perf record -F 99 ./myprogram           # 99 Hz sampling frequency
perf record -F 99 -g ./myprogram        # With call graph (for flamegraphs)
perf record -F 99 -g -p 1234 sleep 30  # Attach to running PID, 30 seconds
perf report                             # Interactive report from perf.data
perf report --stdio                     # Non-interactive text report
perf report --stdio | head -40          # Quick summary

# Script and annotate
perf script                             # Raw event output (for FlameGraph tools)
perf annotate function_name             # Source-level annotation

# Trace specific events
perf trace ls                           # Syscall trace (like strace but faster)
perf trace -p 1234                      # Trace running process
perf trace -e 'syscalls:sys_enter_openat' ls  # Specific syscall

# Count specific hardware events
perf stat -e cache-misses,cache-references,instructions,cycles ./myprogram
perf stat -e L1-dcache-loads,L1-dcache-load-misses,LLC-loads ./myprogram

# Flamegraph generation (Brendan Gregg's tools)
# git clone https://github.com/brendangregg/FlameGraph && cd FlameGraph
perf record -F 99 -g -p $(pgrep myapp) sleep 30
perf script | ./stackcollapse-perf.pl | ./flamegraph.pl > /tmp/flamegraph.svg
# Open flamegraph.svg in browser for visual profile

#!/usr/bin/env bash
# =============================================================================
# bpftrace — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### bpftrace — eBPF tracing (apt install bpftrace)
# ---------------------------------------------------------------------------
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'
bpftrace -e 'kprobe:do_sys_open { printf("PID %d opened: %s\n", pid, str(arg1)); }'
bpftrace -e 'tracepoint:block:block_rq_complete { @ = hist(args->nr_sector * 512); }'  # Block I/O histogram
bpftrace -e 'profile:hz:99 { @[comm] = count(); } interval:s:5 { print(@); clear(@); }'  # CPU profiler
bpftrace -l 'tracepoint:syscalls:*'     # List all syscall tracepoints
bpftrace -l 'kprobe:tcp*'              # List TCP kernel probes

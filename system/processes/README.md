# Processes

Process lifecycle, ps, top, nice, kill.

---

## Files

- [examples.sh](examples.sh)

---

## Process Lifecycle

```
fork() → exec() → run → exit()
  │         │               │
  │         └─ loads new    └─ sends SIGCHLD to parent
  └─ copies parent process      parent must wait() to reap
```

### Process States

| State | Symbol | Meaning |
|-------|--------|---------|
| Running | R | Actively executing or runnable |
| Sleeping | S | Interruptible sleep (waiting for event) |
| Disk Sleep | D | Uninterruptible sleep (waiting for I/O) — cannot be killed |
| Stopped | T | Stopped by signal (SIGSTOP or debugger) |
| Zombie | Z | Exited, parent hasn't called wait() yet |
| Idle | I | Idle kernel thread |

```bash
# View process tree
pstree -p              # With PIDs
pstree -u              # Show owners

# Zombie processes — find and investigate
ps aux | awk '$8 == "Z"'
# Zombies are harmless unless numerous — fix the parent process

# Process limits
ulimit -a              # Show all limits for current shell
ulimit -n 65536        # Increase open files for this session
ulimit -u 4096         # Max user processes
# For persistent limits: /etc/security/limits.conf
# or /etc/security/limits.d/99-custom.conf
```


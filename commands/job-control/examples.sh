#!/usr/bin/env bash
# =============================================================================
# job-control — annotated command examples
# Tier: 4 (Expert)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### Job Control — bg, fg, nohup, disown, wait
# ---------------------------------------------------------------------------
## Background / foreground
command &                       # Run in background; prints [jobnum] PID
jobs                            # List active jobs
jobs -l                         # List with PIDs
fg                              # Bring most recent job to foreground
fg %1                           # Bring job 1 to foreground
fg %nginx                       # Bring job named 'nginx' to foreground
bg                              # Resume stopped job in background
bg %2                           # Resume job 2 in background
Ctrl+Z                          # Suspend foreground process (sends SIGTSTP)
Ctrl+C                          # Interrupt foreground process (sends SIGINT)
Ctrl+\                          # Quit with core dump (sends SIGQUIT)

## nohup — run immune to hangup (survive terminal close)
nohup ./long-job.sh &                           # Output goes to nohup.out
nohup ./long-job.sh > /var/log/job.log 2>&1 &  # Custom log file
echo "PID: $!"                                   # PID of last background command

## disown — detach from shell's job table
./long-job &
disown %1                       # Remove from job table (survives shell exit)
disown -h %1                    # Mark SIGHUP-immune but keep in table

## wait — wait for background jobs
./job1.sh & pid1=$!
./job2.sh & pid2=$!
./job3.sh & pid3=$!
wait $pid1 $pid2 $pid3          # Wait for all three
echo "All jobs done"
wait $pid1 || echo "job1 failed with $?"  # Check individual exit codes

# Parallel with error tracking
pids=()
for server in web-01 web-02 db-01; do
  ssh "$server" "apt-get upgrade -y" &
  pids+=($!)
done
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failed++))
done
echo "$failed server(s) failed"

## screen / tmux — terminal multiplexers (survive disconnections)
screen -S mysession             # Start named session
screen -ls                      # List sessions
screen -r mysession             # Reattach to session
screen -d -r mysession          # Detach and reattach
# Inside screen: Ctrl+A D = detach, Ctrl+A C = new window, Ctrl+A N = next window

tmux new -s mysession           # Start named tmux session
tmux ls                         # List sessions
tmux attach -t mysession        # Attach to session
tmux detach                     # Detach from session (Ctrl+B D)
# Inside tmux: Ctrl+B D=detach, Ctrl+B C=new window, Ctrl+B N=next, Ctrl+B %=split

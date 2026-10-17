# bash

Shell setup, scripting, pipes and redirection.

---

## Files

- [examples.sh](examples.sh)

---

## Shell Environment Setup

### /etc/environment — system-wide environment variables

```bash
cat >> /etc/environment << 'EOF'
EDITOR=vim
VISUAL=vim
PAGER=less
LANG=en_US.UTF-8
EOF
```

### /etc/profile.d/ — drop-in scripts for login shells

```bash
# Create a custom system-wide profile
cat > /etc/profile.d/99-custom.sh << 'EOF'
# Unlimited core dumps for debugging (remove on hardened systems)
# ulimit -c unlimited

# Increase open file descriptor limit
ulimit -n 65536

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Prompt with hostname and path
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
```

### ~/.bashrc — per-user interactive shell

```bash
# Useful aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias top='htop'
alias ..='cd ..'
alias ...='cd ../..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git pull'

# Networking
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me'

# System info
alias sysinfo='echo "CPU: $(nproc) cores | RAM: $(free -h | awk "/^Mem/{print \$2}") | Disk: $(df -h / | awk "NR==2{print \$3}")/$(df -h / | awk "NR==2{print \$2}")"'
```

---

## Expert — Bash Scripting Patterns

### Error Handling (most important pattern)

Every production script must start with:
```bash
set -euo pipefail
```
- `-e` Exit immediately if a command fails
- `-u` Treat unset variables as errors (prevents `rm -rf /$UNSET_VAR/`)
- `-o pipefail` Pipe fails if ANY command in it fails (not just the last)

### Defensive Variable Expansion

```bash
# These four operators cover every real-world case:
${VAR:-default}    # Use default if unset or empty (VAR unchanged)
${VAR:=default}    # Assign default if unset or empty (VAR changes)
${VAR:?error msg}  # Abort with error if unset or empty
${VAR:+alternate}  # Use alternate if SET (else empty)

# Path manipulation (no need for dirname/basename in many cases)
file="/var/log/nginx/access.log"
echo "${file%/*}"          # /var/log/nginx   (strip suffix from last /)
echo "${file##*/}"         # access.log        (strip prefix up to last /)
echo "${file%.log}"        # /var/log/nginx/access  (strip .log)
echo "${file##*.}"         # log               (extension only)
```

### The Retry Pattern (critical for cloud/network scripts)

```bash
retry() {
  local max=$1 delay=$2; shift 2
  local attempt=1
  while (( attempt <= max )); do
    "$@" && return 0
    echo "Attempt $attempt/$max failed, retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
  done
  echo "All $max attempts failed: $*" >&2
  return 1
}

retry 5 10 curl -f https://api.example.com/health
```

### Parallel Execution (real-world pattern)

```bash
# Run tasks in parallel, collect exit codes
MAX_PARALLEL=4
pids=()

for server in web-01 web-02 db-01 db-02; do
  # Limit parallelism
  while (( ${#pids[@]} >= MAX_PARALLEL )); do
    for i in "${!pids[@]}"; do
      kill -0 "${pids[$i]}" 2>/dev/null || unset "pids[$i]"
    done
    pids=("${pids[@]}")   # Re-index
    sleep 0.1
  done

  (ssh "admin@$server" "uptime") &
  pids+=($!)
done

# Wait for all and check results
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failed++))
done
echo "Parallel tasks done: $failed failed"
```


---

## Bash Automation Scripts

See [system/installation/initial-setup.sh](../../system/installation/initial-setup.sh) for the full provisioning script.

### Idiomatic Bash Patterns

```bash
#!/usr/bin/env bash
# Production-grade bash script template

set -euo pipefail                    # Exit on error, unset var, pipe fail
IFS=$'\n\t'                         # Safer word splitting

# Logging with timestamps
readonly LOG_FILE="/var/log/myscript.log"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { log "ERROR: $*" >&2; exit 1; }

# Root check
[[ $EUID -eq 0 ]] || error "Must run as root"

# Dependency check
require_commands() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || error "Required command not found: $cmd"
  done
}
require_commands curl wget systemctl apt

# Cleanup handler
cleanup() {
  local exit_code=$?
  log "Script exiting with code $exit_code"
  rm -f /tmp/myscript.lock
}
trap cleanup EXIT
trap 'error "Caught SIGINT"' INT
trap 'error "Caught SIGTERM"' TERM

# Lock file (prevent concurrent runs)
LOCK=/tmp/myscript.lock
if ! mkdir "$LOCK" 2>/dev/null; then
  error "Another instance is running (lock: $LOCK)"
fi

# Retry function
retry() {
  local max_attempts="$1"
  local delay="$2"
  shift 2
  local attempt=1
  while (( attempt <= max_attempts )); do
    "$@" && return 0
    log "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
  done
  error "Command failed after $max_attempts attempts: $*"
}

retry 3 10 curl -f https://example.com/resource -o /tmp/resource

# Config file parser (key=value format)
parse_config() {
  local config_file="$1"
  local -n config_ref="$2"             # nameref (bash 4.3+)
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[[:space:]]*# ]] && continue   # Skip comments
    [[ -z "$key" ]] && continue                   # Skip empty lines
    key="${key// /}"                              # Trim spaces
    value="${value// /}"
    config_ref["$key"]="$value"
  done < "$config_file"
}

declare -A config
parse_config /etc/myapp/config.env config
echo "DB host: ${config[DB_HOST]}"
```


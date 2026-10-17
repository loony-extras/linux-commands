#!/usr/bin/env bash
# =============================================================================
# one-liners — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### Automation One-Liners
# ---------------------------------------------------------------------------
# Show top 10 memory consumers with name
ps aux --sort=-%rss | awk 'NR<=10 {printf "%-20s %8.1f MB\n", $11, $6/1024}'

# Kill all processes owned by a user (use carefully)
pkill -u baduser; sleep 2; pkill -9 -u baduser

# Quickly find which process is listening on a port
fuser -n tcp 8080                          # PID using TCP port 8080
fuser -k 8080/tcp                          # Kill process using port 8080

# Add user with SSH key in one command
useradd -m -s /bin/bash john && \
  mkdir -p /home/john/.ssh && \
  echo "ssh-ed25519 AAAA..." > /home/john/.ssh/authorized_keys && \
  chmod 700 /home/john/.ssh && chmod 600 /home/john/.ssh/authorized_keys && \
  chown -R john:john /home/john/.ssh

# Find largest files, human-readable, sorted
find / -xdev -type f -printf '%s %p\n' 2>/dev/null | \
  sort -rn | head -20 | awk '{printf "%10.1f MB  %s\n", $1/1048576, $2}'

# Replace string in ALL files recursively (with backup)
grep -rl "old-string" /path/ | \
  xargs sed -i.bak 's/old-string/new-string/g'

# Archive and compress a directory, show progress
tar -cf - /var/www | pv -s $(du -sb /var/www | awk '{print $1}') | gzip > www.tar.gz

# Count files by extension in current directory tree
find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

# Watch a directory for changes (inotify)
inotifywait -m -r -e modify,create,delete,moved_to /var/www 2>/dev/null | \
  while read path action file; do
    echo "$(date): $action $path$file"
  done

# Quickly test if a port is open (no netcat needed)
(echo >/dev/tcp/hostname/80) &>/dev/null && echo open || echo closed

# One-liner HTTP server on port 8080
python3 -m http.server 8080

# Generate a strong random password
openssl rand -base64 24 | tr -d '/+='

# Base64 encode/decode
echo "my secret" | base64
echo "bXkgc2VjcmV0Cg==" | base64 -d

# Check SSL certificate expiry for a domain
echo | openssl s_client -connect example.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# One-liner system health snapshot
hostname && uptime && free -h | awk '/Mem/{print "RAM:",$3"/"$2}' && \
  df -h / | awk 'NR==2{print "Disk:",$3"/",$2,"("$5")"}' && \
  ss -s | grep TCP:

# Find all open network connections with process names
ss -tnp | awk 'NR>1 {print $5, $6}' | sort -k2

# Monitor a file for changes and react
while true; do
  inotifywait -e modify /etc/nginx/nginx.conf 2>/dev/null
  nginx -t && systemctl reload nginx && echo "nginx reloaded"
done

# Count unique IPs accessing your server in real time
watch -n 5 'ss -tnp | awk "NR>1{print \$5}" | cut -d: -f1 | sort | uniq -c | sort -rn | head -10'

# Find duplicate files by MD5 hash
find . -type f -exec md5sum {} + | sort | awk 'prev==$1{print $2" is duplicate of prev_file"} {prev=$1; prev_file=$2}'

# Create self-signed TLS certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj '/CN=localhost'

# Show disk I/O by process in real time (requires root)
iotop -o -b -n 3 | awk 'NR>2 && /[KMG]/ {print $NF, $(NF-3)}'

# Parallel SSH command execution
for host in web-01 web-02 db-01; do
  ssh -o StrictHostKeyChecking=yes -o ConnectTimeout=5 "$host" \
    "hostname && uptime" 2>&1 &
done; wait

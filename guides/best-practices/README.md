# Best Practices, Anti-Patterns, Scaling & Migration

## Best Practices Checklist

### System Administration
```
[ ] Use configuration management (Ansible, Puppet, Chef) — no manual changes
[ ] All changes via version-controlled code (git)
[ ] Immutable infrastructure: replace, don't patch in production
[ ] Separate logs, tmp, var from root filesystem
[ ] LVM or ZFS for all data volumes (enables snapshots, online resize)
[ ] Monitor inodes, not just disk space
[ ] Enable process accounting (psacct/acct)
[ ] All secrets in a secrets manager (Vault, AWS Secrets Manager) — never in code
[ ] Principle of least privilege: every user, every service, every process
[ ] Document everything that isn't obvious from reading the code
```

### SSH & Access
```
[ ] Ed25519 keys only (no RSA < 4096)
[ ] Key rotation policy (annually at minimum)
[ ] Bastion host for all production SSH access
[ ] SSH agent forwarding: use ProxyJump, not AgentForward
[ ] Disable root SSH (always)
[ ] Disable password SSH (always)
[ ] Record all privileged sessions (sudoreplay or teleport)
[ ] MFA for bastion access
```

### Networking
```
[ ] All services: bind to loopback or internal IP, not 0.0.0.0 unless necessary
[ ] Deny by default, allow by exception (firewall default policy DROP)
[ ] Separate management network from production traffic
[ ] TLS everywhere (even internal services)
[ ] Certificate automation (certbot + Let's Encrypt or internal CA)
[ ] No self-signed certs in production
```

### Backups
```
[ ] 3-2-1 rule: 3 copies, 2 different media, 1 offsite
[ ] Backups are encrypted at rest (GPG or AES-256)
[ ] Backup VERIFICATION: restore tested monthly
[ ] Point-in-time recovery for databases
[ ] RTO and RPO defined and tested
[ ] Backup process is automated and monitored
[ ] Never store backups on the same host as production data
```

### Scripting
```
[ ] set -euo pipefail in every bash script
[ ] Lock files to prevent concurrent execution
[ ] Idempotent: safe to run multiple times
[ ] Log with timestamps
[ ] Validate all inputs
[ ] Test on a staging system before production
[ ] Cleanup handlers (trap EXIT)
```

---

## Anti-Patterns to Avoid

### Extremely Common Mistakes

```bash
# ANTI-PATTERN: Storing credentials in scripts or environment files in /tmp
export DB_PASS=mysecretpassword
# INSTEAD: Use /run/secrets, Vault, or environment files with 600 permissions

# ANTI-PATTERN: Running apps as root
CMD ["node", "server.js"]   # In a Dockerfile with USER root
# INSTEAD: Create a dedicated user
RUN useradd -r -u 1001 appuser
USER appuser

# ANTI-PATTERN: rm -rf with unvalidated variables
DEPLOY_DIR=/app
rm -rf $DEPLOY_DIR/           # If DEPLOY_DIR is empty: rm -rf /
# INSTEAD: Always validate and quote
[[ -n "$DEPLOY_DIR" ]] || error "DEPLOY_DIR is not set"
rm -rf "${DEPLOY_DIR:?DEPLOY_DIR unset}/"

# ANTI-PATTERN: chmod 777 to fix permission problems
chmod 777 /var/www/html      # Exposes files to all users and processes
# INSTEAD: Set correct owner and use 755/644
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# ANTI-PATTERN: Using apt in Dockerfile without pinning versions
RUN apt-get install nginx    # Installs whatever version is current at build time
# INSTEAD: Pin versions
RUN apt-get install nginx=1.24.0-1ubuntu1

# ANTI-PATTERN: Ignoring exit codes
cp important-file.txt /backup/
# INSTEAD:
cp important-file.txt /backup/ || { echo "Backup failed!"; exit 1; }

# ANTI-PATTERN: Not testing firewall rules before applying (risk of lockout)
ufw enable                   # With default deny — can block SSH without an allow rule
# INSTEAD:
ufw allow ssh                # Allow SSH FIRST
ufw enable                   # THEN enable

# ANTI-PATTERN: Cron jobs that silently fail
0 2 * * * /backup/run.sh    # Errors go nowhere — you don't know it failed
# INSTEAD: Always redirect or mail
0 2 * * * /backup/run.sh >> /var/log/backup.log 2>&1 || \
  echo "Backup failed at $(date)" | mail -s "BACKUP FAILED" admin@company.com

# ANTI-PATTERN: `find ... | xargs rm` without -print0 / -0
find /tmp -name "*.tmp" | xargs rm    # Breaks on filenames with spaces
# INSTEAD:
find /tmp -name "*.tmp" -print0 | xargs -0 rm

# ANTI-PATTERN: Using iptables-save without actually restoring on reboot
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT  # Lost on reboot
# INSTEAD: Use iptables-persistent or nftables with systemd unit

# ANTI-PATTERN: Docker as root, all containers sharing network
docker run --privileged --network host myapp   # No isolation at all
# INSTEAD: Run rootless, use custom bridge network
```

### Architecture Anti-Patterns

```
❌ Single server for everything (SPOF)
   → Use at least 2 web servers behind a load balancer

❌ Shared /tmp with world-write and execute
   → Separate /tmp as tmpfs with noexec,nosuid

❌ No log rotation (disks fill up)
   → Configure logrotate for all custom logs

❌ Cron jobs on the same schedule on multiple servers (thundering herd)
   → Stagger with RandomizedDelaySec= in systemd timers

❌ No monitoring for backup success/failure
   → Monitor with Prometheus backup_last_success_timestamp gauge

❌ SSH port forwarding wide open on internal servers
   → AllowTcpForwarding no in sshd_config unless explicitly needed

❌ Container images that run as root
   → Always set USER in Dockerfile

❌ Long-lived service accounts with broad permissions
   → Rotate credentials, use short-lived tokens (AWS STS, Vault)
```

---

## Scaling Linux Systems

### Vertical Scaling (bigger machine)

```bash
# Add CPU — online hot-plug (if kernel/hardware supports)
echo 1 > /sys/devices/system/cpu/cpu3/online
nproc

# Extend LVM without downtime
lvextend -L +50G /dev/vg_system/lv_data
resize2fs /dev/vg_system/lv_data    # ext4 — online resize
xfs_growfs /mnt/data                 # xfs — online resize

# Add RAM — NUMA-aware tuning
numactl --hardware
# Ensure memory is allocated from the correct NUMA node
numactl --cpunodebind=0 --membind=0 ./myapp
```

### Horizontal Scaling (more machines)

```bash
# Session management: move from local files to Redis
# Session stored in Redis → any server can serve any request

# Shared storage for app uploads
# NFS: for simple shared storage
# Ceph/GlusterFS: for distributed storage
# Object storage (S3/MinIO): for static assets and backups

# Database read scaling
# Primary/replica streaming replication (PostgreSQL)
# Application reads from replica, writes to primary

# Load balancer setup (HAProxy)
cat > /etc/haproxy/haproxy.cfg << 'EOF'
frontend http
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web-01 192.168.1.10:80 check inter 5s rise 2 fall 3
    server web-02 192.168.1.11:80 check inter 5s rise 2 fall 3

frontend stats
    bind *:8404
    stats enable
    stats uri /
    stats auth admin:secretpass
EOF

# Connection pooling for PostgreSQL (PgBouncer)
apt install pgbouncer
# Reduces connection overhead from many short-lived app connections
```

---

## Migration: Bare Metal → Cloud

### Phase 1: Assess

```bash
# Inventory current system
lshw -short                      # Hardware
df -h                            # Storage
ss -tlnp                         # Open ports
systemctl list-units --state=running  # Running services
dpkg -l | grep ^ii | wc -l      # Package count
crontab -l; ls /etc/cron.d/     # Cron jobs
lsmod                            # Kernel modules
cat /etc/fstab                   # Mount points
```

### Phase 2: Replicate with IaC

```bash
# Capture OS-level config
ansible localhost -m setup > server-facts.json
dpkg --get-selections > packages.list

# Generate Terraform for cloud (example: AWS EC2)
# terraform/main.tf:
# resource "aws_instance" "web" {
#   ami           = "ami-0c02fb55956c7d316"  # Ubuntu 22.04
#   instance_type = "t3.medium"
#   ...
# }

# Test IaC in staging before production cutover
```

### Phase 3: Data Migration

```bash
# Database migration with minimal downtime
# 1. Set up replica pointing to bare metal primary
# 2. Wait for replica to catch up
# 3. Maintenance window: promote replica, update app connection strings
# 4. DNS cutover

# File sync
rsync -azP --delete /var/www/ user@cloud-server:/var/www/

# DNS TTL reduction before cutover
# Set TTL to 60 seconds 24h before migration
# After successful cutover, increase back to 3600+
```

### Phase 4: Cutover

```bash
# Blue-green deployment for zero-downtime
# 1. Deploy new (cloud) infrastructure (blue)
# 2. Health check blue
# 3. Switch load balancer / DNS to blue
# 4. Monitor for 30 minutes
# 5. Decommission old (green) when stable
```

---

## Disaster Recovery Planning

### RTO and RPO

```
RTO (Recovery Time Objective) = max acceptable downtime
RPO (Recovery Point Objective) = max acceptable data loss

Example targets:
  Tier 1 (critical): RTO=1h, RPO=15min
  Tier 2 (important): RTO=4h, RPO=1h
  Tier 3 (low priority): RTO=24h, RPO=24h
```

### DR Runbooks

```bash
# /usr/local/bin/dr-restore.sh
# Disaster recovery script — executes full server restore from backup

#!/bin/bash
set -euo pipefail

BACKUP_DATE="${1:?Usage: $0 YYYYMMDD}"
BACKUP_HOST="${BACKUP_HOST:-backup.company.com}"
BACKUP_PATH="/backups/$(hostname)/$BACKUP_DATE"

echo "=== Disaster Recovery: $(hostname) ==="
echo "Restore from: $BACKUP_HOST:$BACKUP_PATH"

# Step 1: Restore filesystem
rsync -azP "${BACKUP_HOST}:${BACKUP_PATH}/" /

# Step 2: Restore database
gzip -dc "${BACKUP_PATH}/databases/postgresql_${BACKUP_DATE}.sql.gz" | \
  sudo -u postgres psql

# Step 3: Restart services
systemctl daemon-reload
systemctl restart nginx postgresql redis-server myapp

# Step 4: Verify
curl -f http://localhost/health && echo "Application: HEALTHY"
sudo -u postgres psql -c "\l" && echo "Database: HEALTHY"

echo "Recovery complete at $(date)"
```

### Recovery Testing

```bash
# Monthly DR drill script — test restore in isolated environment
dr_test() {
  local test_server="dr-test-$(date +%Y%m%d)"

  # Spin up a temporary server (cloud)
  # ... terraform apply / cloud API call ...

  # Run restore
  ssh "admin@${test_server}" "bash /usr/local/bin/dr-restore.sh $(date +%Y%m%d)"

  # Verify
  ssh "admin@${test_server}" "bash /usr/local/bin/security-check.sh"
  curl -f "http://${test_server}/health"

  # Record results
  echo "DR Test $test_server: PASS at $(date)" >> /var/log/dr-tests.log

  # Terminate test server
  # ... terraform destroy ...
}
```

---

## Operational Readiness Checklist

Before any system goes to production:

```
INFRASTRUCTURE
[ ] Two or more servers for all critical services
[ ] Load balancer with health checks configured
[ ] Database primary + replica with streaming replication
[ ] Backups automated, verified, and offsite
[ ] DNS failover configured (if applicable)

SECURITY
[ ] Security hardening script applied and verified
[ ] All secrets in secrets manager
[ ] TLS on all endpoints (including internal)
[ ] Vulnerability scan passed (Lynis score > 70)
[ ] Penetration test completed (annual)

OBSERVABILITY
[ ] All services export metrics to Prometheus
[ ] Grafana dashboards for CPU, memory, disk, network, app-specific
[ ] Alerts defined for all SLO-breaking conditions
[ ] Log aggregation configured (ELK, Loki, or CloudWatch)
[ ] On-call rotation configured in PagerDuty/OpsGenie

PROCESS
[ ] Runbooks documented for top 10 incidents
[ ] DR plan documented and tested
[ ] Change management process (no surprise changes)
[ ] Post-mortem process defined
[ ] Backup restore tested within last 30 days
```

---

## Lynis Security Audit

```bash
# Install Lynis (security auditing tool)
apt install -y lynis

# Run audit
lynis audit system 2>&1 | tee /var/log/lynis-$(date +%Y%m%d).log

# Key sections to review:
# - System hardening index (higher = better)
# - Warning and suggestion list at the end
# - Authentication strength
# - Kernel hardening
# - Network security

# Typical production target: score > 75 (max 100)
# New Ubuntu default: ~65
# After loony-linux hardening: ~80-85

# Generate report
lynis audit system --report-file /var/log/lynis-report.dat
lynis show details <test-id>    # Details on specific test
```

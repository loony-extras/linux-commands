# Real-World Project Template

This section describes a complete production server setup using all the tools in this repo.

## Architecture Overview

```
Internet
    │
    ▼
[Cloudflare / DNS]
    │
    ▼
[Load Balancer / Bastion]  ← Public IP, SSH on :2222
    │
    ├── [web-01]  nginx + app containers
    ├── [web-02]  nginx + app containers (HA)
    │
    ├── [db-01]   PostgreSQL primary
    ├── [db-02]   PostgreSQL replica (streaming replication)
    │
    └── [mon-01]  Prometheus + Grafana + alertmanager
```

## Provisioning Workflow

```bash
# On a fresh Ubuntu 22.04 server:

# Step 1: Initial setup (installs packages, creates admin user, SSH hardening, UFW)
sudo bash system/installation/initial-setup.sh \
  --hostname web-01 \
  --admin-user deploy \
  --timezone UTC

# Step 2: Copy SSH public key
ssh-copy-id -i ~/.ssh/prod_ed25519.pub deploy@<server-ip>

# Step 3: Disable password auth
ssh deploy@<server-ip> "sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' \
  /etc/ssh/sshd_config.d/99-hardening.conf && sudo sshd -t && sudo systemctl reload sshd"

# Step 4: Deeper security hardening
ssh deploy@<server-ip> "sudo bash -s" < security/hardening/harden.sh

# Step 5: Set up firewall for this server's role
ssh deploy@<server-ip> "sudo bash -s" < networking/firewall/firewall-setup.sh \
  -- --profile web --ssh-port 22

# Step 6: Ansible full provision
ansible-playbook -i devops/ansible/inventory/hosts.yml devops/ansible/playbooks/site.yml \
  --limit web-01 \
  --diff \
  --check    # Dry run first

ansible-playbook -i devops/ansible/inventory/hosts.yml devops/ansible/playbooks/site.yml \
  --limit web-01

# Step 7: Deploy app stack
scp devops/docker/docker-compose.yml deploy@web-01:/opt/myapp/
ssh deploy@web-01 "cd /opt/myapp && docker compose up -d"

# Step 8: Verify
curl -f https://app.company.com/health
```

## Security Baseline Verification

Run this checklist on every server:

```bash
#!/bin/bash
# security-check.sh — verify security baseline

PASS=0; FAIL=0

check() {
  local desc="$1"; shift
  if eval "$*" &>/dev/null; then
    echo "  [PASS] $desc"
    ((PASS++))
  else
    echo "  [FAIL] $desc"
    ((FAIL++))
  fi
}

echo "=== Security Baseline Check: $(hostname) ==="

# Authentication
check "Root login disabled in SSH" \
  "sshd -T | grep -q 'permitrootlogin no'"
check "Password auth disabled in SSH" \
  "sshd -T | grep -q 'passwordauthentication no'"
check "SSH listens on non-standard port or has rate limit" \
  "ufw status | grep -q 'LIMIT'"

# Services
check "fail2ban running" "systemctl is-active fail2ban"
check "auditd running" "systemctl is-active auditd"
check "UFW enabled" "ufw status | grep -q 'Status: active'"
check "AppArmor loaded" "apparmor_status | grep -q 'profiles are in enforce'"
check "unattended-upgrades enabled" "systemctl is-enabled unattended-upgrades"

# Kernel parameters
check "ASLR enabled" "[[ $(sysctl -n kernel.randomize_va_space) == 2 ]]"
check "SYN cookies enabled" "[[ $(sysctl -n net.ipv4.tcp_syncookies) == 1 ]]"
check "IP forwarding disabled" "[[ $(sysctl -n net.ipv4.ip_forward) == 0 ]]"
check "dmesg restricted" "[[ $(sysctl -n kernel.dmesg_restrict) == 1 ]]"
check "Symlink protection" "[[ $(sysctl -n fs.protected_symlinks) == 1 ]]"

# Filesystem
check "/tmp noexec" "mount | grep '/tmp' | grep -q noexec"
check "No world-writable files in /etc" \
  "! find /etc -xdev -perm -o+w -type f 2>/dev/null | grep -q ."

# Users
check "No empty passwords" \
  "! awk -F: '(\$2 == \"\" ) { print \$1 }' /etc/shadow | grep -q ."
check "No root-owned files in /home" \
  "! find /home -xdev -user root -type f 2>/dev/null | grep -q ."

echo
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "BASELINE: PASS" || echo "BASELINE: FAIL — review failures above"
```

## Monitoring Integration

```bash
# Deploy Prometheus + Grafana via Docker Compose
docker compose --profile monitoring up -d prometheus grafana

# Install node_exporter on all servers
bash monitoring/node-exporter/node-exporter.sh

# Access Grafana at http://mon-01:3000
# Import dashboards:
# - Node Exporter Full: dashboard ID 1860
# - Nginx: dashboard ID 9614
# - PostgreSQL: dashboard ID 9628
# - Docker: dashboard ID 893

# Set up alertmanager for PagerDuty/Slack
cat > /etc/alertmanager/alertmanager.yml << 'EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-critical'
  routes:
    - match:
        severity: critical
      receiver: pagerduty
    - match:
        severity: warning
      receiver: slack-warning

receivers:
  - name: pagerduty
    pagerduty_configs:
      - service_key: <PagerDuty-integration-key>

  - name: slack-critical
    slack_configs:
      - api_url: <Slack-webhook-URL>
        channel: '#alerts-critical'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

  - name: slack-warning
    slack_configs:
      - api_url: <Slack-webhook-URL>
        channel: '#alerts-warning'
EOF
```

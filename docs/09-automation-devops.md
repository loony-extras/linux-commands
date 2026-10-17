# Section 09 — Automation & DevOps

## 9.1 Bash Automation Scripts

See [scripts/setup/initial-setup.sh](../scripts/setup/initial-setup.sh) for the full provisioning script.

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

---

## 9.2 Ansible Playbooks

See [ansible/](../ansible/) directory for full playbooks and roles.

### Inventory

```yaml
# ansible/inventory/hosts.yml
all:
  vars:
    ansible_user: admin
    ansible_ssh_private_key_file: ~/.ssh/prod_ed25519
    ansible_ssh_common_args: '-o StrictHostKeyChecking=yes'

  children:
    web:
      hosts:
        web-01:
          ansible_host: 192.168.1.10
        web-02:
          ansible_host: 192.168.1.11
      vars:
        nginx_workers: 4

    db:
      hosts:
        db-01:
          ansible_host: 192.168.1.20
      vars:
        postgres_max_connections: 200

    bastion:
      hosts:
        bastion-01:
          ansible_host: 1.2.3.4
          ansible_port: 2222
```

### Main Site Playbook

```yaml
# ansible/playbooks/site.yml
---
- name: Common baseline for all servers
  hosts: all
  become: yes
  roles:
    - common
    - security

- name: Web servers
  hosts: web
  become: yes
  roles:
    - nginx
    - certbot

- name: Database servers
  hosts: db
  become: yes
  roles:
    - postgresql
    - monitoring
```

### Common Role Tasks

```yaml
# ansible/roles/common/tasks/main.yml
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install baseline packages
  apt:
    name:
      - curl
      - wget
      - git
      - vim
      - htop
      - tmux
      - ufw
      - fail2ban
      - auditd
      - unattended-upgrades
    state: present

- name: Set timezone to UTC
  timezone:
    name: UTC

- name: Set hostname
  hostname:
    name: "{{ inventory_hostname }}"

- name: Configure /etc/hosts
  template:
    src: hosts.j2
    dest: /etc/hosts
    owner: root
    group: root
    mode: '0644'

- name: Configure sysctl security parameters
  sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    state: present
    reload: yes
  loop:
    - { name: net.ipv4.ip_forward, value: '0' }
    - { name: kernel.randomize_va_space, value: '2' }
    - { name: net.ipv4.tcp_syncookies, value: '1' }
    - { name: kernel.dmesg_restrict, value: '1' }
    - { name: fs.protected_symlinks, value: '1' }
    - { name: fs.protected_hardlinks, value: '1' }

- name: Disable and mask unnecessary services
  systemd:
    name: "{{ item }}"
    state: stopped
    enabled: no
    masked: yes
  loop:
    - avahi-daemon
    - cups
    - bluetooth
  ignore_errors: yes

- name: Configure unattended upgrades
  template:
    src: 50unattended-upgrades.j2
    dest: /etc/apt/apt.conf.d/50unattended-upgrades
  notify: enable unattended-upgrades

- name: Create admin user
  user:
    name: "{{ admin_user }}"
    groups:
      - sudo
      - adm
    shell: /bin/bash
    create_home: yes
    state: present

- name: Set authorized keys for admin
  authorized_key:
    user: "{{ admin_user }}"
    key: "{{ lookup('file', 'files/authorized_keys') }}"
    state: present
    exclusive: yes

- name: Configure sudo for admin
  copy:
    content: "{{ admin_user }} ALL=(ALL:ALL) ALL\n"
    dest: "/etc/sudoers.d/{{ admin_user }}"
    mode: '0440'
    validate: /usr/sbin/visudo -cf %s
```

### Security Role

```yaml
# ansible/roles/security/tasks/main.yml
---
- name: Configure SSH hardening
  template:
    src: sshd_hardening.conf.j2
    dest: /etc/ssh/sshd_config.d/99-hardening.conf
    mode: '0600'
  notify: restart sshd

- name: Configure UFW defaults
  ufw:
    state: enabled
    policy: deny
    direction: incoming

- name: Allow SSH through UFW
  ufw:
    rule: allow
    port: '22'
    proto: tcp

- name: Configure fail2ban
  template:
    src: jail.local.j2
    dest: /etc/fail2ban/jail.local
  notify: restart fail2ban

- name: Enable and start fail2ban
  service:
    name: fail2ban
    state: started
    enabled: yes

- name: Configure auditd rules
  template:
    src: audit.rules.j2
    dest: /etc/audit/rules.d/99-custom.rules
  notify: restart auditd

- name: Configure sysctl security settings
  template:
    src: sysctl-security.conf.j2
    dest: /etc/sysctl.d/99-security.conf
  notify: reload sysctl

- name: Initialize AIDE database
  command: aide --init
  args:
    creates: /var/lib/aide/aide.db.new
  register: aide_init

- name: Move AIDE database
  command: mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
  when: aide_init.changed
```

### Running Ansible

```bash
# Syntax check
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check

# Dry run (check mode)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check --diff

# Apply to all hosts
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Apply to specific host/group
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit web-01
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit web

# Apply only specific tags
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags security

# Override variables
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  --extra-vars "admin_user=deploy nginx_workers=8"

# Verbose output
ansible-playbook -vvv -i inventory/hosts.yml playbooks/site.yml

# Ad-hoc commands
ansible all -i inventory/hosts.yml -m ping
ansible web -i inventory/hosts.yml -m shell -a "df -h"
ansible web -i inventory/hosts.yml -m apt -a "name=nginx state=latest" --become
ansible db -i inventory/hosts.yml -m service -a "name=postgresql state=restarted" --become
```

---

## 9.3 Docker Setup and Management

### Installation

```bash
# Official Docker Engine install (Ubuntu)
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Post-install
usermod -aG docker $USER       # Add user to docker group (avoid sudo)
systemctl enable --now docker
```

### Docker Operations

```bash
# Images
docker pull ubuntu:22.04
docker images
docker rmi ubuntu:22.04
docker image prune -f         # Remove dangling images
docker image prune -a         # Remove all unused images

# Containers
docker run -d --name myapp \
  -p 8080:80 \
  -v /var/data:/app/data \
  -e APP_ENV=production \
  --restart unless-stopped \
  --memory 512m \
  --cpus 1.5 \
  myapp:latest

docker ps                     # Running containers
docker ps -a                  # All containers
docker stop myapp
docker start myapp
docker restart myapp
docker rm myapp               # Remove stopped container
docker rm -f myapp            # Force remove running container

# Exec into container
docker exec -it myapp bash
docker exec -it myapp sh      # If no bash

# Logs
docker logs myapp
docker logs -f myapp          # Follow
docker logs --tail 100 myapp
docker logs --since 1h myapp

# Inspect
docker inspect myapp
docker inspect --format '{{.NetworkSettings.IPAddress}}' myapp
docker stats                  # Live resource usage
docker stats --no-stream      # One-shot stats

# Network
docker network create mynet --driver bridge
docker network ls
docker run -d --network mynet --name db postgres:15
docker run -d --network mynet --name app myapp:latest

# Volumes
docker volume create mydata
docker volume ls
docker volume inspect mydata
docker volume rm mydata
docker volume prune

# System cleanup
docker system prune            # Remove stopped containers + dangling images
docker system prune -a         # All unused containers, networks, images
docker system df               # Disk usage

# Save and load images (for air-gapped environments)
docker save myapp:latest | gzip > myapp.tar.gz
docker load < myapp.tar.gz
```

### Production Dockerfile

```dockerfile
# docker/Dockerfile.base
# Multi-stage build: keeps final image small

# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server

# Stage 2: Runtime (minimal image)
FROM gcr.io/distroless/static-debian12

# Run as non-root
USER nonroot:nonroot

# Copy only the binary
COPY --from=builder --chown=nonroot:nonroot /app/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
```

### Docker Compose Stack

```yaml
# docker/docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    image: myapp:${APP_VERSION:-latest}
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"     # Bind to loopback only (nginx proxies)
    environment:
      - DATABASE_URL=postgres://app:${DB_PASSWORD}@db:5432/myapp
      - REDIS_URL=redis://cache:6379
      - APP_ENV=production
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    volumes:
      - app_data:/app/data
    networks:
      - internal
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    logging:
      driver: journald
      options:
        tag: "{{.Name}}"

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./configs/postgresql.conf:/etc/postgresql/postgresql.conf:ro
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - internal

  nginx:
    image: nginx:1.25-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./configs/nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - app
    networks:
      - internal
      - external

volumes:
  app_data:
  db_data:
  redis_data:
  nginx_logs:

networks:
  internal:
    internal: true        # No external access
  external:
    driver: bridge
```

---

## 9.4 Kubernetes Basics

See [kubernetes/](../kubernetes/) directory for manifests.

```bash
# kubectl essentials
kubectl get nodes
kubectl get pods -n myapp
kubectl get pods --all-namespaces
kubectl describe pod mypod -n myapp
kubectl logs mypod -n myapp
kubectl logs -f mypod -n myapp -c mycontainer
kubectl exec -it mypod -n myapp -- bash

# Apply manifests
kubectl apply -f deployment.yml
kubectl apply -f kubernetes/         # Apply entire directory

# Rollout management
kubectl rollout status deployment/myapp -n myapp
kubectl rollout history deployment/myapp -n myapp
kubectl rollout undo deployment/myapp -n myapp  # Rollback

# Scaling
kubectl scale deployment myapp --replicas=5 -n myapp
kubectl autoscale deployment myapp --min=2 --max=10 --cpu-percent=70 -n myapp

# Resource inspection
kubectl top nodes
kubectl top pods -n myapp
kubectl get events -n myapp --sort-by='.lastTimestamp'
```

---

## 9.5 CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Build, Test, and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
          cache: true

      - name: Run unit tests
        run: go test ./... -v -race -coverprofile=coverage.out

      - name: Upload coverage
        uses: codecov/codecov-action@v4

  security-scan:
    name: Security Scan
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: CRITICAL,HIGH
          exit-code: '1'

  build-push:
    name: Build and Push Image
    needs: [test, security-scan]
    runs-on: ubuntu-22.04
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=sha-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: Deploy to Production
    needs: build-push
    runs-on: ubuntu-22.04
    environment: production
    concurrency:
      group: production
      cancel-in-progress: false

    steps:
      - uses: actions/checkout@v4

      - name: Deploy via SSH
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PROD_HOST }}
          username: deploy
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /opt/myapp
            docker compose pull
            docker compose up -d --no-deps app
            docker compose exec -T app ./migrate
            docker system prune -f
```

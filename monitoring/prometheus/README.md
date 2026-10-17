# Prometheus

Metrics scraping and alerting.

---

## Files

- [alerts.yml](alerts.yml)
- [prometheus.yml](prometheus.yml)

---

## Usage

| File | Purpose |
|------|---------|
| `prometheus.yml` | Scrapes node_exporter, nginx, postgres, redis, cadvisor, blackbox, app metrics |
| `alerts.yml` | TargetDown, SSL expiry, CPU, memory, disk, I/O, network, PostgreSQL, app errors |

Full stack via Docker Compose (see [devops/docker](../../devops/docker/)):

```bash
docker compose -f devops/docker/docker-compose.yml --profile monitoring up -d prometheus grafana
# Prometheus → http://localhost:9090
# Grafana    → http://localhost:3000  (admin / $GRAFANA_PASSWORD)
```

Dashboards: [monitoring/grafana](../grafana/). Host metrics: [monitoring/node-exporter](../node-exporter/).

---

## Prometheus + Grafana Setup

### Prometheus (metrics collector)

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: production
    datacenter: dc1

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  # Prometheus self-monitoring
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (system metrics)
  - job_name: node
    static_configs:
      - targets:
          - web-01:9100
          - web-02:9100
          - db-01:9100
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance

  # Nginx metrics (nginx-prometheus-exporter)
  - job_name: nginx
    static_configs:
      - targets: ['web-01:9113', 'web-02:9113']

  # PostgreSQL metrics
  - job_name: postgres
    static_configs:
      - targets: ['db-01:9187']

  # Docker containers via cAdvisor
  - job_name: cadvisor
    static_configs:
      - targets: ['localhost:8080']

  # Custom application metrics
  - job_name: myapp
    metrics_path: /metrics
    static_configs:
      - targets: ['app-01:8080', 'app-02:8080']
    basic_auth:
      username: metrics
      password: secretpass
```

### Alert Rules

```yaml
# monitoring/prometheus/rules/alerts.yml
groups:
  - name: node
    rules:
      - alert: NodeDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.instance }} is down"

      - alert: HighCPU
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}: {{ $value }}%"

      - alert: HighMemory
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory on {{ $labels.instance }}: {{ $value }}%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_free_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Disk space critical on {{ $labels.instance }}: {{ $value }}% free"

      - alert: HighDiskIO
        expr: rate(node_disk_io_time_seconds_total[5m]) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk {{ $labels.device }} near saturation on {{ $labels.instance }}"

      - alert: NetworkErrors
        expr: rate(node_network_receive_errs_total[5m]) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Network errors on {{ $labels.instance }}"
```

### Node Exporter Installation

```bash
# monitoring/node-exporter/node-exporter.sh
#!/bin/bash
set -euo pipefail

NODE_EXPORTER_VERSION="1.7.0"
ARCH="linux-amd64"

wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

# Create system user
useradd -r -s /usr/sbin/nologin node_exporter

# systemd unit
cat > /etc/systemd/system/node-exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes \
  --collector.interrupts \
  --collector.perf \
  --web.listen-address=:9100

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node-exporter
echo "Node Exporter running on :9100"
```


# Node Exporter

Host metrics for Prometheus.

---

## Files

- [node-exporter.sh](node-exporter.sh)

---

## Usage

Install on every server:

```bash
sudo bash monitoring/node-exporter/node-exporter.sh
# Installs as a systemd service on :9100
# Includes the textfile collector for custom metrics
# Adds a backup success metric automatically
```

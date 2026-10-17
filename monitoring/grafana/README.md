# Grafana

Dashboards.

---

## Files

- [dashboard.json](dashboard.json)

---

## Usage

Import `dashboard.json`: Grafana → Dashboards → Import → Upload JSON.

- Panels: CPU%, memory%, disk%, network I/O, load average, disk I/O util, uptime
- Variables: instance (multi-select, auto-populated from Prometheus)

Setup of Prometheus + Grafana is covered in [monitoring/prometheus](../prometheus/).

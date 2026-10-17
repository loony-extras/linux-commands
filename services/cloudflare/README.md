# Cloudflare

Tunnels, Zero Trust access, Workers/Pages and the Cloudflare API from the command line.

---

## Files

- [examples.sh](examples.sh): annotated `cloudflared`, `wrangler` and API (curl) commands
- [tunnel-config.yml](tunnel-config.yml): `/etc/cloudflared/config.yml` template with common ingress rules
- [cf-ddns.sh](cf-ddns.sh): dynamic DNS, keeps an A/AAAA record on this host's public IP
- [cf-ddns.service](cf-ddns.service), [cf-ddns.timer](cf-ddns.timer), [cf-ddns.env.example](cf-ddns.env.example): run it every 5 minutes
- [cloudflare-ips.sh](cloudflare-ips.sh): nginx real-IP config and origin lockdown (nftables/UFW) from Cloudflare's IP ranges

---

## The Three Tools

| Tool | What it's for | Install |
|------|---------------|---------|
| `cloudflared` | Tunnels (expose services without open ports), Access for SSH/TCP/HTTP | apt repo or `.deb` (see examples.sh) |
| `wrangler` | Workers, Pages, KV, R2, D1, Queues, secrets, logs | `npm install -D wrangler` |
| API + `curl`/`jq` | DNS, cache, zone settings, WAF rules, analytics | Nothing; create an API token |

API tokens: dash → My Profile → API Tokens → Create Token. Scope each token to one zone and
the minimum permissions (e.g. `Zone:DNS:Edit` + `Zone:Zone:Read` for DDNS, `Zone:Cache Purge`
for deploy scripts). Keep tokens in `0600` files, not in shell history.

---

## Usage

### Cloudflare Tunnel (locally-managed)

```bash
cloudflared tunnel login
cloudflared tunnel create myapp                 # note the <UUID>
cloudflared tunnel route dns myapp app.example.com

sudo mkdir -p /etc/cloudflared
sudo cp services/cloudflare/tunnel-config.yml /etc/cloudflared/config.yml   # set <UUID>
sudo cp ~/.cloudflared/<UUID>.json /etc/cloudflared/
cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate
sudo cloudflared service install
sudo systemctl status cloudflared
```

Once the tunnel works, close inbound 80/443 entirely (see [networking/firewall](../../networking/firewall/)):
the tunnel only makes outbound connections.

### Dynamic DNS

```bash
sudo cp services/cloudflare/cf-ddns.sh /usr/local/bin/cf-ddns.sh
sudo chmod 755 /usr/local/bin/cf-ddns.sh
sudo cp services/cloudflare/cf-ddns.env.example /etc/cf-ddns.env
sudo chmod 600 /etc/cf-ddns.env && sudoedit /etc/cf-ddns.env      # token, zone, record
sudo cp services/cloudflare/cf-ddns.service services/cloudflare/cf-ddns.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cf-ddns.timer
journalctl -u cf-ddns -n 20                                         # check the first run
```

The script creates the record if missing, updates it only when the IP changes, and fails
with Cloudflare's error message otherwise. The service runs as a throwaway unprivileged user.

### Real client IPs and origin lockdown

When a site is proxied (orange cloud), nginx sees Cloudflare's IPs, not visitors'.

```bash
bash services/cloudflare/cloudflare-ips.sh --list                  # current ranges
sudo bash services/cloudflare/cloudflare-ips.sh --nginx            # → /etc/nginx/conf.d/cloudflare-real-ip.conf
sudo nginx -t && sudo systemctl reload nginx

# Only accept HTTP/HTTPS from Cloudflare (stops attackers bypassing the proxy/WAF)
sudo bash services/cloudflare/cloudflare-ips.sh --nftables --dry-run   # review first
sudo bash services/cloudflare/cloudflare-ips.sh --nftables && sudo nft -f /etc/nftables.d/cloudflare.nft
# or, with UFW:
sudo bash services/cloudflare/cloudflare-ips.sh --ufw
```

`PORTS=80,443,8443` overrides the restricted ports. Re-run weekly (ranges change rarely),
for example from cron: `0 4 * * 1 root /path/to/cloudflare-ips.sh --nginx && systemctl reload nginx`.

---

## Workers project config (wrangler.jsonc)

```jsonc
{
  "name": "my-worker",
  "main": "src/index.ts",
  "compatibility_date": "2026-10-01",
  "routes": [{ "pattern": "api.example.com/*", "zone_name": "example.com" }],
  "vars": { "LOG_LEVEL": "info" },                      // plain-text; secrets via `wrangler secret put`
  "kv_namespaces": [{ "binding": "CACHE", "id": "<namespace-id>" }],
  "r2_buckets": [{ "binding": "ASSETS", "bucket_name": "assets" }],
  "d1_databases": [{ "binding": "DB", "database_name": "appdb", "database_id": "<uuid>" }],
  "triggers": { "crons": ["*/15 * * * *"] },
  "env": {
    "staging": { "name": "my-worker-staging", "routes": [] } // wrangler deploy -e staging
  }
}
```

`wrangler kv namespace create`, `wrangler d1 create` and similar commands print the exact
binding block to paste in.

---

## Security Checklist

- SSL/TLS mode **Full (strict)** with a valid origin certificate (a Cloudflare Origin CA cert is fine); never "Flexible".
- Lock the origin to Cloudflare IPs (`cloudflare-ips.sh`) or use a tunnel with no inbound ports.
- Restore real client IPs (`--nginx`) so logs, rate limits and [fail2ban](../../security/fail2ban/) see visitors, not Cloudflare.
- Put admin panels, SSH and internal tools behind **Cloudflare Access** rather than exposing them.
- Use scoped API tokens per task; rotate them; never use the Global API Key in scripts.
- Incident mode: `security_level=under_attack` (examples.sh), then revert when traffic is normal.

See also: [networking/dns](../../networking/dns/), [networking/firewall](../../networking/firewall/), [networking/ssh](../../networking/ssh/).

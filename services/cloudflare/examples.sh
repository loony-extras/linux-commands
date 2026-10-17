#!/usr/bin/env bash
# =============================================================================
# Cloudflare — annotated command examples (cloudflared, wrangler, API)
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# Checked against cloudflared 2026.10.1 and wrangler 4.151.1.
# =============================================================================

# ---------------------------------------------------------------------------
### cloudflared — install and update
# ---------------------------------------------------------------------------
# Debian/Ubuntu apt repository (gets updates with apt upgrade)
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
  | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
  | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared

# Single .deb from GitHub releases (amd64; use arm64 on ARM)
curl -fsSL -o cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb

cloudflared --version                   # Print version
cloudflared update                      # Self-update (binary installs only; apt installs use apt)

# ---------------------------------------------------------------------------
### cloudflared tunnel — create, route and run (locally-managed)
# ---------------------------------------------------------------------------
# A tunnel makes an outbound-only connection to Cloudflare: no open inbound ports.
cloudflared tunnel login                # Browser auth; writes ~/.cloudflared/cert.pem
cloudflared tunnel create myapp         # Creates tunnel + ~/.cloudflared/<UUID>.json credentials
cloudflared tunnel list                 # All tunnels in the account
cloudflared tunnel route dns myapp app.example.com     # CNAME app.example.com → <UUID>.cfargotunnel.com
cloudflared tunnel route dns -f myapp app.example.com  # Overwrite an existing DNS record
cloudflared tunnel run myapp            # Run using ~/.cloudflared/config.yml
cloudflared tunnel --config /etc/cloudflared/config.yml run myapp   # Explicit config file
cloudflared tunnel run --url http://localhost:8080 myapp            # Single service, no config file

# Ingress rules (config.yml) — see tunnel-config.yml in this folder
cloudflared tunnel ingress validate                             # Check ingress rules in config.yml
cloudflared tunnel --config tunnel-config.yml ingress validate  # Check a specific file
cloudflared tunnel ingress rule https://app.example.com/api     # Which rule matches this URL?

# Clean up
cloudflared tunnel cleanup myapp        # Drop stale connector connections
cloudflared tunnel delete myapp         # Delete tunnel (must have no active connections)
cloudflared tunnel delete -f myapp      # Force: clean up connections, then delete

# ---------------------------------------------------------------------------
### cloudflared tunnel — tokens and quick tunnels
# ---------------------------------------------------------------------------
# Remotely-managed tunnels are configured in the dashboard (Zero Trust → Networks → Tunnels);
# the server only needs the token.
cloudflared tunnel token myapp                          # Print the run token for an existing tunnel
cloudflared tunnel run --token "$TUNNEL_TOKEN"          # Run with a token
cloudflared tunnel run --token-file /etc/cloudflared/token   # Keep the token out of `ps` output

# Quick tunnel: random *.trycloudflare.com URL, no account needed (testing only)
cloudflared tunnel --url http://localhost:3000
cloudflared tunnel --hello-world        # Built-in test server behind a quick tunnel

# ---------------------------------------------------------------------------
### cloudflared tunnel — private networks (WARP routing)
# ---------------------------------------------------------------------------
# Expose a private subnet to WARP-enrolled devices instead of public hostnames.
cloudflared tunnel route ip add 10.0.0.0/24 myapp "office LAN"   # CIDR, tunnel, comment
cloudflared tunnel route ip show                    # Routing table
cloudflared tunnel route ip get 10.0.0.15           # Which route matches this IP?
cloudflared tunnel route ip delete 10.0.0.0/24
cloudflared tunnel vnet add staging-net             # Virtual network (for overlapping CIDRs)
cloudflared tunnel vnet list

# ---------------------------------------------------------------------------
### cloudflared tunnel — inspect and debug
# ---------------------------------------------------------------------------
cloudflared tunnel info myapp           # Active connectors, versions, edge locations
cloudflared tunnel list -o json | jq '.[] | {name, id}'
cloudflared tunnel run --loglevel debug myapp       # Verbose (logs headers: don't leave on)
cloudflared tunnel --metrics localhost:2000 run myapp   # Prometheus metrics on :2000/metrics
cloudflared tunnel --metrics localhost:2000 ready   # Exit 0 if the local connector is ready
cloudflared tunnel diag                 # Build a diagnostic bundle from a running local instance
cloudflared tail myapp                  # Stream logs from a remote cloudflared (by tunnel name/ID)
journalctl -u cloudflared -f            # Logs when running as a service

# ---------------------------------------------------------------------------
### cloudflared service — run as a systemd service
# ---------------------------------------------------------------------------
# Locally-managed: copy config + credentials to /etc/cloudflared, then install
sudo mkdir -p /etc/cloudflared
sudo cp ~/.cloudflared/config.yml ~/.cloudflared/<UUID>.json /etc/cloudflared/
sudo cloudflared service install        # Creates cloudflared.service using /etc/cloudflared/config.yml

# Remotely-managed: install with the token
sudo cloudflared service install "$TUNNEL_TOKEN"

sudo systemctl status cloudflared
sudo systemctl restart cloudflared      # After editing config.yml
sudo cloudflared service uninstall

# ---------------------------------------------------------------------------
### cloudflared access — SSH, TCP and Access-protected apps
# ---------------------------------------------------------------------------
# SSH through a tunnel (ingress: service: ssh://localhost:22) with Cloudflare Access login
cloudflared access ssh-config --hostname ssh.example.com    # Print the ~/.ssh/config block
cloudflared access ssh-config --hostname ssh.example.com --short-lived-cert
# ~/.ssh/config:
#   Host ssh.example.com
#     ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
ssh user@ssh.example.com

# Arbitrary TCP (databases, RDP, …): local listener → Cloudflare → tunnel → origin
cloudflared access tcp --hostname db.example.com --url localhost:5432
psql -h localhost -p 5432 -U app appdb  # In another terminal
cloudflared access rdp --hostname rdp.example.com --url localhost:3389

# HTTP apps behind Access
cloudflared access login https://app.example.com       # Browser login, caches a JWT
cloudflared access token --app=https://app.example.com # Print the cached JWT
cloudflared access curl https://app.example.com/api/health  # curl with the JWT attached

# Non-interactive (CI/cron): Access service token
cloudflared access tcp --hostname db.example.com --url localhost:5432 \
  --service-token-id "$CF_ACCESS_CLIENT_ID" --service-token-secret "$CF_ACCESS_CLIENT_SECRET"
curl -H "CF-Access-Client-Id: $CF_ACCESS_CLIENT_ID" \
     -H "CF-Access-Client-Secret: $CF_ACCESS_CLIENT_SECRET" https://app.example.com/api

# ---------------------------------------------------------------------------
### wrangler — install, auth and project setup
# ---------------------------------------------------------------------------
npm create cloudflare@latest my-worker  # Scaffold a Worker/Pages project (C3)
npm install -D wrangler@latest          # Pin wrangler per project
npx wrangler --version

npx wrangler login                      # OAuth in the browser
npx wrangler whoami                     # Account(s) and token scopes
npx wrangler logout
npx wrangler auth token                 # Print the current auth token
export CLOUDFLARE_API_TOKEN=...         # CI: API token instead of login
export CLOUDFLARE_ACCOUNT_ID=...        # CI: skip the account prompt

npx wrangler types                      # Generate TypeScript types for bindings
npx wrangler docs d1                    # Open docs for a command

# ---------------------------------------------------------------------------
### wrangler — Workers: dev, deploy, versions, rollback
# ---------------------------------------------------------------------------
npx wrangler dev                        # Local dev server on :8787 (local bindings)
npx wrangler dev --port 9000 --ip 0.0.0.0
npx wrangler dev --test-scheduled       # Trigger cron handlers at /__scheduled
npx wrangler dev --tunnel               # Share the dev server via a quick tunnel

npx wrangler deploy                     # Build + deploy to production
npx wrangler deploy -e staging          # Use [env.staging] from the config
npx wrangler deploy --dry-run --outdir dist   # Build only, inspect the bundle
npx wrangler deploy --message "fix cache headers"

# Gradual rollouts: upload a version, then split traffic
npx wrangler versions upload --message "v2"
npx wrangler versions list
npx wrangler versions deploy <new-version-id>@10% <old-version-id>@90%
npx wrangler deployments list           # Recent deployments
npx wrangler deployments status         # What's live now
npx wrangler rollback                   # Roll back to the previous version
npx wrangler rollback <version-id> --message "bad release"

npx wrangler delete my-worker           # Delete the Worker

# ---------------------------------------------------------------------------
### wrangler — secrets and live logs
# ---------------------------------------------------------------------------
npx wrangler secret put API_KEY         # Prompted for the value (or pipe it in)
echo -n "$API_KEY" | npx wrangler secret put API_KEY
npx wrangler secret list
npx wrangler secret delete API_KEY
npx wrangler secret bulk secrets.json   # {"KEY": "value", "OLD_KEY": null} — null deletes
# Local dev secrets: put KEY=value lines in .dev.vars (never commit it)

npx wrangler tail                       # Live logs from the deployed Worker
npx wrangler tail my-worker --format json | jq .
npx wrangler tail --status error        # Only failed invocations
npx wrangler tail --search "timeout" --ip self

# ---------------------------------------------------------------------------
### wrangler kv — Workers KV
# ---------------------------------------------------------------------------
# Key commands default to local storage in wrangler v4: add --remote for production data.
npx wrangler kv namespace create CACHE  # Prints the binding block for the config
npx wrangler kv namespace list
npx wrangler kv key put --binding=CACHE "greeting" "hello" --remote
npx wrangler kv key put --binding=CACHE "page" --path=./page.html --remote
npx wrangler kv key put --binding=CACHE "session" "x" --ttl=3600 --remote   # Expires in 1h
npx wrangler kv key get --binding=CACHE "greeting" --remote
npx wrangler kv key list --binding=CACHE --remote | jq -r '.[].name'
npx wrangler kv key delete --binding=CACHE "greeting" --remote
npx wrangler kv bulk put --binding=CACHE data.json --remote   # [{"key":"k","value":"v"}, …]
npx wrangler kv namespace delete --binding=CACHE

# ---------------------------------------------------------------------------
### wrangler r2 — R2 object storage
# ---------------------------------------------------------------------------
# Object commands default to local storage in wrangler v4: add --remote.
npx wrangler r2 bucket create assets
npx wrangler r2 bucket list
npx wrangler r2 bucket info assets
npx wrangler r2 object put assets/img/logo.png --file=./logo.png --content-type=image/png --remote
npx wrangler r2 object get assets/img/logo.png --file=./logo.png --remote
npx wrangler r2 object delete assets/img/logo.png --remote
npx wrangler r2 bucket dev-url enable assets            # Public r2.dev URL (testing)
npx wrangler r2 bucket domain add assets --domain cdn.example.com --zone-id "$CF_ZONE_ID"
npx wrangler r2 bucket delete assets
# R2 is also S3-compatible: aws s3 --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com ...

# ---------------------------------------------------------------------------
### wrangler d1 — D1 SQL databases
# ---------------------------------------------------------------------------
npx wrangler d1 create appdb            # Prints the binding block for the config
npx wrangler d1 list
npx wrangler d1 info appdb
npx wrangler d1 execute appdb --remote --command "SELECT name FROM sqlite_master WHERE type='table'"
npx wrangler d1 execute appdb --remote --file=./schema.sql
npx wrangler d1 execute appdb --local --command "SELECT count(*) FROM users"   # wrangler dev DB
npx wrangler d1 migrations create appdb add_users_table   # → migrations/0001_add_users_table.sql
npx wrangler d1 migrations list appdb --remote
npx wrangler d1 migrations apply appdb --remote
npx wrangler d1 export appdb --remote --output=backup.sql
npx wrangler d1 export appdb --remote --no-data --output=schema.sql
npx wrangler d1 time-travel info appdb  # Point-in-time restore bookmarks

# ---------------------------------------------------------------------------
### wrangler pages — Cloudflare Pages
# ---------------------------------------------------------------------------
npx wrangler pages project create my-site --production-branch=main
npx wrangler pages project list
npx wrangler pages deploy ./dist --project-name=my-site                  # Production
npx wrangler pages deploy ./dist --project-name=my-site --branch=preview # Preview URL
npx wrangler pages deployment list --project-name=my-site
npx wrangler pages dev ./dist           # Serve locally with Pages Functions
npx wrangler pages secret put API_KEY --project-name=my-site

# ---------------------------------------------------------------------------
### wrangler queues and hyperdrive
# ---------------------------------------------------------------------------
npx wrangler queues create jobs
npx wrangler queues list
npx wrangler queues info jobs
npx wrangler queues purge jobs          # Drop all pending messages
npx wrangler hyperdrive create pg --connection-string="postgres://user:pass@db.example.com:5432/app"
npx wrangler hyperdrive list

# ---------------------------------------------------------------------------
### Cloudflare API — auth and lookups (curl + jq)
# ---------------------------------------------------------------------------
# Create a scoped API token: dash → My Profile → API Tokens. Prefer tokens over the global key.
export CF_API_TOKEN=...                 # Never commit; load from a 0600 file
API=https://api.cloudflare.com/client/v4
cf() { curl -sS -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" "$@"; }

cf "$API/user/tokens/verify" | jq '.result.status'                 # "active"
cf "$API/accounts" | jq -r '.result[] | "\(.id)  \(.name)"'
cf "$API/zones?per_page=50" | jq -r '.result[] | "\(.id)  \(.name)  \(.status)"'
ZONE_ID=$(cf "$API/zones?name=example.com" | jq -r '.result[0].id')
# Errors come back as {"success":false,"errors":[{"code":…,"message":…}]}
cf "$API/zones/$ZONE_ID" | jq '.success, .errors'

# ---------------------------------------------------------------------------
### Cloudflare API — DNS records
# ---------------------------------------------------------------------------
cf "$API/zones/$ZONE_ID/dns_records?per_page=100" \
  | jq -r '.result[] | [.type, .name, .content, (.proxied|tostring)] | @tsv' | column -t
cf "$API/zones/$ZONE_ID/dns_records?type=A&name=app.example.com" | jq '.result[0]'

# Create (ttl 1 = automatic; proxied true = orange cloud)
cf -X POST "$API/zones/$ZONE_ID/dns_records" \
  --data '{"type":"A","name":"app.example.com","content":"203.0.113.10","ttl":1,"proxied":true}'
cf -X POST "$API/zones/$ZONE_ID/dns_records" \
  --data '{"type":"CNAME","name":"www","content":"example.com","proxied":true}'
cf -X POST "$API/zones/$ZONE_ID/dns_records" \
  --data '{"type":"MX","name":"example.com","content":"mail.example.com","priority":10}'
cf -X POST "$API/zones/$ZONE_ID/dns_records" \
  --data '{"type":"TXT","name":"example.com","content":"\"v=spf1 include:_spf.example.net -all\""}'

# Update / delete by record ID
REC_ID=$(cf "$API/zones/$ZONE_ID/dns_records?type=A&name=app.example.com" | jq -r '.result[0].id')
cf -X PATCH "$API/zones/$ZONE_ID/dns_records/$REC_ID" --data '{"content":"203.0.113.20"}'
cf -X PATCH "$API/zones/$ZONE_ID/dns_records/$REC_ID" --data '{"proxied":false}'
cf -X DELETE "$API/zones/$ZONE_ID/dns_records/$REC_ID"

# Export / import a BIND zone file
cf "$API/zones/$ZONE_ID/dns_records/export" > example.com.zone
curl -sS -H "Authorization: Bearer $CF_API_TOKEN" -X POST \
  "$API/zones/$ZONE_ID/dns_records/import" -F "file=@example.com.zone" -F "proxied=false"

# Dynamic DNS for a home server: see cf-ddns.sh in this folder

# ---------------------------------------------------------------------------
### Cloudflare API — cache purge and zone settings
# ---------------------------------------------------------------------------
cf -X POST "$API/zones/$ZONE_ID/purge_cache" --data '{"purge_everything":true}'
cf -X POST "$API/zones/$ZONE_ID/purge_cache" \
  --data '{"files":["https://example.com/app.js","https://example.com/style.css"]}'
cf -X POST "$API/zones/$ZONE_ID/purge_cache" --data '{"prefixes":["example.com/blog/"]}'
cf -X POST "$API/zones/$ZONE_ID/purge_cache" --data '{"hosts":["static.example.com"]}'

cf "$API/zones/$ZONE_ID/settings" | jq -r '.result[] | "\(.id)=\(.value|tostring)"'
cf -X PATCH "$API/zones/$ZONE_ID/settings/ssl" --data '{"value":"strict"}'              # Full (strict)
cf -X PATCH "$API/zones/$ZONE_ID/settings/always_use_https" --data '{"value":"on"}'
cf -X PATCH "$API/zones/$ZONE_ID/settings/min_tls_version" --data '{"value":"1.2"}'
cf -X PATCH "$API/zones/$ZONE_ID/settings/development_mode" --data '{"value":"on"}'      # Bypass cache 3h
cf -X PATCH "$API/zones/$ZONE_ID/settings/security_level" --data '{"value":"under_attack"}'  # Incident mode
cf -X PATCH "$API/zones/$ZONE_ID/settings/security_level" --data '{"value":"medium"}'        # Back to normal

# ---------------------------------------------------------------------------
### Cloudflare API — WAF custom rules and IP access rules
# ---------------------------------------------------------------------------
# Custom rules live in the http_request_firewall_custom phase ruleset.
cf "$API/zones/$ZONE_ID/rulesets/phases/http_request_firewall_custom/entrypoint" \
  | jq '.result.rules[] | {id, description, action, expression}'
# PUT replaces ALL custom rules in the zone: include existing ones you want to keep.
cf -X PUT "$API/zones/$ZONE_ID/rulesets/phases/http_request_firewall_custom/entrypoint" --data '{
  "rules": [
    {"description": "Block admin outside office",
     "expression": "(http.request.uri.path starts_with \"/wp-admin\" and ip.src ne 203.0.113.0/24)",
     "action": "block"},
    {"description": "Challenge non-EU on login",
     "expression": "(http.request.uri.path eq \"/login\" and not ip.src.continent in {\"EU\"})",
     "action": "managed_challenge"}
  ]}'

# IP access rules: quick allow/block/challenge by IP, range, ASN or country
cf -X POST "$API/zones/$ZONE_ID/firewall/access_rules/rules" \
  --data '{"mode":"block","configuration":{"target":"ip","value":"198.51.100.7"},"notes":"scraper"}'
cf -X POST "$API/zones/$ZONE_ID/firewall/access_rules/rules" \
  --data '{"mode":"challenge","configuration":{"target":"country","value":"XX"},"notes":"abuse"}'
cf "$API/zones/$ZONE_ID/firewall/access_rules/rules" | jq -r '.result[] | "\(.id) \(.mode) \(.configuration.value)"'
cf -X DELETE "$API/zones/$ZONE_ID/firewall/access_rules/rules/<rule-id>"

# ---------------------------------------------------------------------------
### Cloudflare API — tunnels, IP ranges and analytics
# ---------------------------------------------------------------------------
ACCOUNT_ID=$(cf "$API/accounts" | jq -r '.result[0].id')
cf "$API/accounts/$ACCOUNT_ID/cfd_tunnel?is_deleted=false" | jq -r '.result[] | "\(.id) \(.name) \(.status)"'

# Cloudflare edge IP ranges (no auth). Use them to trust CF-Connecting-IP or lock down
# the origin: see cloudflare-ips.sh in this folder.
curl -sS "$API/ips" | jq -r '.result.ipv4_cidrs[], .result.ipv6_cidrs[]'
curl -sS https://www.cloudflare.com/ips-v4

# What IP/colo does Cloudflare see for me?
curl -sS https://cloudflare.com/cdn-cgi/trace       # ip=, colo=, tls=, warp=

# GraphQL analytics: requests per day for the last 7 days
cf -X POST "$API/graphql" --data "$(jq -n --arg z "$ZONE_ID" --arg d "$(date -u -d '7 days ago' +%F)" '{
  query: "query($z: String!, $d: Date!) { viewer { zones(filter: {zoneTag: $z}) {
            httpRequests1dGroups(limit: 7, filter: {date_geq: $d}) {
              dimensions { date } sum { requests cachedRequests threats } } } } }",
  variables: {z: $z, d: $d}}')" | jq '.data.viewer.zones[0].httpRequests1dGroups'

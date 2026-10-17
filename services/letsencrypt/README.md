# Let's Encrypt

Free, automated TLS certificates with certbot or acme.sh, plus renewal hooks and expiry monitoring.

---

## Files

- [examples.sh](examples.sh): annotated certbot, acme.sh and openssl commands
- [nginx-ssl.conf](nginx-ssl.conf): nginx site with the ACME webroot, HTTP→HTTPS redirect and Mozilla "intermediate" TLS
- [deploy-hook.sh](deploy-hook.sh): certbot deploy hook; tests config, then reloads nginx/apache/haproxy/postfix/dovecot
- [cert-expiry-check.sh](cert-expiry-check.sh): days-left check for hosts and cert files, with webhook alerts
- [cloudflare.ini.example](cloudflare.ini.example): credentials for the dns-cloudflare plugin (wildcards)

---

## Choosing a Challenge

| Challenge | Use when | Needs |
|-----------|----------|-------|
| HTTP-01 `--webroot` | A web server already runs on port 80 | Port 80 reachable from the internet |
| HTTP-01 `--nginx` | You want certbot to edit nginx for you | nginx plugin, port 80 |
| HTTP-01 `--standalone` | No web server (mail server, API on another port) | Port 80 free during issuance |
| DNS-01 `--dns-cloudflare` | Wildcards, internal hosts, or port 80 is blocked | DNS provider API token |

Webroot is the most predictable for servers you manage by hand or with Ansible: certbot never
touches the nginx config, and renewals work while nginx is running.

---

## Usage

### First certificate (nginx + webroot)

```bash
sudo apt install certbot
sudo mkdir -p /var/www/letsencrypt
sudo cp services/letsencrypt/nginx-ssl.conf /etc/nginx/sites-available/example.com
# edit server_name/paths; comment out the 443 server until the cert exists
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com -d www.example.com \
  --dry-run                                                         # staging test, nothing saved
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com -d www.example.com \
  -m admin@example.com --agree-tos --no-eff-email                   # the real certificate

# enable the 443 server block, then:
sudo nginx -t && sudo systemctl reload nginx
```

### Wildcard certificate (Cloudflare DNS)

```bash
sudo apt install python3-certbot-dns-cloudflare
sudo install -m 600 services/letsencrypt/cloudflare.ini.example /etc/letsencrypt/cloudflare.ini
sudoedit /etc/letsencrypt/cloudflare.ini                           # token with Zone:DNS:Edit
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d example.com -d '*.example.com'
```

The same token setup is described in [services/cloudflare](../cloudflare/).

### Reload services on renewal

```bash
sudo install -m 755 services/letsencrypt/deploy-hook.sh /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh
sudo certbot renew --dry-run --run-deploy-hooks                    # exercise renewal + hook
```

For each running service the hook tests the config first (`nginx -t`, `haproxy -c`, ...) and
only reloads if it passes, so a broken config never takes the site down. HAProxy gets a
combined `fullchain + key` PEM in `/etc/haproxy/certs/<name>.pem`. Limit the services with
`SERVICES="nginx"` in the environment if needed.

### Monitor expiry

Let's Encrypt no longer emails expiry warnings, so check yourself:

```bash
bash services/letsencrypt/cert-expiry-check.sh example.com mail.example.com:465 /etc/letsencrypt/live
#   OK        63  example.com          expires 2026-12-19
#   WARN      12  mail.example.com:465 expires 2026-10-29
# exit 0 = OK, 1 = warning, 2 = critical/unreachable

# Daily, alert a Slack/Mattermost/Discord-compatible webhook only when something is wrong
0 8 * * * /usr/local/bin/cert-expiry-check.sh --quiet --webhook https://hooks.example.com/xyz example.com /etc/letsencrypt/live
```

Remote checks also catch the cases where renewal succeeded but the server still serves the old
certificate (missing reload), a hostname mismatch or a broken chain.

---

## Good to Know

- **Rate limits:** test with `--test-cert` / `--dry-run`. Production allows 5 certificates for
  the same set of names per week; hitting it means waiting.
- **Lifetimes are shrinking:** certificates are 90 days today and Let's Encrypt is moving to
  shorter ones (`shortlived` profile: about 6 days). Renewal must be fully automatic,
  with reload hooks; never copy certificates around by hand.
- **No OCSP:** Let's Encrypt ended OCSP in 2025. Don't configure `ssl_stapling` or `--must-staple`.
- **CAA records** limit which CAs may issue for your domain (see examples.sh).
- **Private keys** in `/etc/letsencrypt/live/*/privkey.pem` are root-only. Services that drop
  privileges read them at startup as root, or via a group-readable copy made in a deploy hook.
- **Behind Cloudflare** (orange cloud): HTTP-01 still works through the proxy; or use DNS-01,
  or a Cloudflare Origin CA certificate for the origin and skip Let's Encrypt there.

See also: [services/cloudflare](../cloudflare/), [networking/firewall](../../networking/firewall/), [monitoring/prometheus](../../monitoring/prometheus/).

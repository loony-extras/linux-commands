#!/usr/bin/env bash
# =============================================================================
# Let's Encrypt — annotated command examples (certbot, acme.sh, openssl checks)
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# Checked against certbot 5.8.0 and acme.sh 3.1.7.
# =============================================================================

# ---------------------------------------------------------------------------
### certbot — install
# ---------------------------------------------------------------------------
sudo apt install certbot python3-certbot-nginx          # Distro package + nginx plugin
sudo apt install python3-certbot-dns-cloudflare         # DNS plugin for wildcards via Cloudflare

# Or the snap (newest certbot; recommended upstream)
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo snap set certbot trust-plugin-with-root=ok
sudo snap install certbot-dns-cloudflare

certbot --version
certbot plugins                                         # Installed authenticators/installers

# ---------------------------------------------------------------------------
### certbot — get a certificate (HTTP-01)
# ---------------------------------------------------------------------------
# nginx plugin: validates AND edits the nginx server block for you
sudo certbot --nginx -d example.com -d www.example.com
sudo certbot --nginx -d example.com --redirect          # Also add the HTTP→HTTPS redirect

# webroot: nginx keeps running and serves /.well-known/acme-challenge/ (see nginx-ssl.conf)
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com -d www.example.com

# standalone: certbot binds :80 itself (stop the web server, or use hooks)
sudo certbot certonly --standalone -d example.com \
  --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx"

# Non-interactive (scripts, Ansible): agree to ToS, set email, no prompts
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com \
  -n --agree-tos -m admin@example.com --no-eff-email

# Files land in /etc/letsencrypt/live/<cert-name>/:
#   fullchain.pem  → ssl_certificate      privkey.pem → ssl_certificate_key
#   chain.pem      → intermediate only    cert.pem    → leaf only (rarely what you want)

# ---------------------------------------------------------------------------
### certbot — wildcard and DNS-01 certificates
# ---------------------------------------------------------------------------
# Wildcards need DNS-01. Cloudflare plugin: token with Zone:DNS:Edit (see cloudflare.ini.example)
sudo install -m 600 cloudflare.ini.example /etc/letsencrypt/cloudflare.ini   # then fill in the token
sudo certbot certonly --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  -d example.com -d '*.example.com'

# DNS-01 also works for hosts that are not reachable from the internet (internal services)
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d grafana.internal.example.com

# Manual DNS (no API): certbot prints a TXT record to create — cannot auto-renew
sudo certbot certonly --manual --preferred-challenges dns -d '*.example.com'
dig +short TXT _acme-challenge.example.com              # Check the record before continuing

# ---------------------------------------------------------------------------
### certbot — test safely (staging and dry runs)
# ---------------------------------------------------------------------------
# Production has rate limits (e.g. 5 duplicate certs/week). Test against staging first.
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com --test-cert   # Untrusted cert
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com --dry-run     # Nothing saved
sudo certbot renew --dry-run                             # Simulate renewal of every cert
sudo certbot renew --dry-run --run-deploy-hooks          # …and run deploy hooks too

# ---------------------------------------------------------------------------
### certbot — renewal and hooks
# ---------------------------------------------------------------------------
# Packages install a timer that runs `certbot renew` twice a day. A cert is renewed when about a
# third of its lifetime is left (30 days for 90-day certs), or earlier if the CA asks for it.
systemctl list-timers | grep -E 'certbot|snap.certbot'
sudo certbot renew                                       # Renew everything that is due
sudo certbot renew --cert-name example.com --force-renewal   # Renew one now (rate limits apply)
journalctl -u certbot.service --since -7d                # Renewal logs (apt package)
less /var/log/letsencrypt/letsencrypt.log

# Hook directories run for every cert (scripts must be executable):
#   /etc/letsencrypt/renewal-hooks/pre/     before any renewal attempt
#   /etc/letsencrypt/renewal-hooks/deploy/  after EACH successful renewal ($RENEWED_LINEAGE set)
#   /etc/letsencrypt/renewal-hooks/post/    after all renewal attempts
sudo install -m 755 deploy-hook.sh /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh

# Per-cert hook, saved into /etc/letsencrypt/renewal/<cert-name>.conf
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com \
  --deploy-hook "systemctl reload nginx"

# ---------------------------------------------------------------------------
### certbot — manage certificates
# ---------------------------------------------------------------------------
sudo certbot certificates                                # Names, domains, expiry, paths
sudo certbot certonly --webroot -w /var/www/letsencrypt --cert-name example.com \
  -d example.com -d www.example.com -d api.example.com   # Add a name (replaces the domain list)
sudo certbot certonly --nginx --cert-name example.com --expand -d example.com,www.example.com,api.example.com
sudo certbot reconfigure --cert-name example.com --deploy-hook "systemctl reload nginx"
sudo certbot delete --cert-name old.example.com          # Remove files + renewal config
sudo certbot revoke --cert-name example.com --reason keycompromise   # Key leaked
sudo certbot show_account

# Key type: ECDSA (default since certbot 2.0) or RSA for old clients
sudo certbot certonly --nginx -d example.com --key-type rsa --rsa-key-size 4096 --cert-name example.com-rsa

# ---------------------------------------------------------------------------
### certbot — profiles and IP address certificates
# ---------------------------------------------------------------------------
# Let's Encrypt profiles: classic (default), tlsserver, shortlived (~6-day certs).
curl -sS https://acme-v02.api.letsencrypt.org/directory | jq '.meta.profiles'
sudo certbot certonly --webroot -w /var/www/letsencrypt -d example.com --preferred-profile tlsserver
sudo certbot certonly --standalone --preferred-profile shortlived \
  --ip-address 203.0.113.10                              # Cert for a bare IP (shortlived only)
# Short-lived certs renew every few days: only use with fully automated renewal + reload hooks.
# Don't use --must-staple: Let's Encrypt ended OCSP in 2025.

# ---------------------------------------------------------------------------
### acme.sh — lightweight alternative (pure shell, many DNS APIs)
# ---------------------------------------------------------------------------
curl https://get.acme.sh | sh -s email=admin@example.com    # Installs to ~/.acme.sh + cron job
acme.sh --set-default-ca --server letsencrypt               # Default CA is ZeroSSL otherwise
acme.sh --issue -d example.com -d www.example.com -w /var/www/letsencrypt   # Webroot
acme.sh --issue -d example.com --standalone                 # Needs :80 free
export CF_Token=... CF_Zone_ID=...                          # Cloudflare DNS API token
acme.sh --issue --dns dns_cf -d example.com -d '*.example.com'
acme.sh --issue -d example.com -w /var/www/letsencrypt --staging   # Test first

# Copy certs to their final place and reload on every renewal (don't point nginx at ~/.acme.sh)
acme.sh --install-cert -d example.com --ecc \
  --key-file /etc/nginx/ssl/example.com.key \
  --fullchain-file /etc/nginx/ssl/example.com.crt \
  --reloadcmd "systemctl reload nginx"
acme.sh --list
acme.sh --renew -d example.com --ecc --force
acme.sh --revoke -d example.com --ecc
acme.sh --remove -d example.com --ecc                       # Stop renewing (files stay)
acme.sh --upgrade --auto-upgrade

# ---------------------------------------------------------------------------
### openssl — inspect and verify certificates
# ---------------------------------------------------------------------------
# Remote: what is the server actually serving? (-servername is required for SNI)
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null \
  | openssl x509 -noout -checkend $((14*86400)) && echo "valid >14 days" || echo "EXPIRES within 14 days"
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null   # Full chain
openssl s_client -connect example.com:443 -servername example.com -tls1_3 </dev/null      # TLS 1.3?

# Local files
sudo openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -noout -enddate -ext subjectAltName
sudo openssl verify -untrusted /etc/letsencrypt/live/example.com/chain.pem \
  /etc/letsencrypt/live/example.com/cert.pem
# Does the key match the cert? (works for RSA and ECDSA)
diff <(sudo openssl x509 -in fullchain.pem -noout -pubkey) <(sudo openssl pkey -in privkey.pem -pubout) && echo match

# Expiry checks for many hosts/files at once: see cert-expiry-check.sh in this folder

# ---------------------------------------------------------------------------
### DNS — CAA records and challenge troubleshooting
# ---------------------------------------------------------------------------
# CAA: only these CAs may issue for the domain (add one line per CA you use)
#   example.com.  CAA 0 issue "letsencrypt.org"
#   example.com.  CAA 0 issuewild "letsencrypt.org"
#   example.com.  CAA 0 iodef "mailto:security@example.com"
dig +short CAA example.com

# HTTP-01 failing? Check from outside that the challenge path is reachable over port 80
curl -sI http://example.com/.well-known/acme-challenge/test   # Expect 404 from YOUR server, not a redirect loop/timeout
dig +short A example.com && dig +short AAAA example.com       # A stale AAAA record is a common cause

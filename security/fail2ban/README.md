# fail2ban

Ban hosts after repeated failures.

---

## Files

- [jail.local](jail.local)

---

## Usage

`jail.local` deploys to `/etc/fail2ban/jail.local`: SSH (3 tries / 1h ban), nginx and
recidive (7-day ban for repeat offenders).

---

## fail2ban Setup

fail2ban monitors logs and bans IPs that show signs of brute-force attacks.

```bash
apt install -y fail2ban

# /etc/fail2ban/jail.local — override defaults (never edit jail.conf)
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban time (10 minutes)
bantime = 600
# Window to count failures in
findtime = 600
# Number of failures before ban
maxretry = 5
# Email alerts (configure sendmail/postfix)
destemail = admin@company.com
sendername = Fail2Ban
mta = sendmail
action = %(action_mwl)s      # Ban + email with log lines

# Backend to use for log monitoring
backend = systemd

# Ignore these IPs (management IPs, VPN ranges)
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 10.0.0.0/8

# ========================
# SERVICE-SPECIFIC JAILS
# ========================

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 3600              # 1 hour ban for SSH

[sshd-ddos]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 10
findtime = 10               # 10 attempts in 10 seconds = flood
bantime = 86400             # 24 hour ban

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[postfix]
enabled = true
port = smtp,465,submission
logpath = %(postfix_log)s

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s

[wordpress]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
filter = wordpress
EOF

systemctl enable --now fail2ban

# fail2ban management
fail2ban-client status                  # Overall status
fail2ban-client status sshd            # SSH jail status
fail2ban-client set sshd banip 1.2.3.4  # Manually ban
fail2ban-client set sshd unbanip 1.2.3.4  # Unban
fail2ban-client get sshd banlist       # List banned IPs
fail2ban-client reload                 # Reload config
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf  # Test filter
```


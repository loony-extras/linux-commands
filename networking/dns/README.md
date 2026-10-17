# DNS

Resolver and DNS server setup.

---

## DNS Setup

### /etc/resolv.conf

```bash
# /etc/resolv.conf (often managed by systemd-resolved or resolvconf)
cat > /etc/resolv.conf << 'EOF'
# Primary and fallback DNS
nameserver 1.1.1.1
nameserver 8.8.8.8
# Search domains (for short hostnames)
search internal.company.com company.com
# How many times to retry queries
options attempts:3
# Timeout per attempt
options timeout:2
# Only use first nameserver unless it fails
options rotate
EOF

# On Ubuntu with systemd-resolved:
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable --now systemd-resolved

# Query DNS
resolvectl status
resolvectl query google.com
resolvectl flush-caches

# DNS tools
dig google.com                         # Basic query
dig google.com A                       # Specific record type
dig google.com MX                      # Mail records
dig @8.8.8.8 google.com               # Use specific DNS server
dig +short google.com                  # Just the answer
dig +trace google.com                  # Full resolution path
dig -x 8.8.8.8                         # Reverse lookup (PTR)
nslookup google.com
host google.com
```

### Bind9 DNS Server (authoritative/recursive)

```bash
apt install -y bind9 bind9-utils

# /etc/bind/named.conf.options
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";

    # Only allow queries from local network
    allow-query { localhost; 192.168.0.0/24; };

    # Forward unknown queries to upstream DNS
    forwarders {
        1.1.1.1;
        8.8.8.8;
    };

    # Enable DNSSEC validation
    dnssec-validation auto;

    # Disable recursive queries from external (security)
    recursion yes;
    allow-recursion { localhost; 192.168.0.0/24; };

    listen-on port 53 { any; };
    listen-on-v6 { any; };
};
EOF

# Zone file example
cat > /etc/bind/db.internal.company.com << 'EOF'
$ORIGIN internal.company.com.
$TTL    3600

@       IN      SOA     ns1.internal.company.com. admin.company.com. (
                        2024010101  ; Serial (YYYYMMDDnn)
                        3600        ; Refresh
                        1800        ; Retry
                        604800      ; Expire
                        86400 )     ; Negative cache TTL

; Name servers
@       IN      NS      ns1.internal.company.com.

; A records
ns1     IN      A       192.168.1.10
web     IN      A       192.168.1.20
db      IN      A       192.168.1.30

; CNAME
www     IN      CNAME   web

; MX
@       IN      MX      10 mail.company.com.
EOF

systemctl enable --now bind9
named-checkconf                        # Validate configuration
named-checkzone internal.company.com /etc/bind/db.internal.company.com
```


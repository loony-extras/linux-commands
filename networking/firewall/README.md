# Firewall

UFW, nftables and iptables.

---

## Files

- [firewall-setup.sh](firewall-setup.sh)
- [iptables-rules.sh](iptables-rules.sh)
- [nftables.conf](nftables.conf)

---

## Usage

| File | Purpose |
|------|---------|
| `firewall-setup.sh` | nftables firewall with dynamic rate-limit sets, by profile |
| `nftables.conf` | Production ruleset: SSH rate-limit sets, HTTP flood protection, auto-block set |
| `iptables-rules.sh` | Legacy iptables equivalent; `--dry-run` previews without applying |

```bash
sudo bash networking/firewall/firewall-setup.sh --profile web --ssh-port 22
# Profiles:
# web     → SSH (rate-limited) + HTTP/HTTPS + node_exporter
# db      → SSH + PostgreSQL/MySQL/Redis (internal CIDR only) + node_exporter
# bastion → SSH only
# minimal → SSH only

# Apply the static nftables ruleset
sudo cp networking/firewall/nftables.conf /etc/nftables.conf
sudo nft -c -f /etc/nftables.conf    # validate
sudo systemctl restart nftables

# Legacy iptables
sudo bash networking/firewall/iptables-rules.sh --dry-run   # preview
sudo bash networking/firewall/iptables-rules.sh             # apply
```

---

## Firewall Configuration

### UFW (Uncomplicated Firewall) — Ubuntu default

```bash
# Enable UFW
ufw enable
ufw disable
ufw status verbose
ufw status numbered      # Show rules with numbers

# Default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny forward

# Allow rules
ufw allow ssh              # Allow SSH (port 22)
ufw allow 80/tcp           # Allow HTTP
ufw allow 443              # Allow HTTPS
ufw allow 8080:8090/tcp    # Port range
ufw allow from 192.168.1.0/24    # From subnet
ufw allow from 192.168.1.100 to any port 22  # Specific source to port

# Deny rules
ufw deny 23               # Block telnet
ufw deny from 1.2.3.4    # Block IP

# Delete rules
ufw delete allow 80/tcp
ufw delete 5              # Delete rule #5 (from ufw status numbered)

# Rate limiting (against brute force)
ufw limit ssh             # Allow but rate-limit SSH

# Logging
ufw logging on
ufw logging medium        # low, medium, high, full

# Reset
ufw reset

# App profiles (/etc/ufw/applications.d/)
ufw app list
ufw allow "Nginx Full"
ufw app info "Nginx Full"
```

### iptables — low-level packet filtering

```bash
# View rules
iptables -L -n -v                     # List all chains, verbose
iptables -L INPUT -n -v --line-numbers
iptables -t nat -L -n -v             # NAT table

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow established connections (essential — prevents lockout)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow specific ports
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow from subnet
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 5432 -j ACCEPT

# Rate limiting (brute force protection)
iptables -A INPUT -p tcp --dport 22 -m state --state NEW \
  -m recent --name SSH --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW \
  -m recent --name SSH --rcheck --seconds 60 --hitcount 5 -j DROP

# NAT — masquerade (internet sharing)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# NAT — port forwarding
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.20:80
iptables -A FORWARD -p tcp -d 192.168.1.20 --dport 80 -j ACCEPT

# Save and restore
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
iptables-restore < /etc/iptables/rules.v4

# Persist across reboots
apt install -y iptables-persistent
netfilter-persistent save
```

### nftables — modern iptables replacement

```bash
# /etc/nftables.conf
cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        # Loopback
        iif lo accept

        # Established connections
        ct state established,related accept

        # Drop invalid
        ct state invalid drop

        # ICMP (ping)
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # SSH — rate limited
        tcp dport 22 ct state new limit rate 10/minute burst 30 packets accept

        # HTTP/HTTPS
        tcp dport { 80, 443 } accept

        # Allow from management network
        ip saddr 192.168.100.0/24 accept

        # Log and drop everything else
        log prefix "[nftables-drop] " drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}

table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100;

        # Port forwarding
        iif eth0 tcp dport 8080 dnat to 192.168.1.20:80
    }

    chain postrouting {
        type nat hook postrouting priority 100;

        # Masquerade for internet sharing
        oif eth0 masquerade
    }
}
EOF

systemctl enable --now nftables
nft list ruleset                        # View loaded rules
nft list table inet filter
```


# Section 06 — Networking

## 6.1 Network Configuration

### ip — modern network configuration (iproute2)

```bash
# Interface management
ip link show                           # List all interfaces
ip link show eth0                      # Specific interface
ip link set eth0 up                    # Bring interface up
ip link set eth0 down                  # Bring interface down
ip link set eth0 mtu 9000              # Set jumbo frames
ip link set eth0 promisc on            # Promiscuous mode

# IP addresses
ip addr show                           # Show all addresses
ip addr show eth0                      # Specific interface
ip addr add 192.168.1.100/24 dev eth0  # Add IP address
ip addr del 192.168.1.100/24 dev eth0  # Remove IP address
ip addr flush dev eth0                 # Remove all IPs from interface

# Routing
ip route show                          # Routing table
ip route add default via 192.168.1.1  # Default gateway
ip route add 10.0.0.0/8 via 10.1.1.1 # Static route
ip route del 10.0.0.0/8               # Delete route
ip route get 8.8.8.8                   # What route would be used?
ip route flush table main              # Flush routing table (careful!)

# ARP cache
ip neigh show                          # ARP table
ip neigh add 192.168.1.10 lladdr aa:bb:cc:dd:ee:ff dev eth0  # Static ARP
ip neigh del 192.168.1.10 dev eth0    # Delete ARP entry
ip neigh flush dev eth0               # Flush ARP cache

# Namespace (network isolation)
ip netns add myns                      # Create namespace
ip netns exec myns ip link show        # Run command inside namespace
ip netns del myns                      # Delete namespace
```

### Netplan (Ubuntu 20.04+ default)

```yaml
# /etc/netplan/00-network.yaml

network:
  version: 2
  renderer: networkd   # or: NetworkManager

  ethernets:
    # DHCP interface
    eth0:
      dhcp4: true
      dhcp6: false
      optional: true

    # Static IP interface
    eth1:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
        - to: 10.0.0.0/8
          via: 192.168.1.254
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
        search:
          - internal.company.com

  # Bonding (LACP) for high availability
  bonds:
    bond0:
      interfaces: [eth2, eth3]
      parameters:
        mode: 802.3ad
        mii-monitor-interval: 100
      addresses:
        - 10.0.1.100/24

  # VLAN
  vlans:
    eth0.100:
      id: 100
      link: eth0
      addresses:
        - 172.16.100.1/24

  # Bridge (for VMs/containers)
  bridges:
    br0:
      interfaces: [eth4]
      addresses:
        - 192.168.100.1/24
      parameters:
        forward-delay: 0
        stp: false
```

```bash
# Apply netplan config
netplan apply              # Apply and persist
netplan try                # Apply with 2-min auto-revert (safe for remote)
netplan generate           # Generate backend config without applying
```

### NetworkManager (desktop/server with nmcli)

```bash
nmcli device status                                    # Device list
nmcli connection show                                  # Connection list
nmcli connection up "Wired connection 1"               # Activate
nmcli connection down "Wired connection 1"

# Create static IP connection
nmcli connection add \
  type ethernet \
  con-name "static-eth0" \
  ifname eth0 \
  ipv4.method manual \
  ipv4.addresses "192.168.1.100/24" \
  ipv4.gateway "192.168.1.1" \
  ipv4.dns "8.8.8.8,1.1.1.1"

nmcli connection modify "static-eth0" ipv4.dns-search "company.com"
nmcli connection up "static-eth0"

# WiFi
nmcli device wifi list
nmcli device wifi connect "SSID" password "mypassword"
```

---

## 6.2 DNS Setup

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

---

## 6.3 Routing Tables

```bash
# View routing table
ip route
route -n                               # Legacy but still common

# Add routes
ip route add 10.0.0.0/8 via 10.1.1.1 dev eth0
ip route add 192.168.2.0/24 via 192.168.1.254
ip route add blackhole 198.51.100.0/24  # Drop packets (blackhole route)

# Enable IP forwarding (router mode)
echo 1 > /proc/sys/net/ipv4/ip_forward
# Persist:
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-routing.conf
sysctl -p /etc/sysctl.d/99-routing.conf

# Policy routing (multiple routing tables)
# Add a route to table 100
ip route add default via 10.0.0.1 table 100
# Add rule: traffic from 10.1.0.0/24 uses table 100
ip rule add from 10.1.0.0/24 lookup 100

# View routing tables
ip rule show
ip route show table all
ip route show table 100
```

---

## 6.4 Firewall Configuration

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

---

## 6.5 SSH Configuration and Hardening

### /etc/ssh/sshd_config — server config

```bash
cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# Network
Port 22                        # Change to non-standard port in high-risk environments
AddressFamily inet             # IPv4 only (remove if IPv6 needed)
ListenAddress 0.0.0.0

# Authentication
PermitRootLogin no             # NEVER allow root login
PasswordAuthentication no      # Key-based auth only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# MFA (uncomment if using Google Authenticator PAM)
# AuthenticationMethods publickey,keyboard-interactive

# Session
LoginGraceTime 60              # Seconds to complete login
MaxAuthTries 3                 # Failed attempts before disconnect
MaxSessions 10                 # Concurrent sessions per connection
MaxStartups 10:30:60          # Rate limit new connections (10 full, then 30% drop, 60 max)

# Security
X11Forwarding no
PrintMotd no
PrintLastLog yes
AcceptEnv LANG LC_*
AllowTcpForwarding no          # Disable unless needed
AllowAgentForwarding no
PermitTunnel no

# Protocol
Protocol 2
HostKeyAlgorithms ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ssh-ed25519
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Timeouts
ClientAliveInterval 300        # Send keepalive every 5 min
ClientAliveCountMax 2          # Disconnect after 2 missed keepalives

# Access control
AllowUsers admin deploy         # Only these users can SSH
# AllowGroups sshusers          # Or by group
DenyUsers root ubuntu           # Explicitly deny

# Banner (show before login)
Banner /etc/ssh/banner.txt
EOF

# Validate config before restarting
sshd -t
systemctl restart sshd
```

### SSH Key Management

```bash
# Generate Ed25519 key (best for modern SSH)
ssh-keygen -t ed25519 -C "user@company.com" -f ~/.ssh/id_ed25519

# Generate RSA 4096 (compatibility with older systems)
ssh-keygen -t rsa -b 4096 -C "user@company.com"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# Manual authorized_keys entry
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Restrict what a key can do in authorized_keys
# Format: options key-type key comment
cat >> ~/.ssh/authorized_keys << 'EOF'
# Restrict to specific command only
command="/usr/local/bin/backup-only.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAA...

# Restrict to specific source IP
from="192.168.1.100",no-pty ssh-ed25519 AAAA...
EOF

# SSH config client file (~/.ssh/config)
cat > ~/.ssh/config << 'EOF'
Host prod-*
    User deploy
    IdentityFile ~/.ssh/prod_ed25519
    StrictHostKeyChecking yes
    ServerAliveInterval 30

Host bastion
    Hostname 1.2.3.4
    User admin
    Port 2222
    IdentityFile ~/.ssh/bastion_ed25519

# Jump through bastion to reach internal servers
Host internal-*
    ProxyJump bastion
    User admin
    IdentityFile ~/.ssh/internal_ed25519
EOF
chmod 600 ~/.ssh/config

# SSH tunnels
ssh -L 5432:db-server:5432 bastion     # Local port forward (access remote DB locally)
ssh -R 8080:localhost:8080 server      # Remote port forward (expose local port on server)
ssh -D 1080 bastion                    # SOCKS proxy through bastion
ssh -N -f user@server -L 3306:db:3306  # Background, no command

# SSH agent
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
ssh-add -l                              # List keys in agent
ssh-add -D                             # Remove all keys from agent
```

---

## 6.6 Network Diagnostics

```bash
# Connectivity test
ping -c 4 8.8.8.8                      # ICMP ping (4 packets)
ping -i 0.2 -c 100 192.168.1.1        # Rapid ping (latency check)
ping6 ::1                              # IPv6 ping

# Traceroute
traceroute 8.8.8.8                     # UDP traceroute
traceroute -T -p 80 google.com         # TCP traceroute (bypasses ICMP blocks)
mtr google.com                         # Interactive, combines ping+traceroute

# Port scanning
nmap -sV -p 22,80,443 192.168.1.0/24  # Service version detection
nmap -O 192.168.1.1                    # OS detection
nmap -sn 192.168.1.0/24               # Ping sweep (host discovery)
nmap -p 1-65535 192.168.1.100         # Full port scan

# Connection testing
nc -zv 192.168.1.100 22               # Test if port is open
nc -zv -u 192.168.1.100 53            # UDP port test
telnet 192.168.1.100 80               # Telnet connection (legacy)

# DNS debugging
dig +short @1.1.1.1 google.com A      # Query specific server
dig +trace google.com                  # Full resolution chain
dig AXFR internal.company.com @ns1   # Zone transfer (test if allowed — should be blocked)

# Bandwidth testing
iperf3 -s                             # Server mode
iperf3 -c server -t 30 -P 4          # Client: 30s test, 4 parallel streams
speedtest-cli                          # Internet speed test

# Packet capture
tcpdump -i eth0 -w /tmp/capture.pcap \
  'host 192.168.1.100 and port 443'   # Capture HTTPS to/from host
tcpdump -i eth0 -n -v 'tcp port 80'  # HTTP traffic verbose
```

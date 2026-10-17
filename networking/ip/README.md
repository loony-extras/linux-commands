# ip & Routing

Interface configuration, netplan and routing tables.

---

## Files

- [examples.sh](examples.sh)

---

## Network Configuration

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

## Routing Tables

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


#!/usr/bin/env bash
# =============================================================================
# ip & Routing — annotated command examples
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### ip — network interface and routing management
# ---------------------------------------------------------------------------
ip link show                    # All interfaces with status
ip link show eth0               # Specific interface
ip link set eth0 up             # Bring interface up
ip link set eth0 down           # Bring interface down
ip addr show                    # Show all IP addresses
ip addr show eth0               # Specific interface's addresses
ip addr add 192.168.1.100/24 dev eth0   # Add IP address
ip addr del 192.168.1.100/24 dev eth0   # Remove IP address
ip route show                   # Routing table
ip route get 8.8.8.8            # Which route is used to reach 8.8.8.8
ip route add default via 192.168.1.1    # Default gateway
ip route add 10.0.0.0/8 via 10.1.1.1   # Static route
ip route del 10.0.0.0/8                 # Delete route
ip neigh show                   # ARP/neighbor table
ip neigh flush dev eth0         # Flush ARP cache for interface
ip -s link show eth0            # Interface statistics (bytes, errors, drops)
ip -br addr                     # Brief address table (compact)
ip -br link                     # Brief interface table

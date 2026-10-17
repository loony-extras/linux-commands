#!/usr/bin/env bash
# =============================================================================
# Network Diagnostics — annotated command examples
# Tier: 3 (Advanced), 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### ss — socket statistics (modern replacement for netstat)
# ---------------------------------------------------------------------------
ss                              # All open sockets
ss -t                           # TCP sockets only
ss -u                           # UDP sockets only
ss -l                           # Listening sockets only
ss -a                           # All sockets (listening + connected)
ss -n                           # Numeric (don't resolve hostnames/ports)
ss -p                           # Show process using socket
ss -s                           # Summary statistics
ss -tlnp                        # TCP Listening Numeric with Process (most useful)
ss -ulnp                        # UDP Listening Numeric with Process
ss -tnp                         # TCP connected with process
ss -anp                         # All sockets with processes
ss -tlnp | grep :80             # Who is listening on port 80
ss -tnp | grep ESTABLISHED      # Established connections
ss -o state ESTABLISHED         # Show only established state
ss -o state TIME-WAIT           # TIME-WAIT sockets (indicates connection churn)
ss -o state CLOSE-WAIT          # CLOSE-WAIT (app not closing sockets)
ss -tnp dst 192.168.1.100       # Connections to specific remote host
ss -tnp dport = :443            # Connections to destination port 443
ss -tnp src :8080               # Connections from source port 8080
ss -4                           # IPv4 only
ss -6                           # IPv6 only
ss -r                           # Resolve hostnames
ss --timer                      # Show timer info (keepalive, retransmit)
ss -e                           # Extended info (UID, inode)
ss -m                           # Memory usage per socket
ss -info                        # Internal TCP info (retransmits, etc.)

# ---------------------------------------------------------------------------
### netstat — legacy socket stats (apt install net-tools)
# ---------------------------------------------------------------------------
netstat -tlnp                   # TCP listening with process
netstat -an                     # All connections (no hostname resolution)
netstat -rn                     # Routing table (numeric)
netstat -s                      # Protocol statistics
netstat -i                      # Interface statistics
netstat -c                      # Continuous output

# ---------------------------------------------------------------------------
### tcpdump — packet capture and analysis
# ---------------------------------------------------------------------------
tcpdump -i eth0                         # All traffic on eth0
tcpdump -i any                          # All interfaces
tcpdump -i eth0 port 80                 # HTTP traffic only
tcpdump -i eth0 host 192.168.1.100     # To/from specific host
tcpdump -i eth0 src 192.168.1.100      # FROM specific host only
tcpdump -i eth0 dst 8.8.8.8            # TO specific host only
tcpdump -i eth0 -n                      # No hostname resolution
tcpdump -i eth0 -nn                     # No name or port resolution
tcpdump -i eth0 -v                      # Verbose (show more packet details)
tcpdump -i eth0 -vv                     # More verbose
tcpdump -i eth0 -X                      # Show packet contents in hex + ASCII
tcpdump -i eth0 -A                      # ASCII only (good for HTTP)
tcpdump -i eth0 -c 100                  # Capture 100 packets then stop
tcpdump -i eth0 -w capture.pcap         # Write to file (for Wireshark analysis)
tcpdump -r capture.pcap                 # Read from file
tcpdump -i eth0 'tcp[tcpflags] & tcp-syn != 0'  # SYN packets only
tcpdump -i eth0 'tcp[tcpflags] & (tcp-rst) != 0'  # RST packets (connection resets)
tcpdump -i eth0 'not port 22'           # Exclude SSH traffic
tcpdump -i eth0 'host A and not host B' # Compound filter

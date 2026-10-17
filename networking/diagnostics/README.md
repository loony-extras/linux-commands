# Network Diagnostics

ss, netstat, tcpdump and connectivity debugging.

---

## Files

- [examples.sh](examples.sh)
- [netstat.md](netstat.md)

---

## Network Diagnostics

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

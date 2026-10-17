Here’s a clean table of commonly used `netstat` commands with explanations you can quickly reference:

---

## 📋 Netstat Commands Cheat Sheet

| Command          | What It Does                                        | When to Use                                      |
| ---------------- | --------------------------------------------------- | ------------------------------------------------ |
| `netstat -a`     | Shows all active connections and listening ports    | General overview of network activity             |
| `netstat -l`     | Displays only listening ports                       | Check which services are waiting for connections |
| `netstat -t`     | Shows TCP connections                               | Focus only on TCP traffic                        |
| `netstat -u`     | Shows UDP connections                               | Focus only on UDP traffic                        |
| `netstat -n`     | Displays numeric addresses (no DNS resolution)      | Faster output, avoids hostname lookup delays     |
| `netstat -p`     | Shows PID and process name (Linux only, needs sudo) | Identify which program owns a connection         |
| `netstat -tuln`  | Lists all listening TCP/UDP ports numerically       | Quick view of open ports                         |
| `netstat -tulnp` | Same as above + process info                        | Debug port conflicts (most useful combo)         |
| `netstat -i`     | Shows network interface statistics                  | Check packet flow and errors                     |
| `netstat -r`     | Displays routing table                              | Diagnose routing/network path issues             |
| `netstat -s`     | Shows protocol statistics (TCP, UDP, ICMP)          | Analyze network performance/issues               |
| `netstat -c`     | Continuously updates output                         | Real-time monitoring                             |
| `netstat -g`     | Shows multicast group memberships                   | Advanced networking/debugging                    |
| `netstat -M`     | Displays masquerade/NAT connections (Linux)         | Debug NAT/firewall issues                        |

---

## 🔍 Useful Combined Commands

| Command                           | Purpose                                                         |
| --------------------------------- | --------------------------------------------------------------- |
| `netstat -tulnp \| grep :PORT`    | Find which process is using a specific port                     |
| `netstat -an \| grep ESTABLISHED` | Show only active (established) connections                      |
| `netstat -an \| grep LISTEN`      | Show only listening services                                    |
| `sudo netstat -tunap`             | Full detailed network + process view (good for security checks) |

---

## 💡 Quick Tips

- Use `sudo` when you want process (`-p`) details
- Combine flags to narrow results (`-tulnp` is the most practical combo)
- Prefer `-n` for speed (avoids DNS lookups)
- On modern systems, consider using the newer tool:
  👉 ss (faster replacement for netstat)

---

If you want, I can turn this into a **one-page printable cheat sheet** or show **real-world troubleshooting examples** using these commands.

# SSH

Remote access, file transfer and SSH hardening.

---

## Files

- [scp.md](scp.md)
- [ssh.md](ssh.md)
- [ssh_dev_workflow.md](ssh_dev_workflow.md)
- [sshd_config](sshd_config)

---

## Usage

`sshd_config` deploys to `/etc/ssh/sshd_config.d/99-hardening.conf`: no root login,
no password auth, strong ciphers, timeouts.

---

## SSH Configuration and Hardening

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

## SSH Hardening

```bash
# Regenerate SSH host keys (after OS install from image)
rm /etc/ssh/ssh_host_*
ssh-keygen -A             # Regenerate all host key types
systemctl restart sshd

# Add legal banner
cat > /etc/ssh/banner.txt << 'EOF'
***************************************************************************
                        AUTHORIZED ACCESS ONLY
This system is for authorized users only. All activity is monitored and
logged. Unauthorized access attempts will be prosecuted to the full extent
of the law. Disconnect immediately if you are not an authorized user.
***************************************************************************
EOF
```


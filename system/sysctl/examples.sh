#!/usr/bin/env bash
# =============================================================================
# sysctl — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### sysctl — kernel parameter management
# ---------------------------------------------------------------------------
sysctl -a                               # List ALL kernel parameters
sysctl -a 2>/dev/null | wc -l          # Count parameters (~1000+)
sysctl -a | grep net.ipv4              # Filter by prefix
sysctl net.ipv4.ip_forward             # Read a parameter
sysctl kernel.hostname                 # Read hostname from kernel
sysctl -w net.ipv4.ip_forward=1        # Set temporarily (lost on reboot)
sysctl -w net.core.somaxconn=65535     # Increase connection backlog
sysctl -p                              # Load /etc/sysctl.conf
sysctl -p /etc/sysctl.d/99-custom.conf # Load specific file
sysctl --system                        # Load all /etc/sysctl.d/ files

# Loony Linux — Production-Grade Linux System Guide & Toolkit

A real-world Linux reference and automation toolkit for systems engineers, DevOps
and security work: in-depth guides, quick cheatsheets, and runnable scripts and configs.
Targets Ubuntu 22.04/24.04 and Debian 12.

## Quick Start

```bash
git clone <repo> linux-commands && cd linux-commands
find . -name "*.sh" -not -path "./.git/*" -exec chmod +x {} \;

# Optional: shortcut for the search tool
echo "alias lls='bash $PWD/search.sh'" >> ~/.bashrc && source ~/.bashrc

./search.sh            # interactive menu
./search.sh nginx      # search everything for a keyword
./search.sh -t grep    # examples for one tool
```

## Documentation

All guides live in [docs/](docs/):

| # | Guide |
|---|-------|
| 01 | [Installation & System Setup](docs/01-installation.md) |
| 02 | [Filesystem & Storage](docs/02-filesystem.md) |
| 03 | [Core Command-Line Toolkit](docs/03-commands.md) |
| 04 | [Process Management & systemd](docs/04-process-management.md) |
| 05 | [User Management & Permissions](docs/05-user-management.md) |
| 06 | [Networking](docs/06-networking.md) |
| 07 | [Security Hardening](docs/07-security.md) |
| 08 | [Package Management & Build Systems](docs/08-package-management.md) |
| 09 | [Automation & DevOps](docs/09-automation-devops.md) |
| 10 | [Monitoring & Performance](docs/10-monitoring.md) |
| 11 | [Troubleshooting Guide](docs/11-troubleshooting.md) |
| 12 | [Kernel & Low-Level Systems](docs/12-kernel.md) |
| 13 | [Real-World Project Template](docs/13-project-template.md) |
| 15 | [Best Practices & Anti-Patterns](docs/15-best-practices.md) |

Reference:

- [Search & Navigation](docs/search.md): every `search.sh` option, doc aliases, command library sections
- [Toolkit Reference](docs/toolkit.md): repository layout, scripts, configs, systemd units, monitoring, security, Docker, Ansible, Kubernetes, compatibility

## Cheatsheets

Quick per-tool references (find, grep, ssh, curl, chmod, ffmpeg, …) are in
[cheatsheets/](cheatsheets/README.md).

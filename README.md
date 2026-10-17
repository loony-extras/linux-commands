# Loony Linux — Production-Grade Linux System Guide & Toolkit

A real-world Linux reference and automation toolkit for systems engineers, DevOps
and security work. Every program has its own folder with its docs (`README.md`),
annotated examples (`examples.sh`) and any scripts or configs.

## Quick Start

```bash
git clone <repo> linux-commands && cd linux-commands
find . -name "*.sh" -not -name examples.sh -not -path "./.git/*" -exec chmod +x {} \;

# Optional: shortcut for the search tool
echo "alias lls='bash $PWD/search.sh'" >> ~/.bashrc && source ~/.bashrc

./search.sh            # interactive menu
./search.sh nginx      # search everything for a keyword
./search.sh -t grep    # examples for one tool
./search.sh -d ssh     # open a program's README
```

Full options: [SEARCH.md](SEARCH.md).

## Layout

```
<category>/<program>/
    README.md       docs for the program
    examples.sh     annotated command examples (reference, not meant to be run whole)
    *.sh, *.conf    runnable scripts and drop-in configs
```

| Category | Programs |
|----------|----------|
| [commands](commands/) | ls, cd, cp, mv, rm, cat, grep, awk, sed, find, xargs, tar, bash, one-liners, ffmpeg, … |
| [system](system/) | installation, grub, apt, kernel, sysctl, systemd, journald, processes, cron, users, permissions, backup |
| [storage](storage/) | filesystems, mount, partitioning, lvm, raid |
| [networking](networking/) | ip, dns, firewall, ssh, diagnostics, curl, wget |
| [security](security/) | hardening, fail2ban, auditd, aide, rkhunter, pam, sudo, apparmor-selinux |
| [monitoring](monitoring/) | performance, logs, prometheus, grafana, node-exporter |
| [debugging](debugging/) | strace, lsof, binary-tools, perf, bpftrace |
| [devops](devops/) | docker, ansible, kubernetes, ci-cd |
| [services](services/) | cloudflare |
| [guides](guides/) | troubleshooting, production-server, best-practices |

Each category folder has a README listing its programs.

## Compatibility

Ubuntu 22.04 / 24.04 LTS and Debian 12 (most scripts work on any systemd Linux).
Kernel 5.15+, bash 4.3+, Ansible 2.12+, Docker 24+, kubectl 1.28+.

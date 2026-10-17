# Ansible

Playbooks and roles for fleet configuration.

---

## Files

- [inventory/hosts.yml](inventory/hosts.yml)
- [playbooks/site.yml](playbooks/site.yml)
- [roles/](roles/): common, security, monitoring

---

## Usage

```bash
cd devops/ansible/

ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check   # no changes
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check --diff   # dry run
ansible-playbook -i inventory/hosts.yml playbooks/site.yml                  # apply
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit web-01
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags security

ansible web -i inventory/hosts.yml -m shell -a "uptime" --become
ansible all -i inventory/hosts.yml -m ping
```

| Role | Tasks |
|------|-------|
| `common` | Packages, timezone, sysctl, unattended-upgrades, admin user, SSH keys, UFW, disable unused services |
| `security` | SSH hardening, nftables, fail2ban, auditd, sysctl security params, core dump disable, /tmp noexec, AIDE |
| `monitoring` | Node Exporter install + systemd service, Prometheus config + alert rules |

---

## Ansible Playbooks

Full playbooks and roles are in [playbooks/](playbooks/) and [roles/](roles/).

### Inventory

```yaml
# devops/ansible/inventory/hosts.yml
all:
  vars:
    ansible_user: admin
    ansible_ssh_private_key_file: ~/.ssh/prod_ed25519
    ansible_ssh_common_args: '-o StrictHostKeyChecking=yes'

  children:
    web:
      hosts:
        web-01:
          ansible_host: 192.168.1.10
        web-02:
          ansible_host: 192.168.1.11
      vars:
        nginx_workers: 4

    db:
      hosts:
        db-01:
          ansible_host: 192.168.1.20
      vars:
        postgres_max_connections: 200

    bastion:
      hosts:
        bastion-01:
          ansible_host: 1.2.3.4
          ansible_port: 2222
```

### Main Site Playbook

```yaml
# devops/ansible/playbooks/site.yml
---
- name: Common baseline for all servers
  hosts: all
  become: yes
  roles:
    - common
    - security

- name: Web servers
  hosts: web
  become: yes
  roles:
    - nginx
    - certbot

- name: Database servers
  hosts: db
  become: yes
  roles:
    - postgresql
    - monitoring
```

### Common Role Tasks

```yaml
# devops/ansible/roles/common/tasks/main.yml
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install baseline packages
  apt:
    name:
      - curl
      - wget
      - git
      - vim
      - htop
      - tmux
      - ufw
      - fail2ban
      - auditd
      - unattended-upgrades
    state: present

- name: Set timezone to UTC
  timezone:
    name: UTC

- name: Set hostname
  hostname:
    name: "{{ inventory_hostname }}"

- name: Configure /etc/hosts
  template:
    src: hosts.j2
    dest: /etc/hosts
    owner: root
    group: root
    mode: '0644'

- name: Configure sysctl security parameters
  sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    state: present
    reload: yes
  loop:
    - { name: net.ipv4.ip_forward, value: '0' }
    - { name: kernel.randomize_va_space, value: '2' }
    - { name: net.ipv4.tcp_syncookies, value: '1' }
    - { name: kernel.dmesg_restrict, value: '1' }
    - { name: fs.protected_symlinks, value: '1' }
    - { name: fs.protected_hardlinks, value: '1' }

- name: Disable and mask unnecessary services
  systemd:
    name: "{{ item }}"
    state: stopped
    enabled: no
    masked: yes
  loop:
    - avahi-daemon
    - cups
    - bluetooth
  ignore_errors: yes

- name: Configure unattended upgrades
  template:
    src: 50unattended-upgrades.j2
    dest: /etc/apt/apt.conf.d/50unattended-upgrades
  notify: enable unattended-upgrades

- name: Create admin user
  user:
    name: "{{ admin_user }}"
    groups:
      - sudo
      - adm
    shell: /bin/bash
    create_home: yes
    state: present

- name: Set authorized keys for admin
  authorized_key:
    user: "{{ admin_user }}"
    key: "{{ lookup('file', 'files/authorized_keys') }}"
    state: present
    exclusive: yes

- name: Configure sudo for admin
  copy:
    content: "{{ admin_user }} ALL=(ALL:ALL) ALL\n"
    dest: "/etc/sudoers.d/{{ admin_user }}"
    mode: '0440'
    validate: /usr/sbin/visudo -cf %s
```

### Security Role

```yaml
# devops/ansible/roles/security/tasks/main.yml
---
- name: Configure SSH hardening
  template:
    src: sshd_hardening.conf.j2
    dest: /etc/ssh/sshd_config.d/99-hardening.conf
    mode: '0600'
  notify: restart sshd

- name: Configure UFW defaults
  ufw:
    state: enabled
    policy: deny
    direction: incoming

- name: Allow SSH through UFW
  ufw:
    rule: allow
    port: '22'
    proto: tcp

- name: Configure fail2ban
  template:
    src: jail.local.j2
    dest: /etc/fail2ban/jail.local
  notify: restart fail2ban

- name: Enable and start fail2ban
  service:
    name: fail2ban
    state: started
    enabled: yes

- name: Configure auditd rules
  template:
    src: audit.rules.j2
    dest: /etc/audit/rules.d/99-custom.rules
  notify: restart auditd

- name: Configure sysctl security settings
  template:
    src: sysctl-security.conf.j2
    dest: /etc/sysctl.d/99-security.conf
  notify: reload sysctl

- name: Initialize AIDE database
  command: aide --init
  args:
    creates: /var/lib/aide/aide.db.new
  register: aide_init

- name: Move AIDE database
  command: mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
  when: aide_init.changed
```

### Running Ansible

```bash
# Syntax check
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check

# Dry run (check mode)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check --diff

# Apply to all hosts
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Apply to specific host/group
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit web-01
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --limit web

# Apply only specific tags
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags security

# Override variables
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  --extra-vars "admin_user=deploy nginx_workers=8"

# Verbose output
ansible-playbook -vvv -i inventory/hosts.yml playbooks/site.yml

# Ad-hoc commands
ansible all -i inventory/hosts.yml -m ping
ansible web -i inventory/hosts.yml -m shell -a "df -h"
ansible web -i inventory/hosts.yml -m apt -a "name=nginx state=latest" --become
ansible db -i inventory/hosts.yml -m service -a "name=postgresql state=restarted" --become
```


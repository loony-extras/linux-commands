# GRUB

Bootloader configuration.

---

## GRUB Configuration

GRUB2 is the standard bootloader for Debian/Ubuntu.

### Key files
- `/etc/default/grub` — user-facing config
- `/etc/grub.d/` — generator scripts
- `/boot/grub/grub.cfg` — generated output (never edit directly)

```bash
# /etc/default/grub — recommended production settings
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="Production Server"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
# Security: enable auditing from boot
GRUB_CMDLINE_LINUX="audit=1 apparmor=1 security=apparmor"

# Regenerate grub config after any edit
sudo update-grub

# Reinstall grub to MBR (BIOS systems)
sudo grub-install /dev/sda

# Reinstall grub for UEFI
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu
```

### GRUB Password Protection (prevent single-user mode access)

```bash
# Generate hashed password
grub-mkpasswd-pbkdf2

# Add to /etc/grub.d/40_custom
cat >> /etc/grub.d/40_custom << 'EOF'
set superusers="grubadmin"
password_pbkdf2 grubadmin grub.pbkdf2.sha512.10000.<HASH_HERE>
EOF

sudo update-grub
```


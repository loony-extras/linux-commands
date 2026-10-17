# Permissions

chmod, chown, ACLs and special bits.

---

## Files

- [chmod.md](chmod.md)
- [chmod_chown.md](chmod_chown.md)
- [chown.md](chown.md)

---

## File Permissions

### Basic Permission Model

```
-rwxr-xr-x  1  user  group  size  date  filename
│├──┤├──┤├──┤
│ u   g   o        u=user/owner, g=group, o=others
│
└─ file type: - file, d directory, l symlink, b block, c char, p pipe, s socket
```

### chmod — change mode

```bash
# Symbolic mode
chmod u+x file           # Add execute for owner
chmod go-w file          # Remove write from group and others
chmod a+r file           # Add read for all
chmod u=rwx,go=rx file   # Set exact permissions

# Octal mode (most common)
chmod 755 file           # rwxr-xr-x
chmod 644 file           # rw-r--r--
chmod 600 file           # rw-------  (private keys, secrets)
chmod 700 dir            # rwx------
chmod 777 file           # AVOID on production (world-writable)

# Recursive
chmod -R 755 /var/www/html

# Common permission patterns
# Config files:  644 (root:root)
# Scripts:       755 (root:root)
# Private keys:  600 (user:user)
# Directories:   755 or 750
# Shared dir:    2775 (setgid)
```

### chown — change owner

```bash
chown user:group file
chown -R www-data:www-data /var/www/html
chown root:sudo /usr/bin/somescript
```

### Special permission bits

```bash
# SUID (Set User ID) — run as file owner, not current user
chmod u+s /usr/bin/passwd    # passwd runs as root regardless of who runs it
ls -l /usr/bin/passwd        # shows: -rwsr-xr-x

# SGID (Set Group ID) — run with file's group / inherit group for dirs
chmod g+s /var/shared        # Files in /var/shared inherit its group
ls -ld /var/shared           # shows: drwxr-sr-x

# Sticky bit — only file owner can delete in shared directory
chmod +t /tmp
ls -ld /tmp                  # shows: drwxrwxrwt

# Combined (SUID+SGID+Sticky in octal)
chmod 7755 file              # SUID+SGID+Sticky = 7, then 755
chmod 1777 /tmp              # Sticky bit only
chmod 2755 /var/shared       # SGID only
chmod 4755 /usr/bin/prog     # SUID only
```

### ACLs (Access Control Lists) — fine-grained beyond rwx

```bash
# Install ACL tools
apt install -y acl

# View ACLs
getfacl /var/www/html

# Set ACL for a specific user
setfacl -m u:nginx:rx /var/www/html

# Set ACL for a specific group
setfacl -m g:developers:rwx /var/www/html

# Set default ACL (inherited by new files/dirs)
setfacl -d -m u:nginx:rx /var/www/html

# Remove an ACL entry
setfacl -x u:nginx /var/www/html

# Remove all ACLs
setfacl -b /var/www/html

# Copy ACLs from one file to another
getfacl file1 | setfacl --set-file=- file2
```


---

## File Permission Model (recap + advanced)

```bash
# umask — default permission mask
umask                              # Show current (e.g., 0022)
# umask 0022 means:
#   files: 666 - 022 = 644 (rw-r--r--)
#   dirs:  777 - 022 = 755 (rwxr-xr-x)
umask 0027                         # More restrictive: files=640, dirs=750
# Set globally in /etc/profile or /etc/pam.d/common-session:
# session optional pam_umask.so umask=0027

# Find files with dangerous permissions
find / -xdev -perm -4000 -type f 2>/dev/null    # SUID files
find / -xdev -perm -2000 -type f 2>/dev/null    # SGID files
find / -xdev -perm -o+w -type f 2>/dev/null     # World-writable files
find / -xdev -nouser 2>/dev/null                 # Files with no owner
find / -xdev -nogroup 2>/dev/null               # Files with no group

# Restrict access to sensitive files
chmod 600 /etc/ssh/ssh_host_*_key    # Private SSH host keys
chmod 640 /etc/shadow                # Shadow file
chmod 440 /etc/sudoers               # sudoers
chmod 700 /root                      # Root's home
chmod 711 /home                      # Home base dir
chmod 750 /home/john                 # User's home
```


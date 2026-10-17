`scp` (secure copy) is a simple but powerful command in Linux used to transfer files over SSH. It’s widely used because it’s secure and doesn’t require extra setup if SSH is already configured.

Here’s a complete, practical breakdown of what you can do with it:

---

# 🔹 Basic Syntax

```
scp [options] source destination
```

---

# 📁 1. Copy file from local → remote

```
scp file.txt user@remote:/path/
```

Uploads a file to a remote server.

---

# 📥 2. Copy file from remote → local

```
scp user@remote:/path/file.txt .
```

Downloads a file to your current directory.

---

# 📂 3. Copy entire directories

```
scp -r folder/ user@remote:/path/
```

- `-r` = recursive (required for directories)

---

# 🔁 4. Remote → Remote copy

```
scp user1@host1:/file user2@host2:/path/
```

Transfers files between two remote servers via your machine.

---

# 🔐 5. Use a specific SSH key

```
scp -i ~/.ssh/key.pem file.txt user@remote:/path/
```

---

# 🔌 6. Use a custom SSH port

```
scp -P 2222 file.txt user@remote:/path/
```

(uppercase `-P`, not lowercase)

---

# ⚡ 7. Limit bandwidth

```
scp -l 1000 file.txt user@remote:/path/
```

- Limits speed (in Kbit/s)

---

# 📊 8. Show progress / verbose mode

```
scp -v file.txt user@remote:/path/
```

Useful for debugging connection issues.

---

# 🗜️ 9. Enable compression

```
scp -C file.txt user@remote:/path/
```

Speeds up transfers for large files over slow networks.

---

# 🧾 10. Preserve file attributes

```
scp -p file.txt user@remote:/path/
```

Keeps timestamps, permissions, etc.

---

# 📍 11. Specify remote path with spaces

```
scp "file name.txt" user@remote:"/path with spaces/"
```

---

# 🔄 12. Copy multiple files

```
scp file1.txt file2.txt user@remote:/path/
```

---

# 📤 13. Upload to a different filename

```
scp file.txt user@remote:/path/newname.txt
```

---

# 📥 14. Download and rename

```
scp user@remote:/path/file.txt newname.txt
```

---

# 🔍 15. Use wildcards

```
scp *.log user@remote:/path/
```

---

# 🌐 16. Use proxy / jump host

```
scp -o ProxyJump=user@jump_host file.txt user@target:/path/
```

Great for accessing internal servers.

---

# 🔗 17. Copy via SSH config alias

If `~/.ssh/config` contains:

```
Host myserver
  HostName 192.168.1.10
  User ubuntu
```

Then:

```
scp file.txt myserver:/path/
```

---

# 🧱 18. Limit cipher (performance tuning)

```
scp -c aes128-ctr file.txt user@remote:/path/
```

---

# 🔄 19. Disable strict host checking (automation)

```
scp -o StrictHostKeyChecking=no file.txt user@remote:/path/
```

⚠️ Use carefully (security risk)

---

# 📡 20. Quiet mode

```
scp -q file.txt user@remote:/path/
```

---

# 🧪 21. Dry-run alternative (not native)

`scp` itself doesn’t support dry-run, but you can simulate with:

```
rsync --dry-run -av file.txt user@remote:/path/
```

---

# ⚠️ Important Notes

- `scp` is being **gradually deprecated** in favor of `sftp` and `rsync`
- Newer OpenSSH versions internally use SFTP for `scp`
- No resume support (use `rsync` if needed)

---

# 🔄 When NOT to use scp

Use alternatives when you need:

- Resume interrupted transfers → `rsync`
- Sync directories → `rsync`
- Interactive browsing → `sftp`

---

# 💡 Pro Tips

- Use `rsync` for large transfers:

  ```
  rsync -avz file user@remote:/path/
  ```

- Combine with SSH config for cleaner commands
- Always test permissions if transfers fail

---

If you want, I can give you:

- real-world DevOps use cases (deployment, backups, etc.)
- or advanced tricks most developers don’t know about

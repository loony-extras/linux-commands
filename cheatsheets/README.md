# Linux Commands

---

## 📂 File & Directory Management

- `ls` – list files (`ls -la` is used constantly)
- `cd` – navigate directories
- `pwd` – show current directory
- `mkdir` – create folders
- `rm` – delete files (`rm -rf` ⚠️ powerful)
- `cp` – copy files
- `mv` – move/rename files
- `tree` – view directory structure (very useful for projects)

---

## 📄 File Viewing & Editing

- `cat` – display file contents
- `less` / `more` – scroll through files (better than `cat` for large files)
- `head` / `tail` – view start/end of files
- `tail -f` – live log monitoring (very common)
- `nano` / `vim` – terminal editors

---

## 🔍 Text Processing (very powerful combo tools)

- `awk` – pattern scanning & processing
- `sed` – stream editing (search/replace)
- `cut` – extract columns
- `sort` – sort lines
- `uniq` – remove duplicates
- `wc` – count lines/words

👉 Example:

```bash
cat file.txt | grep error | sort | uniq -c
```

---

## ⚙️ Process & System Monitoring

- `top` / `htop` – monitor system processes
- `ps` – show running processes
- `kill` / `killall` – stop processes
- `df` – disk usage
- `du` – folder size
- `free` – memory usage
- `uptime` – system load

---

## 🌐 Networking

- `curl` – make HTTP requests (super important for devs)
- `wget` – download files
- `ping` – test connectivity
- `netstat` / `ss` – network stats
- `ssh` – remote login
- `scp` / `rsync` – transfer files

---

## 📦 Package & System Management

(Depends on distro)

- `apt`, `apt-get` – Debian/Ubuntu
- `yum` / `dnf` – RHEL/Fedora
- `pacman` – Arch

---

## 🔐 Permissions & Ownership

- `chmod` – change permissions
- `chown` – change ownership

---

## 🧠 Shell Productivity Boosters

- `alias` – create shortcuts
- `clear` – clear terminal
- `xargs` – pass output as arguments
- `watch` – run command repeatedly
- `which` – locate a command
- `whereis` – find binaries

---

## 🔥 Very Common Power Combos

- Pipes: `|`
- Redirect:
  - `>` overwrite
  - `>>` append

- Background jobs: `&`
- Command chaining:
  - `&&` (run if success)
  - `||` (run if fail)

---

## 🧑‍💻 Developer-Focused Essentials

- `git` – version control (you’ll use this daily)
- `make` – build automation
- `tar` / `zip` / `unzip` – archives
- `env` / `export` – environment variables

---

## 💡 Underrated but VERY Useful

- `fzf` – fuzzy finder (huge productivity boost)
- `bat` – better `cat` with syntax highlighting
- `exa` / `eza` – modern `ls`
- `ripgrep (rg)` – faster `grep`

---

If you want, I can give you a **“top 20 commands every developer actually uses daily”** or a **cheat sheet tailored for backend/devops work**.

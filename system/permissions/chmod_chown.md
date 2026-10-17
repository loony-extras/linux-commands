Here’s a **combined `chmod` + `chown` quick-reference table** you can use for real-world tasks and interviews:

---

## 📊 chmod vs chown (At a Glance)

| Command | What it Controls       | Example                 | Purpose                    |
| ------- | ---------------------- | ----------------------- | -------------------------- |
| chmod   | Permissions (rwx)      | `chmod 755 file`        | Who can read/write/execute |
| chown   | Ownership (user/group) | `chown user:group file` | Who owns the file          |

---

## 🧩 Combined Syntax Overview

| Task                     | Command Example                           |
| ------------------------ | ----------------------------------------- |
| Change owner             | `chown user file.txt`                     |
| Change group             | `chown :group file.txt`                   |
| Change permissions       | `chmod 644 file.txt`                      |
| Change both (separately) | `chown user:group file && chmod 755 file` |

---

## 🔢 Permissions + Ownership Together

| Scenario             | Ownership Command           | Permission Command    |
| -------------------- | --------------------------- | --------------------- |
| Private file         | `chown user:user file`      | `chmod 600 file`      |
| Shared group file    | `chown user:devs file`      | `chmod 660 file`      |
| Public readable file | `chown user:user file`      | `chmod 644 file`      |
| Executable script    | `chown user:user script.sh` | `chmod 755 script.sh` |
| Secure config file   | `chown root:root config`    | `chmod 600 config`    |

---

## 📁 Directory Use Cases

| Scenario                     | Command Combination                                             |
| ---------------------------- | --------------------------------------------------------------- |
| Project folder (team access) | `chown -R user:devs project/` + `chmod -R 775 project/`         |
| Web server directory         | `chown -R www-data:www-data /var/www` + `chmod -R 755 /var/www` |
| Shared temp folder           | `chown root:root /shared` + `chmod 1777 /shared`                |

---

## ⚙️ Common Admin Patterns

| Purpose                    | Command Example                                   |
| -------------------------- | ------------------------------------------------- |
| Fix permission issues      | `sudo chown -R user:user dir && chmod -R 755 dir` |
| Restrict access completely | `sudo chown root:root file && chmod 600 file`     |
| Allow group collaboration  | `chown user:team file && chmod 664 file`          |

---

## 🔐 Quick Permission Guide

| Number | Meaning |
| ------ | ------- |
| 7      | rwx     |
| 6      | rw-     |
| 5      | r-x     |
| 4      | r--     |

---

## 🧠 Rule of Thumb

| Goal               | Use This Combination                 |
| ------------------ | ------------------------------------ |
| Secure file        | `chown user:user` + `chmod 600`      |
| Share within group | `chown user:group` + `chmod 660/770` |
| Public read-only   | `chown user:user` + `chmod 644`      |
| Executable         | `chmod +x` or `755`                  |

---

If you want, I can turn this into a **real-world scenario walkthrough (like fixing a broken Node.js app or deploying a backend)** so you actually _feel_ how these are used in practice.

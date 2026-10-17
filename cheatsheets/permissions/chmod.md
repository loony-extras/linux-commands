The `chmod` command in Linux is used to **change file and directory permissions**—basically controlling who can read, write, or execute something.

Here’s a clear breakdown of what you can do with it:

---

## 🔑 1. Set Basic Permissions (Read, Write, Execute)

Each file has 3 permission types:

- **r (read)** → view file contents
- **w (write)** → modify file
- **x (execute)** → run file as a program

Example:

```bash
chmod u+x script.sh
```

👉 Gives the **user (owner)** permission to execute the file.

---

## 👥 2. Control Permissions for Different Users

You can target:

- `u` → user (owner)
- `g` → group
- `o` → others
- `a` → all

Example:

```bash
chmod g-w file.txt
```

👉 Removes write permission from the group.

---

## 🔢 3. Use Numeric (Octal) Mode

Permissions can also be set using numbers:

| Permission | Value |
| ---------- | ----- |
| Read       | 4     |
| Write      | 2     |
| Execute    | 1     |

Add them up:

- `7 = rwx`
- `6 = rw-`
- `5 = r-x`
- `4 = r--`

Example:

```bash
chmod 755 script.sh
```

👉 Owner: full access, others: read + execute

---

## 📁 4. Change Permissions Recursively

Apply changes to a directory and everything inside:

```bash
chmod -R 755 myfolder
```

---

## 🔒 5. Make Files Private or Public

- Private file:

```bash
chmod 600 secret.txt
```

- Public readable:

```bash
chmod 644 file.txt
```

---

## ⚙️ 6. Add or Remove Multiple Permissions

```bash
chmod u+rw,g+r,o-r file.txt
```

👉 Fine-grained control in one command.

---

## 🚀 7. Make Scripts Executable

Very common use case:

```bash
chmod +x script.sh
```

---

## 🧩 8. Special Permissions (Advanced)

### 🔹 Setuid (run as owner)

```bash
chmod u+s file
```

### 🔹 Setgid (inherit group)

```bash
chmod g+s directory
```

### 🔹 Sticky bit (protect deletion in shared dirs)

```bash
chmod +t /shared
```

---

## 🧠 Quick Real-World Examples

- Run a script → `chmod +x script.sh`
- Lock down config → `chmod 600 config.env`
- Web files → `chmod 755 folder`, `644 files`
- Shared directory → `chmod 1777 /tmp-like-dir`

---

Here’s a clean table-style cheat sheet for `chmod` usage:

---

## 📊 chmod Permission Basics

| Symbol | Meaning | Value |
| ------ | ------- | ----- |
| r      | Read    | 4     |
| w      | Write   | 2     |
| x      | Execute | 1     |

---

## 👥 User Types

| Symbol | Who it Represents |
| ------ | ----------------- |
| u      | User (Owner)      |
| g      | Group             |
| o      | Others            |
| a      | All               |

---

## 🔢 Numeric Permission Examples

| Number | Permission | Meaning        |
| ------ | ---------- | -------------- |
| 7      | rwx        | Full access    |
| 6      | rw-        | Read + write   |
| 5      | r-x        | Read + execute |
| 4      | r--        | Read only      |
| 0      | ---        | No permission  |

---

## ⚙️ Common chmod Commands

| Command                | Description                        |
| ---------------------- | ---------------------------------- |
| `chmod +x file.sh`     | Make file executable               |
| `chmod 755 file.sh`    | Owner full, others read + execute  |
| `chmod 644 file.txt`   | Owner read/write, others read      |
| `chmod 600 file.txt`   | Only owner can read/write          |
| `chmod g-w file.txt`   | Remove write permission from group |
| `chmod u+rwx file.sh`  | Give full permissions to owner     |
| `chmod -R 755 folder/` | Recursive permission change        |

---

## 🔒 Special Permissions

| Command          | Name       | Purpose                            |
| ---------------- | ---------- | ---------------------------------- |
| `chmod u+s file` | Setuid     | Run file as owner                  |
| `chmod g+s dir`  | Setgid     | Files inherit group                |
| `chmod +t dir`   | Sticky bit | Prevent others from deleting files |

---

## 🧠 Common Real-World Use Cases

| Scenario             | Command Example              |
| -------------------- | ---------------------------- |
| Make script runnable | `chmod +x script.sh`         |
| Secure private file  | `chmod 600 secret.txt`       |
| Web server files     | `chmod 755 dir`, `644 files` |
| Shared temp folder   | `chmod 1777 /tmp`            |

---

If you want, I can also generate a **single-page printable cheat sheet** or explain how to _read permission strings like `-rwxr-xr--` step by step_.

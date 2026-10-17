Here’s a **clean, practical table cheat sheet** for the Linux `grep` command—focused on real-world usage:

---

# 📊 Linux `grep` Command – Complete Table

| Category              | Command / Option      | What it Does                      | Example                                       |                |
| --------------------- | --------------------- | --------------------------------- | --------------------------------------------- | -------------- |
| **Basic**             | `grep "pattern" file` | Search text in a file             | `grep "error" app.log`                        |                |
|                       | `grep pattern *`      | Search in multiple files          | `grep "main" *.c`                             |                |
| **Case Handling**     | `-i`                  | Case-insensitive search           | `grep -i "error" log.txt`                     |                |
|                       | `-v`                  | Invert match (exclude)            | `grep -v "debug" log.txt`                     |                |
| **Count & Display**   | `-c`                  | Count matches                     | `grep -c "error" log.txt`                     |                |
|                       | `-n`                  | Show line numbers                 | `grep -n "error" log.txt`                     |                |
|                       | `-o`                  | Show only matched text            | `grep -o "error" log.txt`                     |                |
| **Recursive Search**  | `-r`                  | Search in directories recursively | `grep -r "TODO" .`                            |                |
|                       | `-R`                  | Recursive (follow symlinks)       | `grep -R "config" .`                          |                |
| **File Filtering**    | `--include`           | Include specific files            | `grep -r "main" --include="*.c" .`            |                |
|                       | `--exclude`           | Exclude files                     | `grep -r "main" --exclude="*.log" .`          |                |
|                       | `--exclude-dir`       | Exclude directories               | `grep -r "main" --exclude-dir=node_modules .` |                |
| **Word Matching**     | `-w`                  | Match whole words only            | `grep -w "cat" file.txt`                      |                |
|                       | `-x`                  | Match whole line                  | `grep -x "hello world" file.txt`              |                |
| **Regex**             | `-E`                  | Extended regex (egrep)            | `grep -E "cat                                 | dog" file.txt` |
|                       | `-F`                  | Fixed string (no regex)           | `grep -F "a.b" file.txt`                      |                |
| **Context Lines**     | `-A n`                | Show n lines after match          | `grep -A 3 "error" log.txt`                   |                |
|                       | `-B n`                | Show n lines before match         | `grep -B 2 "error" log.txt`                   |                |
|                       | `-C n`                | Show n lines before & after       | `grep -C 2 "error" log.txt`                   |                |
| **Multiple Patterns** | `-e`                  | Multiple patterns                 | `grep -e "error" -e "fail" log.txt`           |                |
| **Binary Handling**   | `-a`                  | Treat binary as text              | `grep -a "text" file.bin`                     |                |
| **Quiet Mode**        | `-q`                  | No output, only exit code         | `grep -q "error" log.txt`                     |                |
| **Color Output**      | `--color=auto`        | Highlight matches                 | `grep --color=auto "error" log.txt`           |                |
| **Piping**            | `\|`                  | Use with other commands           | `ps aux \| grep nginx`                        |                |

---

# ⚡ Most Useful (Real-World Picks)

| Trick                                | Why it matters          |
| ------------------------------------ | ----------------------- |
| `grep -r "TODO" .`                   | Search across project   |
| `grep -i "error" log.txt`            | Ignore case issues      |
| `grep -v "debug" log.txt`            | Filter noise            |
| `grep -n "error"`                    | Debug with line numbers |
| `grep -E "error\|fail"`              | Multiple conditions     |
| `ps aux \| grep process`             | Find running processes  |
| `grep -C 3 "error"`                  | See context in logs     |
| `grep -r --exclude-dir=node_modules` | Faster search           |

---

If you want, I can take it further with:

- 🔥 **regex cheat sheet specifically for grep**
- ⚡ **real-world debugging workflows (logs, servers, codebases)**

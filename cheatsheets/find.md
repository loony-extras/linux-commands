Here’s a **clean, practical table cheat sheet** for the Linux `find` command—focused on real-world usage:

---

# 📊 Linux `find` Command – Complete Table

| Category               | Command / Option      | What it Does                    | Example                                          |
| ---------------------- | --------------------- | ------------------------------- | ------------------------------------------------ |
| **Basic**              | `find path`           | List all files & directories    | `find .`                                         |
|                        | `find path -name`     | Search by filename              | `find . -name "file.txt"`                        |
|                        | `-iname`              | Case-insensitive name search    | `find . -iname "file.txt"`                       |
| **By Type**            | `-type f`             | Find files only                 | `find . -type f`                                 |
|                        | `-type d`             | Find directories only           | `find . -type d`                                 |
|                        | `-type l`             | Find symbolic links             | `find . -type l`                                 |
| **By Size**            | `-size +n`            | Larger than size                | `find . -size +100M`                             |
|                        | `-size -n`            | Smaller than size               | `find . -size -10k`                              |
|                        | `-size n`             | Exact size                      | `find . -size 1G`                                |
| **By Time**            | `-mtime n`            | Modified _n_ days ago           | `find . -mtime 2`                                |
|                        | `-mtime +n`           | Modified more than _n_ days ago | `find . -mtime +7`                               |
|                        | `-mtime -n`           | Modified within _n_ days        | `find . -mtime -1`                               |
|                        | `-atime`              | Last accessed                   | `find . -atime -2`                               |
|                        | `-ctime`              | Metadata changed                | `find . -ctime +5`                               |
| **By Permissions**     | `-perm mode`          | Exact permission match          | `find . -perm 644`                               |
|                        | `-perm -mode`         | At least these permissions      | `find . -perm -755`                              |
| **By Owner**           | `-user`               | Find by user                    | `find . -user root`                              |
|                        | `-group`              | Find by group                   | `find . -group dev`                              |
| **Execute Actions**    | `-exec command {} \;` | Run command on each result      | `find . -name "*.log" -exec rm {} \;`            |
|                        | `-exec ... +`         | Faster batch execution          | `find . -name "*.txt" -exec rm {} +`             |
| **Delete Files**       | `-delete`             | Delete matched files            | `find . -name "*.tmp" -delete`                   |
| **Search Depth**       | `-maxdepth n`         | Limit directory depth           | `find . -maxdepth 2`                             |
|                        | `-mindepth n`         | Skip top levels                 | `find . -mindepth 1`                             |
| **Combine Conditions** | `-and` / `-a`         | Logical AND                     | `find . -type f -a -size +1M`                    |
|                        | `-or` / `-o`          | Logical OR                      | `find . -name "*.js" -o -name "*.ts"`            |
|                        | `!`                   | NOT condition                   | `find . ! -name "*.txt"`                         |
| **Regex Search**       | `-regex`              | Match regex pattern             | `find . -regex ".*\.log"`                        |
| **Empty Files**        | `-empty`              | Find empty files/dirs           | `find . -empty`                                  |
| **Print Options**      | `-print`              | Default output                  | `find . -print`                                  |
|                        | `-print0`             | Null-separated output           | Useful with `xargs`                              |
| **With xargs**         | `\| xargs`            | Pass results to commands        | `find . -name "*.log" \| xargs rm`               |
| **Ignore Paths**       | `-path`               | Match path                      | `find . -path "./node_modules/*"`                |
|                        | `-prune`              | Exclude directories             | `find . -path "./node_modules" -prune -o -print` |

---

# ⚡ Most Useful (Real-World Picks)

| Trick                                  | Why it matters          |
| -------------------------------------- | ----------------------- |
| `find . -name "*.log"`                 | Everyday file search    |
| `find . -type f -size +100M`           | Find large files        |
| `find . -mtime -1`                     | Recently modified files |
| `find . -name "*.tmp" -delete`         | Clean junk quickly      |
| `find . -name "*.log" -exec rm {} +`   | Safe bulk delete        |
| `find . -type f \| wc -l`              | Count files             |
| `find . -empty`                        | Clean empty files/dirs  |
| `find . -path "./node_modules" -prune` | Skip heavy dirs         |

---

If you want next level, I can show you:

- 🔥 **dangerous but powerful `find` one-liners**
- ⚡ **real dev use cases (logs, builds, cleanup, debugging)**

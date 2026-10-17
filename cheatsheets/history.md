Here’s a clean **table-style cheat sheet** of the Linux `history` command with practical usage:

---

# 📊 Linux `history` Command – Complete Table

| Category             | Command / Shortcut         | What it Does                          | Example                          |
| -------------------- | -------------------------- | ------------------------------------- | -------------------------------- |
| **Basic**            | `history`                  | Show all history                      | `history`                        |
|                      | `history n`                | Show last _n_ commands                | `history 20`                     |
| **Run Commands**     | `!n`                       | Run command by number                 | `!123`                           |
|                      | `!!`                       | Run last command                      | `!!`                             |
|                      | `!string`                  | Run last command starting with string | `!git`                           |
|                      | `!?string?`                | Run last command containing string    | `!?docker?`                      |
| **Reuse Arguments**  | `!$`                       | Last argument of previous command     | `cd !$`                          |
|                      | `!^`                       | First argument                        | `echo !^`                        |
|                      | `!*`                       | All arguments                         | `echo !*`                        |
| **Edit & Replace**   | `^old^new`                 | Replace text in last command          | `^vim^nano`                      |
| **Search**           | `Ctrl + r`                 | Reverse interactive search            | Press `Ctrl+r`                   |
|                      | `history \| grep text`     | Search history                        | `history \| grep ssh`            |
| **Delete/Clear**     | `history -d n`             | Delete specific entry                 | `history -d 123`                 |
|                      | `history -c`               | Clear current session                 | `history -c`                     |
|                      | `history -c && history -w` | Clear permanently                     | —                                |
| **Save/Load**        | `history -w`               | Write history to file                 | —                                |
|                      | `history -a`               | Append new entries                    | —                                |
|                      | `history -r`               | Read history file                     | —                                |
|                      | `history -n`               | Read new lines only                   | —                                |
| **Timestamps**       | `HISTTIMEFORMAT`           | Show timestamps                       | `export HISTTIMEFORMAT="%F %T "` |
| **Control Behavior** | `HISTSIZE`                 | Number of commands stored             | `HISTSIZE=1000`                  |
|                      | `HISTFILESIZE`             | File size limit                       | `HISTFILESIZE=2000`              |
|                      | `HISTCONTROL=ignoredups`   | Ignore duplicates                     | —                                |
|                      | `HISTCONTROL=ignorespace`  | Ignore commands starting with space   | —                                |
|                      | `HISTCONTROL=ignoreboth`   | Both of above                         | —                                |
| **Advanced**         | `!n:p`                     | Print command without running         | `!123:p`                         |
|                      | `!start-end`               | Run range of commands                 | `!100-105`                       |
| **File Location**    | `~/.bash_history`          | Where history is stored               | —                                |

---

# ⚡ Most Useful (Real-World Picks)

| Trick                                     | Why it matters                    |
| ----------------------------------------- | --------------------------------- |
| `Ctrl + r`                                | Fastest way to find past commands |
| `!!`                                      | Retry last command quickly        |
| `!$`                                      | Reuse last argument instantly     |
| `history \| grep`                         | Quick filtering                   |
| `HISTCONTROL=ignoreboth`                  | Keeps history clean               |
| `PROMPT_COMMAND="history -a; history -n"` | Sync history across terminals     |

---

If you want, I can turn this into:

- a **printable PDF cheat sheet**
- or a **perfect `.bashrc` config for developers**

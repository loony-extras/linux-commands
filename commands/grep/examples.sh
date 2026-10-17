#!/usr/bin/env bash
# =============================================================================
# grep — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### grep — Pattern search in files
# ---------------------------------------------------------------------------
grep "pattern" file.txt                    # Basic literal search
grep -i "error" file.txt                   # Case-insensitive
grep -r "TODO" ./src/                      # Recursive directory search
grep -rn "DEBUG" /var/log/                 # Recursive + line numbers
grep -rl "pattern" /etc/                   # List filenames only (not content)
grep -rL "pattern" /etc/*.conf             # Files that do NOT match
grep -c "ERROR" /var/log/syslog            # Count matching lines per file
grep -v "^#" config.conf                   # Invert: exclude comment lines
grep -v "^$" file.txt                      # Exclude empty lines
grep -A 5 "ERROR" app.log                  # 5 lines After match
grep -B 5 "ERROR" app.log                  # 5 lines Before match
grep -C 5 "ERROR" app.log                  # 5 lines Context (before + after)
grep -m 10 "pattern" file.txt              # Stop after 10 matches
grep -o "pattern" file.txt                 # Print only matching part (not whole line)
grep -h "pattern" file1 file2              # No filename prefix in multi-file search
grep -H "pattern" file.txt                 # Always show filename
grep -w "word" file.txt                    # Match whole words only
grep -x "exact line" file.txt              # Match entire line exactly
grep -f patterns.txt file.txt              # Read patterns from file
grep -e "err" -e "warn" -e "crit" log.txt # Multiple patterns (OR)
grep -E "err|warn|crit" log.txt            # Extended regex (ERE) — same as egrep
grep -P "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" file.txt  # Perl regex (IP address)
grep -F "literal.string" file.txt          # Fixed string — no regex (faster)
grep "^START" file.txt                     # Lines beginning with START
grep "END$" file.txt                       # Lines ending with END
grep "^$" file.txt                         # Empty lines
grep "." file.txt                          # Non-empty lines (any character)
grep -q "pattern" file.txt && echo "found" # Quiet: exit code only
grep --include="*.py" -r "import" .        # Recurse only in .py files
grep --exclude="*.log" -r "pattern" .      # Skip .log files
grep --exclude-dir=".git" -r "pattern" .   # Skip .git directory
# Grep with color (highlight match)
grep --color=always "ERROR" log.txt | less -R
# Count occurrences (not lines) — use -o + wc
grep -o "ERROR" log.txt | wc -l
# Extract all IP addresses from a file
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log | sort -u
# Extract all email addresses
grep -Eo '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' file.txt

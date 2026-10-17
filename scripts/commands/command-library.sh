#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — LINUX COMMAND MASTER LIBRARY
# =============================================================================
# A complete, categorized, annotated reference for every major Linux command.
# Suitable for sourcing, reading, or copying from directly.
# Every command block is self-contained and production-tested.
# Platform: Ubuntu 22.04 / Debian 12 / any systemd-based Linux.
#
# USAGE:
#   Read directly:   less scripts/commands/command-library.sh
#   Search section:  grep -A 30 "### awk" command-library.sh
#   Jump to section: grep -n "^# ====" command-library.sh
# =============================================================================

# =============================================================================
# SECTION 1 — BASIC COMMANDS
# =============================================================================

# ---------------------------------------------------------------------------
### ls — List directory contents
# ---------------------------------------------------------------------------
ls                              # Basic list
ls -l                           # Long format: perms, links, owner, group, size, date, name
ls -la                          # All files including hidden (dot-files)
ls -lh                          # Human-readable sizes (K, M, G)
ls -lt                          # Sort by modification time, newest first
ls -ltr                         # Sort by time, oldest first — best for log directories
ls -lS                          # Sort by file size, largest first
ls -lu                          # Sort by last access time
ls -lc                          # Sort by ctime (metadata change)
ls -R                           # Recursive — shows entire tree
ls -d */                        # List only directories in current path
ls -d /etc/*/                   # List subdirectories of /etc
ls -i                           # Show inode numbers
ls -n                           # Numeric UID/GID instead of names
ls -1                           # One entry per line (for scripts/pipes)
ls -F                           # Append type indicator: / = dir, * = exec, @ = link
ls -A                           # Almost-all: hidden files but not . and ..
ls --color=auto                 # Colorize output
ls --sort=size -lh              # Explicit sort: size, extension, version, time
ls -lhX                         # Sort by file extension
ls --time-style=full-iso -l     # ISO 8601 timestamps
ls -la /proc/1/fd/              # Open file descriptors for PID 1
ls -la /dev/disk/by-uuid/       # Disk devices by UUID

# ---------------------------------------------------------------------------
### cd — Change directory
# ---------------------------------------------------------------------------
cd /var/log                     # Absolute path
cd log                          # Relative path (from current dir)
cd ..                           # Parent directory
cd ../..                        # Two levels up
cd -                            # Toggle to previous directory (like alt-tab)
cd ~                            # Home directory of current user
cd ~username                    # Home directory of another user
cd "$HOME"                      # Same as cd ~ but works in scripts
# CDPATH — search path for cd (like PATH for executables)
export CDPATH=".:$HOME:$HOME/projects:/opt"
cd myproject                    # Searches CDPATH directories for "myproject"

# ---------------------------------------------------------------------------
### pwd — Print working directory
# ---------------------------------------------------------------------------
pwd                             # Current directory (may follow symlinks)
pwd -P                          # Physical path — resolves all symlinks
pwd -L                          # Logical path — uses $PWD variable (default)
echo "$PWD"                     # Same as pwd -L (shell variable)
echo "$OLDPWD"                  # Previous directory (what cd - uses)

# ---------------------------------------------------------------------------
### cp — Copy files and directories
# ---------------------------------------------------------------------------
cp file.txt backup.txt                          # Copy a file
cp file1.txt file2.txt /destination/           # Copy multiple files to a directory
cp -r /src/dir /dst/dir                        # Recursive copy (directory)
cp -a /src/dir /dst/dir                        # Archive: preserve ALL attributes
                                                # (-a = -dR --preserve=all)
cp -p file1 file2                              # Preserve permissions, timestamps, ownership
cp -u src/* dest/                              # Copy only if src is NEWER than dest
cp -n file1 file2                              # No-clobber: don't overwrite existing
cp -i file1 file2                              # Interactive: prompt before overwrite
cp -f file1 file2                              # Force: remove dest if can't open
cp -v file1 file2                              # Verbose: show what's copied
cp -l file1 hardlink                           # Create hard link instead of copy
cp -s file1 symlink                            # Create symbolic link
cp --parents src/a/b.txt dest/                 # Preserve full path: dest/src/a/b.txt
cp -T src dst                                  # Treat dst as a file, not a directory
cp --reflink=auto file1 file2                  # CoW copy (btrfs/xfs — instant, no data copy)
# Copy with progress bar (large files)
rsync -ah --progress sourcefile destfile

# ---------------------------------------------------------------------------
### mv — Move and rename
# ---------------------------------------------------------------------------
mv file.txt /tmp/               # Move file to /tmp/
mv file.txt renamed.txt         # Rename file in place
mv dir1/ dir2/                  # Rename directory
mv -i src dst                   # Interactive: prompt if dest exists
mv -n src dst                   # No-clobber: don't overwrite
mv -f src dst                   # Force: don't prompt
mv -v src dst                   # Verbose
mv -u src dst                   # Move only if src is newer
# Move multiple files to a directory
mv file1.txt file2.txt file3.txt /destination/
# Rename pattern (requires rename tool: apt install rename)
rename 's/\.txt$/.bak/' *.txt   # Rename all .txt to .bak
rename 's/ /_/g' *              # Replace spaces with underscores in all filenames
rename 's/^/prefix_/' *         # Add prefix to all files

# ---------------------------------------------------------------------------
### rm — Remove files and directories
# ---------------------------------------------------------------------------
rm file.txt                     # Delete a file
rm -i file.txt                  # Interactive: prompt for confirmation
rm -f file.txt                  # Force: no prompts, ignore nonexistent
rm -r directory/                # Recursive delete (removes non-empty dirs)
rm -rf /path/to/dir             # Recursive force — VERIFY PATH BEFORE RUNNING
rm -v file.txt                  # Verbose: show what's deleted
rm -- -dash-file.txt            # Delete file starting with - (use --)
rm ./-dash-file.txt             # Alternative: explicit relative path
# Safe alternatives to rm -rf:
trash-put file.txt              # Send to trash (apt install trash-cli)
shred -vzu file.txt             # Overwrite then delete (secure delete)
# Find and delete (always test with -print first)
find /tmp -name "*.tmp" -type f -print          # Test
find /tmp -name "*.tmp" -type f -delete         # Delete

# ---------------------------------------------------------------------------
### touch — Create files, update timestamps
# ---------------------------------------------------------------------------
touch newfile.txt               # Create empty file (or update mtime+atime if exists)
touch file1 file2 file3         # Create/update multiple files
touch -a file.txt               # Update access time only
touch -m file.txt               # Update modification time only
touch -t 202401151430 file.txt  # Set specific time: YYYYMMDDhhmm[.ss]
touch -d "2024-01-15 14:30:00" file.txt  # Set time from string
touch -r reference.txt target.txt        # Copy timestamps from reference file
# Use case: force Make to rebuild a target
touch Makefile                  # Makefile is "newer" → all targets rebuild

# ---------------------------------------------------------------------------
### mkdir — Create directories
# ---------------------------------------------------------------------------
mkdir newdir                    # Create directory
mkdir -p /path/to/nested/dir    # Create full path (no error if exists)
mkdir -m 750 secure_dir         # Create with specific permissions
mkdir -v newdir                 # Verbose
# Create dated directory structure
mkdir -p logs/$(date +%Y/%m/%d)

# ---------------------------------------------------------------------------
### cat — Concatenate and display files
# ---------------------------------------------------------------------------
cat file.txt                    # Display file
cat file1.txt file2.txt         # Concatenate two files
cat -n file.txt                 # Number all lines
cat -b file.txt                 # Number non-empty lines only
cat -A file.txt                 # Show all characters (tabs=^I, EOL=$)
cat -s file.txt                 # Squeeze multiple blank lines into one
cat -v file.txt                 # Show non-printing characters
cat > newfile.txt               # Create file from stdin (Ctrl+D to end)
cat >> file.txt                 # Append stdin to file
cat /dev/null > file.txt        # Truncate file to zero bytes

# ---------------------------------------------------------------------------
### head / tail — View file beginnings/ends
# ---------------------------------------------------------------------------
head file.txt                   # First 10 lines (default)
head -n 20 file.txt             # First 20 lines
head -c 1024 file.txt           # First 1024 bytes
head -n -5 file.txt             # All lines EXCEPT last 5

tail file.txt                   # Last 10 lines
tail -n 20 file.txt             # Last 20 lines
tail -c 1024 file.txt           # Last 1024 bytes
tail -f file.txt                # Follow: print new lines as they appear
tail -F file.txt                # Follow by name: handles log rotation
tail -n +10 file.txt            # Start from line 10 (skip first 9)
tail -f /var/log/syslog | grep ERROR  # Live filtered log monitoring

# ---------------------------------------------------------------------------
### wc — Word, line, character count
# ---------------------------------------------------------------------------
wc file.txt                     # Lines, words, bytes
wc -l file.txt                  # Line count only
wc -w file.txt                  # Word count only
wc -c file.txt                  # Byte count
wc -m file.txt                  # Character count (handles multi-byte)
wc -L file.txt                  # Length of longest line
# Count files in directory
ls /var/log | wc -l
# Count total lines in all Python files
find . -name "*.py" -exec cat {} + | wc -l

# ---------------------------------------------------------------------------
### less — Pager (read-only file viewer)
# ---------------------------------------------------------------------------
less file.txt                   # Open file in pager
less +G file.txt                # Open at end of file
less +F file.txt                # Follow mode (like tail -f)
less -N file.txt                # Show line numbers
less -S file.txt                # Don't wrap long lines (scroll horizontally)
less -i file.txt                # Case-insensitive search
less -p "pattern" file.txt      # Open and jump to first match
# Inside less:
# / pattern   = search forward
# ? pattern   = search backward
# n / N       = next / previous match
# g / G       = first / last line
# q           = quit
# &pattern    = only show matching lines (filter)
# F           = follow mode (like tail -f)

# ---------------------------------------------------------------------------
### ln — Create links
# ---------------------------------------------------------------------------
ln file.txt hardlink.txt        # Hard link: same inode, same data
ln -s /path/to/original link    # Symbolic link: reference by path
ln -sf /new/target existing_link # Force: update existing symlink
ln -v file.txt link.txt         # Verbose
readlink link                   # Show where symlink points
readlink -f link                # Show resolved absolute path
readlink -e link                # Resolved path (must exist)

# =============================================================================
# SECTION 2 — INTERMEDIATE COMMANDS
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

# ---------------------------------------------------------------------------
### awk — Pattern scanning and data transformation
# ---------------------------------------------------------------------------
# Syntax: awk 'pattern { action }' file
# Fields: $0=whole line, $1=first field, $NF=last field, NF=field count, NR=line number

awk '{print $1}' file.txt                  # Print first field (whitespace delimited)
awk '{print $NF}' file.txt                 # Print last field
awk '{print $1, $3}' file.txt             # Print fields 1 and 3
awk -F: '{print $1}' /etc/passwd           # Use : as field separator
awk -F',' '{print $2}' data.csv            # CSV: print second column
awk 'NR==5' file.txt                       # Print line 5 only
awk 'NR>=5 && NR<=10' file.txt            # Print lines 5 through 10
awk 'NR%2==0' file.txt                     # Print even-numbered lines
awk '/pattern/' file.txt                   # Print lines matching pattern (like grep)
awk '!/pattern/' file.txt                  # Print lines NOT matching
awk '$3 > 100' file.txt                    # Print if field 3 is numerically > 100
awk '$1 == "root"' /etc/passwd             # Exact string match on field 1
awk 'length > 80' file.txt                 # Lines longer than 80 characters
awk '{sum += $1} END {print sum}' nums.txt # Sum column 1
awk '{sum += $1; count++} END {print sum/count}' nums.txt  # Average
awk 'BEGIN {print "Start"} {print} END {print "End"}' file.txt
awk '!seen[$0]++' file.txt                 # Remove duplicate lines (preserve order)
awk '{print NR": "$0}' file.txt            # Number all lines
awk -F: '{printf "%-20s %s\n", $1, $3}' /etc/passwd   # Formatted output
awk '{a[$1]++} END {for (k in a) print k, a[k]}' file.txt  # Frequency count
awk -F: '$3>=1000 && $7!~/nologin|false/ {print $1}' /etc/passwd  # Regular users
# Multi-file with filename tracking
awk 'FNR==1 {print "=== " FILENAME " ==="}' file1 file2
# Conditional with regex
awk '/ERROR/ {errors++} /WARN/ {warns++} END {print "E:"errors" W:"warns}' app.log
# String operations
awk '{print toupper($0)}' file.txt         # Uppercase entire line
awk '{print substr($0, 1, 10)}' file.txt  # First 10 characters
awk '{gsub(/old/,"new"); print}' file.txt  # Global substitution (like sed s//g)
awk '{print length($0)}' file.txt          # Length of each line
# Process CSV: calculate total from column 3 where column 1 = "prod"
awk -F',' '$1=="prod" {sum+=$3} END {printf "Total: %.2f\n", sum}' data.csv
# Apache/nginx log: count requests per hour
awk '{print substr($4,14,5)}' access.log | sort | uniq -c
# Extract values from key=value pairs
awk -F'=' '{print $2}' config.ini
# Top N values
awk '{print $1}' data.txt | sort | uniq -c | sort -rn | head -10
# Join two files on a common field (like SQL JOIN)
awk 'NR==FNR {map[$1]=$2; next} $1 in map {print $0, map[$1]}' file1 file2

# ---------------------------------------------------------------------------
### sed — Stream editor (non-interactive find/replace/transform)
# ---------------------------------------------------------------------------
# Syntax: sed 'address command' file
# Addresses: line number, regex, N~M (every Mth line from N), $=last

sed 's/old/new/' file.txt                  # Replace first occurrence per line
sed 's/old/new/g' file.txt                 # Replace ALL occurrences per line
sed 's/old/new/gi' file.txt                # Case-insensitive replace all
sed 's/old/new/2' file.txt                 # Replace 2nd occurrence only
sed 's/old/new/gp' file.txt                # Replace + print matched lines
sed -i 's/old/new/g' file.txt             # In-place edit (modifies file directly)
sed -i.bak 's/old/new/g' file.txt         # In-place with .bak backup
sed -n 's/old/new/gp' file.txt            # Only print lines where substitution happened
sed '5d' file.txt                          # Delete line 5
sed '5,10d' file.txt                       # Delete lines 5 through 10
sed '/^#/d' file.txt                       # Delete comment lines (starting with #)
sed '/^$/d' file.txt                       # Delete empty lines
sed '/pattern/d' file.txt                  # Delete lines matching pattern
sed -n '5,10p' file.txt                    # Print lines 5–10 (suppress other output)
sed -n '/START/,/END/p' file.txt           # Print between START and END (inclusive)
sed '$d' file.txt                          # Delete last line
sed '1d' file.txt                          # Delete first line
sed 's/^/  /' file.txt                     # Add 2-space indent to every line
sed 's/ *$//' file.txt                     # Remove trailing whitespace
sed 's/^[[:space:]]*//' file.txt           # Remove leading whitespace
sed 's/^[[:space:]]*//;s/[[:space:]]*$//' file.txt  # Trim both sides
sed '/pattern/a\New line appended' file.txt   # Append after matching line
sed '/pattern/i\New line inserted' file.txt   # Insert before matching line
sed '/pattern/c\Replacement line' file.txt    # Replace matching line entirely
sed 'y/abc/ABC/' file.txt                  # Transliterate characters (like tr)
sed -n '1~2p' file.txt                     # Print every 2nd line starting at 1 (odd lines)
sed -n '0~2p' file.txt                     # Print every 2nd line starting at 0 (even)
sed -e 's/foo/bar/' -e 's/baz/qux/' file.txt  # Multiple expressions
sed -f script.sed file.txt                 # Read sed commands from a file
# Extract content between two patterns
sed -n '/BEGIN/,/END/{/BEGIN/!{/END/!p}}' file.txt
# Remove ANSI color codes
sed 's/\x1b\[[0-9;]*m//g' colored.txt
# Add line numbers
sed = file.txt | sed 'N;s/\n/\t/'
# Multi-line join: join continuation lines (ending with \)
sed ':a;/\\$/N;s/\\\n//;ta' file.txt

# ---------------------------------------------------------------------------
### find — Search for files in directory trees
# ---------------------------------------------------------------------------
find /path -name "*.log"                   # By filename pattern (case-sensitive)
find /path -iname "*.LOG"                  # Case-insensitive name match
find /path -name "file[0-9].txt"           # Shell glob in name
find /path -type f                         # Regular files only
find /path -type d                         # Directories only
find /path -type l                         # Symbolic links only
find /path -type b                         # Block devices
find /path -type c                         # Character devices
find /path -type p                         # Named pipes (FIFO)
find /path -type s                         # Sockets
find /path -size +100M                     # Files larger than 100MB
find /path -size -1k                       # Files smaller than 1KB
find /path -size +100M -size -1G           # Between 100MB and 1GB
find /path -empty                          # Empty files or directories
find /path -mtime -7                       # Modified within last 7 days
find /path -mtime +30                      # Modified more than 30 days ago
find /path -mtime 1                        # Modified exactly 1 day ago
find /path -mmin -60                       # Modified in last 60 minutes
find /path -atime -7                       # Accessed in last 7 days
find /path -ctime -7                       # inode changed in last 7 days
find /path -newer /etc/passwd              # Modified more recently than passwd
find /path -perm 644                       # Exact permission match
find /path -perm -644                      # AT LEAST these permissions set
find /path -perm /o+w                      # World-writable (any of these bits set)
find /path -perm -4000                     # SUID bit set
find /path -perm -2000                     # SGID bit set
find /path -user www-data                  # Owned by user
find /path -group developers               # Owned by group
find /path -nouser                         # No matching user (deleted user's files)
find /path -nogroup                        # No matching group
find /path -maxdepth 2                     # Descend at most 2 levels
find /path -mindepth 2                     # Skip top 2 levels
find /path -maxdepth 1 -type f             # Files in this directory only (not subdirs)
find /path -xdev                           # Don't cross filesystem boundaries
# Actions
find /path -name "*.tmp" -delete           # Find and delete (no confirmation!)
find /path -name "*.log" -exec ls -lh {} \;          # Execute for each file
find /path -name "*.log" -exec ls -lh {} +            # Batch execute (faster — fewer forks)
find /path -name "*.py"  -exec grep -l "TODO" {} +   # Find python files containing TODO
find /path -name "*.log" -exec gzip {} \;             # Compress each log
# Logical operators
find /path \( -name "*.log" -o -name "*.tmp" \)      # OR: log or tmp
find /path -name "*.sh" -a -perm -u+x                 # AND: .sh AND executable
find /path -not -name "*.log"                          # NOT: anything except .log
find /path ! -name "*.log"                             # Same (! = not)
# Complex real-world examples
find /var/log -name "*.gz" -mtime +30 -delete          # Delete compressed logs > 30 days
find / -xdev -perm -4000 -type f 2>/dev/null           # Find all SUID binaries
find /home -name "authorized_keys" -type f             # Find SSH authorized_keys
find . -name "*.py" -newer requirements.txt            # Changed since requirements
find /tmp -maxdepth 1 -mtime +1 -exec rm -rf {} +     # Clean old temp files
find . -name "*.txt" -print0 | xargs -0 grep "pattern" # Handle spaces in names

# ---------------------------------------------------------------------------
### xargs — Build and execute commands from stdin
# ---------------------------------------------------------------------------
find /path -name "*.log" | xargs rm                    # Delete found files
find /path -name "*.conf" | xargs grep -l "port 80"   # Search inside found files
echo "file1 file2 file3" | xargs ls -lh               # ls multiple files
find /path -name "*.py" | xargs wc -l                  # Count lines in all py files
cat urls.txt | xargs wget -P /downloads/               # Download all URLs
find /path -name "*.jpg" | xargs -I{} cp {} /backup/  # Rename pattern with {}
find /path -name "*.jpg" | xargs -I{} -P8 convert {} {}.thumb.jpg  # 8 parallel
echo "a b c d" | xargs -n 1 echo                       # One argument per invocation
echo "a b c d" | xargs -n 2 echo                       # Two arguments per invocation
cat file.txt | xargs -d'\n' rm                         # Delimiter: newline (not space)
find /path -print0 | xargs -0 grep "pattern"           # NUL-delimited (handles spaces)
find /path -print0 | xargs -0 -P4 gzip                 # 4 parallel gzip jobs
ls *.bak | xargs -r rm                                 # -r: don't run if no input
xargs -a filelist.txt rm                               # Read arguments from file
# Prompt before executing
echo "file.txt" | xargs -p rm
# Show what would be run (dry-run)
find /tmp -name "*.tmp" | xargs -t rm

# ---------------------------------------------------------------------------
### tar — Tape Archive (pack/unpack files)
# ---------------------------------------------------------------------------
# Create archives
tar -czf archive.tar.gz dir/               # Create gzip-compressed archive
tar -cjf archive.tar.bz2 dir/             # Create bzip2-compressed archive
tar -cJf archive.tar.xz dir/              # Create xz-compressed (best ratio)
tar -czf archive.tar.gz file1 file2 dir/  # Multiple sources
tar -cf archive.tar dir/                   # Uncompressed archive
tar -czf - dir/ > archive.tar.gz          # Write to stdout (for pipes)
# Extract archives
tar -xf archive.tar.gz                     # Extract (auto-detect compression)
tar -xzf archive.tar.gz                    # Explicit gzip extraction
tar -xf archive.tar.gz -C /destination/   # Extract to specific directory
tar -xf archive.tar.gz file.txt           # Extract single file
tar -xf archive.tar.gz --wildcards "*.conf"  # Extract by pattern
# Inspect archives
tar -tf archive.tar.gz                     # List contents without extracting
tar -tvf archive.tar.gz                    # Verbose list (permissions, sizes)
tar -xf archive.tar.gz --dry-run          # Show what would be extracted
# Advanced options
tar -czf archive.tar.gz dir/ \
  --exclude="*.log" \
  --exclude="node_modules" \
  --exclude=".git"                         # Exclude patterns
tar -czf archive.tar.gz --exclude-vcs dir/  # Exclude version control files
tar -rf archive.tar newfile.txt            # Append to existing (uncompressed only)
tar -uf archive.tar newfile.txt            # Update: add newer files only
tar -czf archive.tar.gz --numeric-owner dir/  # Use numeric UID/GID
# Incremental backup
tar -czf full.tar.gz --listed-incremental=/var/lib/backup.snar dir/
tar -czf incr.tar.gz --listed-incremental=/var/lib/backup.snar dir/  # Next run
# Stream over SSH (no temp file)
tar -czf - /var/www | ssh user@server 'cat > /backup/www.tar.gz'
# Pipe directly to remote tar
tar -czf - /var/www | ssh user@server 'tar -xzf - -C /var/www'
# Create tar and show progress
tar -czf archive.tar.gz dir/ | pv > archive.tar.gz

# ---------------------------------------------------------------------------
### gzip / bzip2 / xz / zstd — Compression tools
# ---------------------------------------------------------------------------
gzip file.txt                  # Compress (replaces file with file.txt.gz)
gzip -d file.txt.gz            # Decompress
gzip -k file.txt               # Keep original (don't replace)
gzip -9 file.txt               # Maximum compression (slowest)
gzip -1 file.txt               # Minimum compression (fastest)
gzip -l file.txt.gz            # List compression stats
gzip -t file.txt.gz            # Test integrity
gzip -c file.txt > out.gz      # Compress to stdout (keep original)
zcat file.txt.gz               # View compressed file without decompressing
zgrep "pattern" file.gz        # Search in compressed file
zdiff file1.gz file2.gz        # Diff compressed files
zless file.gz                  # Page through compressed file

bzip2 file.txt                 # Better compression than gzip, slower
bzip2 -d file.txt.bz2          # Decompress
bzip2 -k file.txt              # Keep original
bzcat file.bz2                 # View without decompressing
bzgrep "pattern" file.bz2      # Search in bzip2 file

xz file.txt                    # Best compression, slowest
xz -d file.txt.xz              # Decompress
xz -9 file.txt                 # Maximum compression
xz -T 4 file.txt               # Use 4 threads (parallel compression)
xzcat file.xz                  # View without decompressing

zstd file.txt                  # Fast compression (Zstandard — apt install zstd)
zstd -d file.txt.zst           # Decompress
zstd -19 file.txt              # High compression (level 1–22)
zstdcat file.txt.zst           # View without decompressing

# ---------------------------------------------------------------------------
### zip / unzip — Cross-platform archives
# ---------------------------------------------------------------------------
zip archive.zip file1 file2    # Create zip
zip -r archive.zip dir/        # Recursive (include directory)
zip -e secure.zip file.txt     # Encrypt with password (prompted)
zip -9 archive.zip file.txt    # Maximum compression
zip -j archive.zip /path/file  # Junk path (don't store directory structure)
zip -u archive.zip newfile.txt # Update: add/replace newer files
zip -d archive.zip oldfile.txt # Delete from archive
zip -m archive.zip file.txt    # Move: delete original after adding
unzip archive.zip              # Extract to current directory
unzip archive.zip -d /dest/    # Extract to specified directory
unzip -l archive.zip           # List contents
unzip -t archive.zip           # Test integrity
unzip -p archive.zip file.txt  # Extract to stdout (pipe)
unzip -o archive.zip           # Overwrite without prompting
unzip -n archive.zip           # Never overwrite existing files
unzip "archive.zip" "*.conf"   # Extract files matching pattern

# =============================================================================
# SECTION 3 — ADVANCED COMMANDS
# =============================================================================

# ---------------------------------------------------------------------------
### Process Management — ps, top, htop, nice, renice, kill
# ---------------------------------------------------------------------------

## ps — process snapshot
ps                              # Processes in current terminal
ps aux                          # All processes, user-oriented format
ps -ef                          # All processes, full format (PPID visible)
ps aux --sort=-%cpu             # Sort by CPU usage, highest first
ps aux --sort=-%mem             # Sort by memory usage
ps aux --sort=+pid              # Sort by PID ascending
ps -p 1234 -o pid,ppid,cmd,%cpu,%mem  # Specific PID, custom columns
ps -u www-data                  # Processes owned by user www-data
ps -C nginx                     # Processes named nginx
ps --ppid 1234                  # Child processes of PID 1234
ps -f --forest                  # Full format, process tree
ps -eLf                         # Show all threads (LWP column)
ps -o pid,ppid,pgid,sid,comm    # Process, parent, group, session, command
ps h -o pid --sort pid          # Just PIDs, sorted (for scripting)
# Key columns: PID, TTY, STAT (state), TIME, COMMAND
# STAT codes: R=running, S=sleeping, D=disk wait, Z=zombie, T=stopped

## top — interactive process monitor
top                             # Default view
top -b -n 1                     # Batch mode, single snapshot (for scripts)
top -b -n 5 -d 2                # 5 iterations, 2-second delay
top -p 1234,5678                # Monitor specific PIDs only
top -u www-data                 # Show only www-data's processes
top -H                          # Show individual threads
# Inside top (interactive keys):
# 1     = expand per-CPU stats
# P     = sort by CPU
# M     = sort by memory
# T     = sort by time
# k     = kill process (enter PID)
# r     = renice process
# q     = quit
# c     = toggle between command and full path
# V     = forest view
# l     = toggle load average line
# t     = cycle through CPU display styles
# m     = cycle through memory display styles
# f     = field management (add/remove columns)
# W     = save current settings to ~/.toprc

## htop — enhanced interactive monitor (apt install htop)
htop                            # Default (color, better UI than top)
htop -u www-data                # Filter by user
htop -p 1234,5678               # Specific PIDs
htop -d 20                      # Refresh delay in tenths of seconds
htop --sort-key=PERCENT_MEM     # Sort by memory

## nice — start process with adjusted priority
nice command                    # Default niceness: 10 (lower priority)
nice -n 10 make -j4             # Lower priority: +10 (range -20 to +19)
nice -n -5 ./critical-task      # Higher priority (negative, requires root)
nice -n 19 find / -name "*.log" # Lowest priority (barely uses CPU)

## renice — change priority of running process
renice -n 5 -p 1234             # Set niceness to 5 for PID 1234
renice -n 10 -u www-data        # Lower all www-data's processes
renice -n -5 -p 1234            # Higher priority (requires root)
renice +1 -p 1234               # Relative adjustment syntax (BSD compat)

## kill — send signals to processes
kill 1234                       # SIGTERM (15): request graceful shutdown
kill -15 1234                   # Same as above (explicit)
kill -9 1234                    # SIGKILL: force kill (no cleanup, uncatchable)
kill -1 1234                    # SIGHUP: reload config (nginx, sshd, etc.)
kill -2 1234                    # SIGINT: keyboard interrupt (like Ctrl+C)
kill -3 1234                    # SIGQUIT: quit with core dump
kill -18 1234                   # SIGCONT: continue stopped process
kill -19 1234                   # SIGSTOP: pause process (uncatchable)
kill -20 1234                   # SIGTSTP: keyboard stop (catchable, like Ctrl+Z)
kill -0 1234                    # Check if process exists (no signal sent)
kill -- -1234                   # Kill entire process group (negative PID)
kill -s TERM 1234               # Use signal name instead of number
killall nginx                   # Kill all processes named nginx
killall -9 python3              # Force kill all python3 processes
killall -u www-data             # Kill all processes by user
pkill nginx                     # Kill by name match (regex)
pkill -f "python app.py"        # Kill by full command line match
pkill -u www-data               # Kill all processes by user
pkill -g 1234                   # Kill by process group ID
pkill -9 -f "node server.js"    # Force kill by full command

## pgrep — find process IDs
pgrep nginx                     # All PIDs matching name
pgrep -f "python app.py"        # Match full command line
pgrep -l nginx                  # PID + name
pgrep -a nginx                  # PID + full command line
pgrep -u www-data               # All PIDs for user
pgrep -u www-data -l            # With names
pgrep -n nginx                  # Newest matching process only
pgrep -o nginx                  # Oldest matching process only
pgrep -c nginx                  # Count matching processes

## Process state and relationships
pstree                          # Process tree (visual)
pstree -p                       # Process tree with PIDs
pstree -u                       # Show owning user
pstree -a                       # Show command arguments
pstree 1234                     # Tree starting from PID 1234

# ---------------------------------------------------------------------------
### Networking Tools — ss, netstat, ip, curl, wget
# ---------------------------------------------------------------------------

## ss — socket statistics (modern replacement for netstat)
ss                              # All open sockets
ss -t                           # TCP sockets only
ss -u                           # UDP sockets only
ss -l                           # Listening sockets only
ss -a                           # All sockets (listening + connected)
ss -n                           # Numeric (don't resolve hostnames/ports)
ss -p                           # Show process using socket
ss -s                           # Summary statistics
ss -tlnp                        # TCP Listening Numeric with Process (most useful)
ss -ulnp                        # UDP Listening Numeric with Process
ss -tnp                         # TCP connected with process
ss -anp                         # All sockets with processes
ss -tlnp | grep :80             # Who is listening on port 80
ss -tnp | grep ESTABLISHED      # Established connections
ss -o state ESTABLISHED         # Show only established state
ss -o state TIME-WAIT           # TIME-WAIT sockets (indicates connection churn)
ss -o state CLOSE-WAIT          # CLOSE-WAIT (app not closing sockets)
ss -tnp dst 192.168.1.100       # Connections to specific remote host
ss -tnp dport = :443            # Connections to destination port 443
ss -tnp src :8080               # Connections from source port 8080
ss -4                           # IPv4 only
ss -6                           # IPv6 only
ss -r                           # Resolve hostnames
ss --timer                      # Show timer info (keepalive, retransmit)
ss -e                           # Extended info (UID, inode)
ss -m                           # Memory usage per socket
ss -info                        # Internal TCP info (retransmits, etc.)

## netstat (legacy — install: apt install net-tools)
netstat -tlnp                   # TCP listening with process
netstat -an                     # All connections (no hostname resolution)
netstat -rn                     # Routing table (numeric)
netstat -s                      # Protocol statistics
netstat -i                      # Interface statistics
netstat -c                      # Continuous output

## ip — network interface and routing management
ip link show                    # All interfaces with status
ip link show eth0               # Specific interface
ip link set eth0 up             # Bring interface up
ip link set eth0 down           # Bring interface down
ip addr show                    # Show all IP addresses
ip addr show eth0               # Specific interface's addresses
ip addr add 192.168.1.100/24 dev eth0   # Add IP address
ip addr del 192.168.1.100/24 dev eth0   # Remove IP address
ip route show                   # Routing table
ip route get 8.8.8.8            # Which route is used to reach 8.8.8.8
ip route add default via 192.168.1.1    # Default gateway
ip route add 10.0.0.0/8 via 10.1.1.1   # Static route
ip route del 10.0.0.0/8                 # Delete route
ip neigh show                   # ARP/neighbor table
ip neigh flush dev eth0         # Flush ARP cache for interface
ip -s link show eth0            # Interface statistics (bytes, errors, drops)
ip -br addr                     # Brief address table (compact)
ip -br link                     # Brief interface table

## curl — HTTP client and data transfer
curl http://example.com                     # GET request
curl -o output.html http://example.com      # Save to file
curl -O http://example.com/file.tar.gz      # Save with remote filename
curl -L http://example.com                  # Follow redirects
curl -I http://example.com                  # Headers only (HEAD request)
curl -i http://example.com                  # Headers + body
curl -v http://example.com                  # Verbose (shows TLS, headers, etc.)
curl -s http://example.com                  # Silent (no progress/errors)
curl -S http://example.com                  # Show errors even with -s
curl -f http://example.com                  # Fail silently on HTTP error (exit 22)
curl -# http://example.com                  # Progress bar instead of stats
curl --max-time 30 http://example.com       # Total timeout 30 seconds
curl --connect-timeout 10 http://example.com  # Connection timeout only
curl --retry 3 --retry-delay 5 http://example.com  # Retry failed requests
curl -X POST http://api.example.com/data    # POST request
curl -X PUT http://api.example.com/item/1   # PUT request
curl -X DELETE http://api.example.com/item/1  # DELETE request
curl -d '{"key":"value"}' -H "Content-Type: application/json" http://api.example.com
curl -F "file=@upload.txt" http://example.com/upload   # Upload file (multipart)
curl -F "image=@photo.jpg;type=image/jpeg" http://api.example.com/images
curl -u user:password http://example.com    # Basic authentication
curl -H "Authorization: Bearer TOKEN" http://api.example.com
curl -H "X-Custom-Header: value" http://example.com    # Custom header
curl -k https://self-signed.example.com     # Skip TLS verification (INSECURE)
curl --cacert /etc/ssl/certs/ca-bundle.crt https://example.com  # Custom CA
curl -c cookies.txt http://example.com      # Save cookies
curl -b cookies.txt http://example.com      # Send cookies from file
curl -b "session=abc123" http://example.com # Send inline cookie
# Show only status code and response time
curl -w "%{http_code} %{time_total}s\n" -o /dev/null -s http://example.com
# Multiple metrics
curl -w "Code: %{http_code}\nTime: %{time_total}s\nSize: %{size_download} bytes\n" \
  -o /dev/null -s http://example.com
# Download with rate limit
curl --limit-rate 1M -O http://example.com/bigfile.iso
# Resume download
curl -C - -O http://example.com/bigfile.iso
# Multiple URLs
curl http://example.com/{file1,file2,file3}.txt
curl http://example.com/item[1-100].html    # Range of URLs
# DNS over HTTPS
curl --doh-url https://cloudflare-dns.com/dns-query https://example.com
# View effective URL after redirects
curl -Ls -o /dev/null -w "%{url_effective}" http://short.url/xyz

## wget — file downloader
wget http://example.com/file.tar.gz            # Download file
wget -O output.tar.gz http://example.com/file  # Save with different name
wget -q http://example.com                     # Quiet mode
wget -nv http://example.com                    # Non-verbose (show errors only)
wget -b http://example.com/bigfile             # Background download
wget -c http://example.com/bigfile             # Resume incomplete download
wget --limit-rate=1M http://example.com/file   # Rate limit
wget -r -np http://example.com/docs/          # Recursive, no parent
wget -r -l 2 http://example.com               # Recursive, depth 2
wget -p http://example.com                     # Download page + all resources
wget --mirror http://example.com               # Mirror entire site
wget -i urls.txt                               # Download from URL list file
wget --spider http://example.com/file          # Check if file exists (no download)
wget --user=admin --password=pass http://example.com  # Authentication
wget -P /download/dir/ http://example.com/file # Save to directory

# ---------------------------------------------------------------------------
### System Monitoring — vmstat, iostat, free, uptime, sar
# ---------------------------------------------------------------------------

## vmstat — virtual memory statistics
vmstat                          # Single snapshot
vmstat 1                        # Update every 1 second (continuous)
vmstat 1 10                     # 1-second interval, 10 samples
vmstat -s                       # Summary table (all counters)
vmstat -d                       # Disk statistics
vmstat -p /dev/sda1             # Specific partition stats
vmstat -a                       # Active/inactive memory breakdown
vmstat -m                       # Slab allocator info
vmstat -t 1 5                   # Include timestamps
# Columns: r=runqueue, b=blocked, swpd=swap, free, buff, cache
# si=swap-in/s, so=swap-out/s (nonzero = memory pressure)
# us=user%, sy=system%, id=idle%, wa=iowait%, st=stolen(VM)%

## iostat — I/O statistics
iostat                          # CPU + disk summary
iostat -x                       # Extended disk stats (most useful)
iostat -xz 1 5                  # Extended, skip idle, 1s interval, 5 samples
iostat -d /dev/sda              # Specific device only
iostat -d -p /dev/sda           # Per-partition breakdown
iostat -k                       # Kilobytes (instead of blocks)
iostat -m                       # Megabytes
iostat -c                       # CPU stats only
iostat -t 1 5                   # Include timestamps
# Key columns: tps=transactions/s, kB_read/s, kB_wrtn/s
# %util=disk busy%, await=avg I/O wait ms, r_await, w_await
# svctm=avg service time, avgrq-sz=avg request size, avgqu-sz=avg queue length

## free — memory usage
free                            # Default (bytes on some systems)
free -h                         # Human-readable (K, M, G)
free -m                         # Megabytes
free -g                         # Gigabytes
free -k                         # Kilobytes
free -s 2                       # Refresh every 2 seconds
free -s 2 -c 5                  # Refresh 5 times then exit
free -t                         # Show totals row
free -w                         # Wide output (separate buffers and cache)
# Key columns:
# total: Physical RAM installed
# used: used = total - free - buff/cache
# free: completely unused
# shared: tmpfs
# buff/cache: kernel buffer + page cache (RECLAIMABLE)
# available: usable for new allocations = free + reclaimable cache

## uptime — system load and uptime
uptime                          # One-liner: time, users, 1/5/15min load
uptime -p                       # Human-readable: "up 3 days, 4 hours"
uptime -s                       # Start time: "2024-01-15 09:30:00"
# Load averages: number of processes wanting CPU
# On N-core system: load > N means queue is building up

## sar — system activity reporter (from sysstat)
sar                             # Default: CPU usage (reads collected data)
sar 1 5                         # Real-time: 1s interval, 5 samples
sar -u 1 5                      # CPU utilization
sar -r 1 5                      # Memory utilization
sar -d 1 5                      # Disk I/O per device
sar -n DEV 1 5                  # Network statistics per interface
sar -n EDEV 1 5                 # Network errors
sar -n SOCK 1 5                 # Socket statistics
sar -q 1 5                      # Queue length and load average
sar -W 1 5                      # Swapping statistics
sar -b 1 5                      # I/O and transfer rate
sar -A 1 5                      # All statistics
sar -f /var/log/sysstat/sa01    # Historical data from file
sar -u -f /var/log/sysstat/sa$(date +%d)  # Today's CPU data

## Additional monitoring tools
watch -n 2 'df -h'              # Run command every 2 seconds
watch -d -n 1 'ss -s'          # -d: highlight differences
dstat                           # Combined stats (apt install dstat)
dstat -cdngy                    # CPU, disk, net, page, system stats
nload eth0                      # Network bandwidth bar chart
glances                         # All-in-one monitor (apt install glances)

# ---------------------------------------------------------------------------
### Pipes, Redirection, File Descriptors
# ---------------------------------------------------------------------------

## Standard file descriptors:
# 0 = stdin  (keyboard)
# 1 = stdout (screen)
# 2 = stderr (screen, separate from stdout)

## Basic redirection
command > file.txt              # Redirect stdout to file (overwrite)
command >> file.txt             # Redirect stdout to file (append)
command 2> error.txt            # Redirect stderr to file
command 2>> error.txt           # Append stderr to file
command &> out.txt              # Redirect both stdout and stderr (bash)
command > out.txt 2>&1          # Same (POSIX compatible — order matters!)
command 2>&1 > out.txt          # WRONG order: stderr goes to original stdout
command < input.txt             # Redirect stdin from file
command 2>/dev/null             # Discard stderr
command > /dev/null 2>&1        # Discard everything
command | tee file.txt          # Pipe to file AND stdout
command | tee -a file.txt       # Pipe and append to file
command 1>&2                    # Redirect stdout to stderr (for error messages)

## Pipes
cmd1 | cmd2                     # Pipe stdout of cmd1 to stdin of cmd2
cmd1 |& cmd2                    # Pipe stdout AND stderr (bash 4+)
cmd1 2>&1 | cmd2                # POSIX: pipe stdout and stderr
cmd1 | cmd2 | cmd3              # Pipeline chain

## Process substitution (bash/zsh)
diff <(ls dir1) <(ls dir2)     # Compare listings without temp files
sort <(cat a.txt) <(cat b.txt) # Sort combined files
tee >(gzip > out.gz) >(wc -l)  # Write to multiple destinations
while read line; do echo "$line"; done < <(cmd)  # Loop over command output

## Here documents and here strings
cat << 'EOF' > config.txt       # Write literal block to file
key=value
debug=false
EOF

cat << EOF > config.txt         # Variable expansion happens inside
server=$HOSTNAME
date=$(date)
EOF

grep "pattern" <<< "search in this string"  # Here string: feed string to stdin
base64 <<< "encode this"

## Named pipes (FIFO)
mkfifo /tmp/mypipe              # Create named pipe
cat /tmp/mypipe &               # Reader (blocks waiting)
echo "hello" > /tmp/mypipe     # Writer (blocks until reader connects)
rm /tmp/mypipe                  # Remove pipe

## File descriptor manipulation
exec 3> output.txt              # Open fd 3 for writing
echo "line" >&3                 # Write to fd 3
exec 3>&-                       # Close fd 3
exec 4< input.txt               # Open fd 4 for reading
read -u 4 line                  # Read from fd 4
exec 4<&-                       # Close fd 4
exec 5<> file.txt               # Open fd 5 for read+write

## /dev/fd and /proc/self/fd
ls -la /proc/self/fd            # Open file descriptors for this process
ls /proc/1234/fd                # Open FDs for PID 1234

# =============================================================================
# SECTION 4 — EXPERT COMMANDS
# =============================================================================

# ---------------------------------------------------------------------------
### Bash Scripting — Loops, Functions, Conditionals, Error Handling
# ---------------------------------------------------------------------------

## Variables and parameter expansion
NAME="World"
echo "${NAME}"                  # Safe variable reference (always quote)
echo "${NAME:-default}"         # Use default if unset or empty
echo "${NAME:=default}"         # Assign default if unset or empty
echo "${NAME:?error message}"   # Abort with message if unset or empty
echo "${NAME:+alternate}"       # Use alternate if set; else empty
echo "${#NAME}"                 # Length of string
echo "${NAME^^}"                # Convert to uppercase (bash 4+)
echo "${NAME,,}"                # Convert to lowercase
echo "${NAME^}"                 # Capitalize first character
echo "${NAME:2:4}"              # Substring from pos 2, length 4
echo "${NAME::-2}"              # All except last 2 characters
echo "${NAME/old/new}"          # Replace first match
echo "${NAME//old/new}"         # Replace all matches
echo "${NAME/#prefix/}"         # Remove prefix if present
echo "${NAME/%suffix/}"         # Remove suffix if present
echo "${NAME%.*}"               # Strip shortest suffix match (. and after)
echo "${NAME%%.*}"              # Strip longest suffix match
echo "${NAME#*.}"               # Strip shortest prefix match (up to .)
echo "${NAME##*/}"              # Strip longest prefix (basename)
echo "${NAME%/*}"               # Strip suffix from / (dirname)

## readonly and unset
readonly PI=3.14159             # Cannot be changed or unset
unset NAME                      # Delete variable

## Arrays (indexed)
arr=("one" "two" "three")       # Define array
arr+=(four five)                # Append elements
echo "${arr[0]}"                # First element (0-indexed)
echo "${arr[-1]}"               # Last element
echo "${arr[@]}"                # All elements (each word-split separately)
echo "${arr[*]}"                # All elements as single string
echo "${#arr[@]}"               # Number of elements
echo "${!arr[@]}"               # All indices
unset arr[1]                    # Remove element at index 1
arr[0]="replaced"               # Replace element

## Associative arrays (bash 4+)
declare -A map
map[key1]="value1"
map["key with spaces"]="value2"
echo "${map[key1]}"
echo "${!map[@]}"               # All keys
echo "${map[@]}"                # All values
[[ -v map[key1] ]] && echo "key exists"  # Check key existence
unset map[key1]                 # Remove key

## Conditionals — [[ ]] preferred over [ ] in bash
if [[ -f /etc/passwd ]]; then
  echo "Regular file exists"
elif [[ -d /etc ]]; then
  echo "Directory exists"
else
  echo "Neither"
fi

# File tests
[[ -e path ]]   # exists (any type)
[[ -f path ]]   # regular file
[[ -d path ]]   # directory
[[ -l path ]]   # symbolic link
[[ -r path ]]   # readable
[[ -w path ]]   # writable
[[ -x path ]]   # executable
[[ -s path ]]   # non-empty file
[[ -p path ]]   # named pipe
[[ -S path ]]   # socket
[[ -b path ]]   # block device
[[ -c path ]]   # character device

# String tests
[[ -z "$str" ]]       # empty string
[[ -n "$str" ]]       # non-empty string
[[ "$a" == "$b" ]]    # string equality
[[ "$a" != "$b" ]]    # string inequality
[[ "$a" < "$b" ]]     # lexicographic less than
[[ "$a" > "$b" ]]     # lexicographic greater than
[[ "$str" =~ ^[0-9]+$ ]]  # regex match (result in BASH_REMATCH)

# Numeric tests
[[ $a -eq $b ]]       # equal
[[ $a -ne $b ]]       # not equal
[[ $a -lt $b ]]       # less than
[[ $a -le $b ]]       # less than or equal
[[ $a -gt $b ]]       # greater than
[[ $a -ge $b ]]       # greater than or equal
(( a > b ))           # arithmetic test (preferred for numbers)
(( a == b && c != d ))  # compound arithmetic test

# Compound conditions
[[ -f file && -r file ]]     # AND
[[ -f file || -l file ]]     # OR
[[ ! -f file ]]              # NOT

## Loops

# for loop — iterate list
for i in {1..10}; do echo "$i"; done
for i in {0..100..5}; do echo "$i"; done  # With step
for i in $(seq 1 10); do echo "$i"; done
for f in /etc/*.conf; do echo "$f"; done  # Glob expansion
for item in "apple" "banana" "cherry"; do echo "$item"; done

# C-style for loop
for ((i=0; i<10; i++)); do echo "$i"; done
for ((i=10; i>0; i-=2)); do echo "$i"; done

# while loop
count=0
while (( count < 10 )); do
  echo "$count"
  ((count++))
done

# Read lines from file
while IFS= read -r line; do
  echo "Processing: $line"
done < /etc/hosts

# Read lines from command output
while IFS= read -r line; do
  echo "$line"
done < <(find /var/log -name "*.log")

# until loop (opposite of while)
until [[ -f /tmp/done ]]; do
  sleep 1
done

# Loop control
for i in {1..10}; do
  [[ $i -eq 5 ]] && continue   # Skip to next iteration
  [[ $i -eq 8 ]] && break      # Exit loop
  echo "$i"
done

# Iterate over array
for item in "${arr[@]}"; do echo "$item"; done

# Iterate with index
for i in "${!arr[@]}"; do
  echo "Index $i: ${arr[$i]}"
done

## Functions
greet() {
  local name="${1:-World}"      # Local variables (don't pollute global scope)
  local greeting="Hello, $name!"
  echo "$greeting"
  return 0                      # Explicit return code (0=success)
}
greet "Alice"
result=$(greet "Bob")           # Capture output
echo "Exit code: $?"            # $? = exit code of last command

# Function with all features
process_file() {
  local file="$1"
  local output_dir="${2:-/tmp}"

  # Validate inputs
  [[ -z "$file" ]] && { echo "Usage: process_file <file> [output_dir]" >&2; return 1; }
  [[ -f "$file" ]] || { echo "File not found: $file" >&2; return 2; }
  [[ -d "$output_dir" ]] || mkdir -p "$output_dir"

  local basename
  basename=$(basename "$file" .txt)
  cp "$file" "${output_dir}/${basename}.bak"
  echo "Processed: $file → ${output_dir}/${basename}.bak"
}

## Error handling
set -euo pipefail               # Best practice for all scripts:
                                # -e: exit on error
                                # -u: error on unset variable
                                # -o pipefail: pipe fails if any command fails

# Trap for cleanup
cleanup() {
  local exit_code=$?
  echo "Script exiting with code: $exit_code"
  rm -f /tmp/lockfile           # Always clean up
  [[ $exit_code -ne 0 ]] && echo "Script FAILED" >&2
}
trap cleanup EXIT               # Run cleanup on any exit
trap 'echo "ERROR at line $LINENO" >&2' ERR  # Run on error

# Conditional error handling (when set -e is active)
command || true                 # Allow failure
command || { echo "Failed"; exit 1; }  # Custom error action
if ! command; then              # Test failure explicitly
  echo "command failed"
  exit 1
fi

## Arithmetic
result=$((3 * 4 + 2))          # Arithmetic expansion
((count++))                     # Increment in place
((total += 10))                 # Add to variable
let "x = 5 * 3"                # let command
x=$(echo "3.14 * 2" | bc)      # Floating point (bc)
x=$(python3 -c "print(3.14159 * 2)")  # Python for complex math

## String operations
str="Hello, World!"
echo "${#str}"                  # 13 (length)
echo "${str:7:5}"               # World (substr pos 7, len 5)
echo "${str,,}"                 # hello, world! (lowercase)
echo "${str^^}"                 # HELLO, WORLD! (uppercase)
echo "${str/World/Bash}"        # Hello, Bash! (replace)
printf '%s\n' "${str}" | tr 'a-z' 'A-Z'  # Uppercase via tr

# ---------------------------------------------------------------------------
### Job Control — bg, fg, nohup, disown, wait
# ---------------------------------------------------------------------------

## Background / foreground
command &                       # Run in background; prints [jobnum] PID
jobs                            # List active jobs
jobs -l                         # List with PIDs
fg                              # Bring most recent job to foreground
fg %1                           # Bring job 1 to foreground
fg %nginx                       # Bring job named 'nginx' to foreground
bg                              # Resume stopped job in background
bg %2                           # Resume job 2 in background
Ctrl+Z                          # Suspend foreground process (sends SIGTSTP)
Ctrl+C                          # Interrupt foreground process (sends SIGINT)
Ctrl+\                          # Quit with core dump (sends SIGQUIT)

## nohup — run immune to hangup (survive terminal close)
nohup ./long-job.sh &                           # Output goes to nohup.out
nohup ./long-job.sh > /var/log/job.log 2>&1 &  # Custom log file
echo "PID: $!"                                   # PID of last background command

## disown — detach from shell's job table
./long-job &
disown %1                       # Remove from job table (survives shell exit)
disown -h %1                    # Mark SIGHUP-immune but keep in table

## wait — wait for background jobs
./job1.sh & pid1=$!
./job2.sh & pid2=$!
./job3.sh & pid3=$!
wait $pid1 $pid2 $pid3          # Wait for all three
echo "All jobs done"
wait $pid1 || echo "job1 failed with $?"  # Check individual exit codes

# Parallel with error tracking
pids=()
for server in web-01 web-02 db-01; do
  ssh "$server" "apt-get upgrade -y" &
  pids+=($!)
done
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failed++))
done
echo "$failed server(s) failed"

## screen / tmux — terminal multiplexers (survive disconnections)
screen -S mysession             # Start named session
screen -ls                      # List sessions
screen -r mysession             # Reattach to session
screen -d -r mysession          # Detach and reattach
# Inside screen: Ctrl+A D = detach, Ctrl+A C = new window, Ctrl+A N = next window

tmux new -s mysession           # Start named tmux session
tmux ls                         # List sessions
tmux attach -t mysession        # Attach to session
tmux detach                     # Detach from session (Ctrl+B D)
# Inside tmux: Ctrl+B D=detach, Ctrl+B C=new window, Ctrl+B N=next, Ctrl+B %=split

# ---------------------------------------------------------------------------
### Cron Jobs and Scheduling
# ---------------------------------------------------------------------------

## crontab syntax:
# ┌───── minute (0-59)
# │ ┌───── hour (0-23)
# │ │ ┌───── day of month (1-31)
# │ │ │ ┌───── month (1-12)
# │ │ │ │ ┌───── day of week (0=Sun, 7=Sun)
# │ │ │ │ │
# * * * * *  command

crontab -e                      # Edit current user's crontab
crontab -l                      # List current crontab
crontab -r                      # Remove crontab (careful!)
crontab -l -u www-data          # List another user's crontab (root only)
crontab -u www-data -e          # Edit another user's crontab

# Schedule examples (as crontab entries):
# 0 2 * * *      /backup/run.sh          # Daily at 2:00 AM
# */5 * * * *    /check/service.sh       # Every 5 minutes
# 0 */4 * * *    /refresh/cache.sh       # Every 4 hours
# 0 9 * * 1-5    /notify/standup.sh     # Weekdays at 9 AM
# 0 0 1 * *      /archive/monthly.sh    # 1st of each month at midnight
# 0 0 * * 0      /run/weekly.sh         # Every Sunday at midnight
# @reboot        /start/daemon.sh        # At system boot
# @daily         /cleanup/logs.sh        # Daily (alias for 0 0 * * *)
# @weekly        /run/weekly.sh          # Weekly (0 0 * * 0)
# @monthly       /archive/month.sh       # Monthly (0 0 1 * *)
# @hourly        /check/health.sh        # Hourly (0 * * * *)

# System cron directories (for root-level tasks)
ls /etc/cron.{hourly,daily,weekly,monthly}/  # Drop scripts here

# Run job and email output only on failure
# 0 2 * * * /backup.sh || echo "Backup failed" | mail -s "BACKUP FAIL" admin@co.com

## at — run once at a specific time
at 2:30 AM tomorrow            # Interactive: type commands, Ctrl+D to submit
at 14:30 < script.sh           # Run script non-interactively
at now + 5 minutes             # Relative time
at next week                   # Relative: next week
at midnight                    # Tonight at midnight
atq                            # List pending jobs
at -l                          # Same as atq
atrm 3                         # Remove job #3
at -c 3                        # Show job #3's commands

## systemd timers (modern cron alternative — see docs/04)
systemctl list-timers          # Show all timers with next run time
systemctl start backup.timer   # Manually trigger timer

# ---------------------------------------------------------------------------
### Log Parsing Pipelines
# ---------------------------------------------------------------------------

## nginx access log analysis
LOG=/var/log/nginx/access.log
# Top 20 IPs by request count
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -20
# HTTP status distribution
awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn
# Top requested URLs
awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -20
# Total bandwidth served (bytes)
awk '{sum += $10} END {printf "Total: %.2f GB\n", sum/1073741824}' "$LOG"
# 5xx errors with URL and timestamp
awk '$9 ~ /^5[0-9][0-9]/ {print $4, $7, $9}' "$LOG" | sed 's/\[//'
# Requests per minute
awk '{print $4}' "$LOG" | cut -d: -f1-3 | sort | uniq -c

## /var/log/auth.log analysis
AUTH=/var/log/auth.log
# Failed SSH login attempts by IP
grep "Failed password" "$AUTH" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
# Successful logins
grep "Accepted" "$AUTH" | awk '{print $9, $11}' | sort | uniq -c
# sudo commands
grep "COMMAND=" "$AUTH" | awk -F'COMMAND=' '{print $2}' | sort | uniq -c | sort -rn

## Syslog / journald analysis
# Count log entries by priority
journalctl --since "1 hour ago" -o json | jq -r '.PRIORITY' | sort | uniq -c
# Services with most errors
journalctl -p err --since today | grep -oP '_SYSTEMD_UNIT=\K[^\s]+' | sort | uniq -c | sort -rn
# Kernel errors only
journalctl -k -p warning --since "1 day ago" | grep -v "ACPI"

## Application log analysis
# Count errors vs warnings
grep -cE "^.*ERROR" app.log; grep -cE "^.*WARN" app.log
# Error messages by type (frequency)
grep "ERROR" app.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -20
# Average response time from structured logs
grep "duration=" app.log | grep -oP 'duration=\K[0-9.]+' | \
  awk '{sum+=$1; count++} END {printf "Avg: %.2fms\n", sum/count}'
# Find the slowest requests
grep "duration=" app.log | grep -oP '.*duration=\K[0-9.]+ .*' | sort -rn | head -10
# Errors per 5-minute window
grep "ERROR" app.log | awk '{print $1, $2}' | cut -d: -f1-2 | \
  awk '{gsub(/:/, " "); m=int($4/5)*5; printf "%s %s:%02d\n", $1, $3, m}' | \
  sort | uniq -c

# =============================================================================
# SECTION 5 — EXTREME: ONE-LINERS, DEBUGGING, PERFORMANCE, KERNEL
# =============================================================================

# ---------------------------------------------------------------------------
### Automation One-Liners
# ---------------------------------------------------------------------------

# Show top 10 memory consumers with name
ps aux --sort=-%rss | awk 'NR<=10 {printf "%-20s %8.1f MB\n", $11, $6/1024}'

# Kill all processes owned by a user (use carefully)
pkill -u baduser; sleep 2; pkill -9 -u baduser

# Quickly find which process is listening on a port
fuser -n tcp 8080                          # PID using TCP port 8080
fuser -k 8080/tcp                          # Kill process using port 8080

# Add user with SSH key in one command
useradd -m -s /bin/bash john && \
  mkdir -p /home/john/.ssh && \
  echo "ssh-ed25519 AAAA..." > /home/john/.ssh/authorized_keys && \
  chmod 700 /home/john/.ssh && chmod 600 /home/john/.ssh/authorized_keys && \
  chown -R john:john /home/john/.ssh

# Find largest files, human-readable, sorted
find / -xdev -type f -printf '%s %p\n' 2>/dev/null | \
  sort -rn | head -20 | awk '{printf "%10.1f MB  %s\n", $1/1048576, $2}'

# Replace string in ALL files recursively (with backup)
grep -rl "old-string" /path/ | \
  xargs sed -i.bak 's/old-string/new-string/g'

# Archive and compress a directory, show progress
tar -cf - /var/www | pv -s $(du -sb /var/www | awk '{print $1}') | gzip > www.tar.gz

# Count files by extension in current directory tree
find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

# Watch a directory for changes (inotify)
inotifywait -m -r -e modify,create,delete,moved_to /var/www 2>/dev/null | \
  while read path action file; do
    echo "$(date): $action $path$file"
  done

# Quickly test if a port is open (no netcat needed)
(echo >/dev/tcp/hostname/80) &>/dev/null && echo open || echo closed

# One-liner HTTP server on port 8080
python3 -m http.server 8080

# Generate a strong random password
openssl rand -base64 24 | tr -d '/+='

# Base64 encode/decode
echo "my secret" | base64
echo "bXkgc2VjcmV0Cg==" | base64 -d

# Check SSL certificate expiry for a domain
echo | openssl s_client -connect example.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# One-liner system health snapshot
hostname && uptime && free -h | awk '/Mem/{print "RAM:",$3"/"$2}' && \
  df -h / | awk 'NR==2{print "Disk:",$3"/",$2,"("$5")"}' && \
  ss -s | grep TCP:

# Find all open network connections with process names
ss -tnp | awk 'NR>1 {print $5, $6}' | sort -k2

# Monitor a file for changes and react
while true; do
  inotifywait -e modify /etc/nginx/nginx.conf 2>/dev/null
  nginx -t && systemctl reload nginx && echo "nginx reloaded"
done

# Count unique IPs accessing your server in real time
watch -n 5 'ss -tnp | awk "NR>1{print \$5}" | cut -d: -f1 | sort | uniq -c | sort -rn | head -10'

# Find duplicate files by MD5 hash
find . -type f -exec md5sum {} + | sort | awk 'prev==$1{print $2" is duplicate of prev_file"} {prev=$1; prev_file=$2}'

# Create self-signed TLS certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj '/CN=localhost'

# Show disk I/O by process in real time (requires root)
iotop -o -b -n 3 | awk 'NR>2 && /[KMG]/ {print $NF, $(NF-3)}'

# Parallel SSH command execution
for host in web-01 web-02 db-01; do
  ssh -o StrictHostKeyChecking=yes -o ConnectTimeout=5 "$host" \
    "hostname && uptime" 2>&1 &
done; wait

# ---------------------------------------------------------------------------
### Debugging Commands — strace, ltrace, lsof
# ---------------------------------------------------------------------------

## strace — system call tracer
strace ls                               # Trace all syscalls for ls
strace -p 1234                          # Attach to running process (noninvasive)
strace -c ls                            # Count syscalls: summary table
strace -e trace=network curl google.com # Network syscalls only
strace -e trace=file ls /tmp           # File-related syscalls only
strace -e trace=read,write cat file.txt # Specific syscalls
strace -e trace=open,openat,read ls    # Open + read calls
strace -T ls                            # Show time spent in each call
strace -t ls                            # Timestamps on each line
strace -tt ls                           # Microsecond timestamps
strace -r ls                            # Relative timestamps
strace -o strace.out ls                 # Write to file (keeps stdout clean)
strace -f ls                            # Follow forks (trace child processes)
strace -ff -o trace.pid ls             # Follow forks, one file per PID
strace -s 200 ls                        # Larger string size (default 32 chars)
strace -e trace=signal kill 1234        # Signal-related syscalls
strace -e trace=process ls             # Process management calls (exec, fork, etc.)
# Useful one-liner: count syscalls for a command
strace -c -f ./myprogram 2>&1 | sort -k4 -rn | head -20
# Attach to nginx worker and see what it's reading
strace -p $(pgrep -n nginx) -e trace=read,write -s 1024 2>&1 | grep -v ^close

## ltrace — library call tracer
ltrace ./myprogram                      # Trace all library calls
ltrace -e malloc,free ./myprogram       # Specific library functions
ltrace -c ./myprogram                   # Summary count
ltrace -p 1234                          # Attach to process

## lsof — list open files (everything is a file in Linux)
lsof                                    # ALL open files (very long)
lsof -p 1234                            # Open files for PID
lsof -p 1234,5678                       # Multiple PIDs
lsof -u www-data                        # Files opened by user
lsof -i                                 # All network files/sockets
lsof -i :80                             # Processes using port 80
lsof -i :80 -i :443                     # Port 80 OR 443
lsof -i tcp                             # All TCP sockets
lsof -i tcp:22                          # TCP port 22 specifically
lsof -i @192.168.1.100                  # Connections to/from this IP
lsof -i 4                               # IPv4 only
lsof -i 6                               # IPv6 only
lsof +D /var/log                        # All files open under /var/log
lsof /var/log/syslog                    # Who has this file open
lsof -n                                 # No hostname resolution (faster)
lsof -P                                 # No port name resolution
lsof -nP                                # Both — fastest output
lsof -nP | grep LISTEN                  # Listening ports (like ss -tlnp)
lsof -nP | grep ESTABLISHED             # Established connections
lsof +L1                                # Deleted files still held open
                                        # (these hold disk space — find memory leaks)
lsof | awk '{print $1}' | sort | uniq -c | sort -rn | head -20  # Processes by open file count
lsof -a -u www-data -i                  # (-a = AND) user www-data AND network

## gdb — GNU Debugger (C/C++)
gdb ./program                           # Debug a program
gdb ./program core                      # Analyze core dump
gdb -p 1234                             # Attach to running process
# Inside gdb:
# r args     = run program with args
# bt         = backtrace (stack trace)
# bt full    = full backtrace with locals
# p variable = print variable value
# l          = list source code
# b function = set breakpoint at function
# n          = next line (step over)
# s          = step into function
# c          = continue
# q          = quit

## addr2line — convert address to source line
addr2line -e ./program 0x1234abcd       # Translate crash address to file:line

## objdump — object file inspection
objdump -d /usr/bin/ls | head -50       # Disassemble binary
objdump -t /usr/bin/ls | head -20       # Symbol table

## nm — list symbols from object files
nm -D /usr/lib/x86_64-linux-gnu/libc.so.6 | grep malloc  # Find symbol
nm -u ./program                         # Undefined symbols (dependencies)

## file — determine file type
file /usr/bin/ls                        # ELF info: 64-bit, dynamically linked
file *.txt *.sh *.py                    # Batch type detection
file -i document.pdf                    # MIME type

## strings — extract printable strings from binary
strings /usr/bin/ls | grep -i "version"
strings /proc/1234/mem                  # Strings from process memory
strings -n 8 binary                     # Minimum length 8 chars

## od — octal dump (inspect file bytes)
od -c file.txt                          # Character dump
od -x file.txt                          # Hex dump
od -A x -t x1z file.txt | head          # Hex dump with printable chars (like xxd)
xxd file.txt | head                     # Hex dump (more readable)
xxd -r hex.txt > binary                 # Reverse: hex → binary

# ---------------------------------------------------------------------------
### Performance Tracing — perf, eBPF, flamegraphs
# ---------------------------------------------------------------------------

## perf — Linux performance analysis tool (apt install linux-tools-common)
perf stat ls                            # Hardware event counts for a command
perf stat -d ls                         # Detailed hardware events
perf stat -a sleep 5                    # System-wide for 5 seconds
perf top                                # Real-time top by kernel/user symbol
perf top -p 1234                        # For specific PID
perf top -K                             # Kernel-only symbols
perf top -U                             # User-space only

# Recording and reporting
perf record ./myprogram                 # Record profile (saves perf.data)
perf record -F 99 ./myprogram           # 99 Hz sampling frequency
perf record -F 99 -g ./myprogram        # With call graph (for flamegraphs)
perf record -F 99 -g -p 1234 sleep 30  # Attach to running PID, 30 seconds
perf report                             # Interactive report from perf.data
perf report --stdio                     # Non-interactive text report
perf report --stdio | head -40          # Quick summary

# Script and annotate
perf script                             # Raw event output (for FlameGraph tools)
perf annotate function_name             # Source-level annotation

# Trace specific events
perf trace ls                           # Syscall trace (like strace but faster)
perf trace -p 1234                      # Trace running process
perf trace -e 'syscalls:sys_enter_openat' ls  # Specific syscall

# Count specific hardware events
perf stat -e cache-misses,cache-references,instructions,cycles ./myprogram
perf stat -e L1-dcache-loads,L1-dcache-load-misses,LLC-loads ./myprogram

# Flamegraph generation (Brendan Gregg's tools)
# git clone https://github.com/brendangregg/FlameGraph && cd FlameGraph
perf record -F 99 -g -p $(pgrep myapp) sleep 30
perf script | ./stackcollapse-perf.pl | ./flamegraph.pl > /tmp/flamegraph.svg
# Open flamegraph.svg in browser for visual profile

## bpftrace — eBPF tracing (apt install bpftrace)
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'
bpftrace -e 'kprobe:do_sys_open { printf("PID %d opened: %s\n", pid, str(arg1)); }'
bpftrace -e 'tracepoint:block:block_rq_complete { @ = hist(args->nr_sector * 512); }'  # Block I/O histogram
bpftrace -e 'profile:hz:99 { @[comm] = count(); } interval:s:5 { print(@); clear(@); }'  # CPU profiler
bpftrace -l 'tracepoint:syscalls:*'     # List all syscall tracepoints
bpftrace -l 'kprobe:tcp*'              # List TCP kernel probes

## tcpdump — packet capture and analysis
tcpdump -i eth0                         # All traffic on eth0
tcpdump -i any                          # All interfaces
tcpdump -i eth0 port 80                 # HTTP traffic only
tcpdump -i eth0 host 192.168.1.100     # To/from specific host
tcpdump -i eth0 src 192.168.1.100      # FROM specific host only
tcpdump -i eth0 dst 8.8.8.8            # TO specific host only
tcpdump -i eth0 -n                      # No hostname resolution
tcpdump -i eth0 -nn                     # No name or port resolution
tcpdump -i eth0 -v                      # Verbose (show more packet details)
tcpdump -i eth0 -vv                     # More verbose
tcpdump -i eth0 -X                      # Show packet contents in hex + ASCII
tcpdump -i eth0 -A                      # ASCII only (good for HTTP)
tcpdump -i eth0 -c 100                  # Capture 100 packets then stop
tcpdump -i eth0 -w capture.pcap         # Write to file (for Wireshark analysis)
tcpdump -r capture.pcap                 # Read from file
tcpdump -i eth0 'tcp[tcpflags] & tcp-syn != 0'  # SYN packets only
tcpdump -i eth0 'tcp[tcpflags] & (tcp-rst) != 0'  # RST packets (connection resets)
tcpdump -i eth0 'not port 22'           # Exclude SSH traffic
tcpdump -i eth0 'host A and not host B' # Compound filter

# ---------------------------------------------------------------------------
### Kernel Interaction Tools
# ---------------------------------------------------------------------------

## sysctl — kernel parameter management
sysctl -a                               # List ALL kernel parameters
sysctl -a 2>/dev/null | wc -l          # Count parameters (~1000+)
sysctl -a | grep net.ipv4              # Filter by prefix
sysctl net.ipv4.ip_forward             # Read a parameter
sysctl kernel.hostname                 # Read hostname from kernel
sysctl -w net.ipv4.ip_forward=1        # Set temporarily (lost on reboot)
sysctl -w net.core.somaxconn=65535     # Increase connection backlog
sysctl -p                              # Load /etc/sysctl.conf
sysctl -p /etc/sysctl.d/99-custom.conf # Load specific file
sysctl --system                        # Load all /etc/sysctl.d/ files

## /proc — process and kernel information (virtual filesystem)
cat /proc/cpuinfo                       # CPU model, cores, flags, MHz
cat /proc/meminfo                       # Detailed memory breakdown
cat /proc/version                       # Kernel version string
cat /proc/uptime                        # Seconds since boot + idle time
cat /proc/loadavg                       # Load avg + runqueue + last PID
cat /proc/filesystems                   # Registered filesystems
cat /proc/mounts                        # Current mounts
cat /proc/partitions                    # Block device partitions
cat /proc/swaps                         # Swap file/partition usage
cat /proc/interrupts                    # IRQ statistics per CPU
cat /proc/softirqs                      # Software interrupt statistics
cat /proc/net/arp                        # ARP table
cat /proc/net/route                     # Routing table (hex)
cat /proc/net/tcp                       # TCP connections (hex)
cat /proc/net/udp                       # UDP sockets (hex)
cat /proc/net/sockstat                  # Socket summary statistics
cat /proc/net/dev                       # Network interface statistics
cat /proc/mdstat                        # RAID array status
cat /proc/buddyinfo                     # Memory fragmentation
cat /proc/slabinfo                      # Kernel slab allocator
cat /proc/1/status                      # Init/systemd process status
cat /proc/1/cgroup                      # cgroup membership
cat /proc/self/fd/ | ls -la            # Current process's open FDs
cat /proc/self/limits                   # Current process limits
echo $(($(cat /proc/uptime | awk '{print int($1)}') / 86400)) # Uptime in days

## /sys — hardware and subsystem interfaces
cat /sys/block/sda/queue/scheduler      # I/O scheduler for sda
echo mq-deadline > /sys/block/sda/queue/scheduler  # Change I/O scheduler
cat /sys/block/sda/queue/rotational     # 1=HDD, 0=SSD
cat /sys/class/net/eth0/speed           # Link speed in Mbps
cat /sys/class/net/eth0/duplex         # full or half
cat /sys/class/net/eth0/carrier         # 1=link up, 0=no link
cat /sys/class/net/eth0/address         # MAC address
cat /sys/class/net/eth0/statistics/rx_bytes  # Bytes received
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor  # CPU governor
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/enabled  # Disable THP

## dmesg — kernel ring buffer
dmesg                                   # All kernel messages
dmesg -T                                # Human-readable timestamps
dmesg -H                                # Human-readable + colors (if supported)
dmesg -l err                            # Error level only
dmesg -l warn,err,crit,alert,emerg     # Multiple levels
dmesg -f kern                           # Kernel facility only
dmesg --follow                          # Live stream (like tail -f)
dmesg | grep -i "oom\|killed"           # OOM events
dmesg | grep -i "error\|fail"           # Hardware errors
dmesg | grep -i "link\|carrier"         # Network link events
dmesg | grep "sda"                      # Disk events
dmesg | grep "EXT4-fs\|XFS"            # Filesystem events
dmesg | grep "Call Trace"               # Kernel oops/panics

## modprobe — kernel module management
lsmod                                   # List loaded modules
lsmod | grep kvm                        # Check if KVM is loaded
modinfo tcp_bbr                         # Module description, params, depends
modprobe tcp_bbr                        # Load module (+ dependencies)
modprobe -r tcp_bbr                     # Remove module (+ unused dependencies)
modprobe -v tcp_bbr                     # Verbose load
modprobe --show-depends tcp_bbr         # Show what would be loaded
insmod /path/to/module.ko               # Direct insert (no dependency resolution)
rmmod module_name                       # Direct remove
echo "tcp_bbr" > /etc/modules-load.d/bbr.conf  # Load at boot
echo "options iwlwifi 11n_disable=1" > /etc/modprobe.d/iwlwifi.conf  # Module params
echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf     # Blacklist

## Hardware information tools
lshw                                    # List hardware (apt install lshw)
lshw -short                             # Compact view
lshw -class memory                      # Memory info only
lshw -class network                     # Network hardware
lspci                                   # PCI devices
lspci -v                                # Verbose PCI info
lspci -k                                # Show kernel driver
lsusb                                   # USB devices
lsusb -v                                # Verbose USB info
lscpu                                   # CPU architecture information
lsblk                                   # Block devices tree
lsblk -f                                # With filesystem info
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,UUID
dmidecode -t memory                     # Memory DIMMs (requires root)
dmidecode -t bios                       # BIOS information
dmidecode -t system                     # System info (manufacturer, model)
sensors                                 # CPU/GPU temperatures (apt install lm-sensors)
smartctl -H /dev/sda                    # Disk SMART health (apt install smartmontools)

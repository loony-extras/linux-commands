#!/usr/bin/env bash
# =============================================================================
# find — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

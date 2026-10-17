#!/usr/bin/env bash
# =============================================================================
# xargs — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

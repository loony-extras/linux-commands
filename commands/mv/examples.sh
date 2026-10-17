#!/usr/bin/env bash
# =============================================================================
# mv — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

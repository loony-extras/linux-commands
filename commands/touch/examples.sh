#!/usr/bin/env bash
# =============================================================================
# touch — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

#!/usr/bin/env bash
# =============================================================================
# tar — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

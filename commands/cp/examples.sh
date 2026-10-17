#!/usr/bin/env bash
# =============================================================================
# cp — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

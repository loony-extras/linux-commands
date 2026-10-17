#!/usr/bin/env bash
# =============================================================================
# ln — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

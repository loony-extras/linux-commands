#!/usr/bin/env bash
# =============================================================================
# rm — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

#!/usr/bin/env bash
# =============================================================================
# cat — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

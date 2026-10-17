#!/usr/bin/env bash
# =============================================================================
# wc — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

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

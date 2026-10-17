#!/usr/bin/env bash
# =============================================================================
# less — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### less — Pager (read-only file viewer)
# ---------------------------------------------------------------------------
less file.txt                   # Open file in pager
less +G file.txt                # Open at end of file
less +F file.txt                # Follow mode (like tail -f)
less -N file.txt                # Show line numbers
less -S file.txt                # Don't wrap long lines (scroll horizontally)
less -i file.txt                # Case-insensitive search
less -p "pattern" file.txt      # Open and jump to first match
# Inside less:
# / pattern   = search forward
# ? pattern   = search backward
# n / N       = next / previous match
# g / G       = first / last line
# q           = quit
# &pattern    = only show matching lines (filter)
# F           = follow mode (like tail -f)

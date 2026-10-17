#!/usr/bin/env bash
# =============================================================================
# sed — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### sed — Stream editor (non-interactive find/replace/transform)
# ---------------------------------------------------------------------------
# Syntax: sed 'address command' file
# Addresses: line number, regex, N~M (every Mth line from N), $=last

sed 's/old/new/' file.txt                  # Replace first occurrence per line
sed 's/old/new/g' file.txt                 # Replace ALL occurrences per line
sed 's/old/new/gi' file.txt                # Case-insensitive replace all
sed 's/old/new/2' file.txt                 # Replace 2nd occurrence only
sed 's/old/new/gp' file.txt                # Replace + print matched lines
sed -i 's/old/new/g' file.txt             # In-place edit (modifies file directly)
sed -i.bak 's/old/new/g' file.txt         # In-place with .bak backup
sed -n 's/old/new/gp' file.txt            # Only print lines where substitution happened
sed '5d' file.txt                          # Delete line 5
sed '5,10d' file.txt                       # Delete lines 5 through 10
sed '/^#/d' file.txt                       # Delete comment lines (starting with #)
sed '/^$/d' file.txt                       # Delete empty lines
sed '/pattern/d' file.txt                  # Delete lines matching pattern
sed -n '5,10p' file.txt                    # Print lines 5–10 (suppress other output)
sed -n '/START/,/END/p' file.txt           # Print between START and END (inclusive)
sed '$d' file.txt                          # Delete last line
sed '1d' file.txt                          # Delete first line
sed 's/^/  /' file.txt                     # Add 2-space indent to every line
sed 's/ *$//' file.txt                     # Remove trailing whitespace
sed 's/^[[:space:]]*//' file.txt           # Remove leading whitespace
sed 's/^[[:space:]]*//;s/[[:space:]]*$//' file.txt  # Trim both sides
sed '/pattern/a\New line appended' file.txt   # Append after matching line
sed '/pattern/i\New line inserted' file.txt   # Insert before matching line
sed '/pattern/c\Replacement line' file.txt    # Replace matching line entirely
sed 'y/abc/ABC/' file.txt                  # Transliterate characters (like tr)
sed -n '1~2p' file.txt                     # Print every 2nd line starting at 1 (odd lines)
sed -n '0~2p' file.txt                     # Print every 2nd line starting at 0 (even)
sed -e 's/foo/bar/' -e 's/baz/qux/' file.txt  # Multiple expressions
sed -f script.sed file.txt                 # Read sed commands from a file
# Extract content between two patterns
sed -n '/BEGIN/,/END/{/BEGIN/!{/END/!p}}' file.txt
# Remove ANSI color codes
sed 's/\x1b\[[0-9;]*m//g' colored.txt
# Add line numbers
sed = file.txt | sed 'N;s/\n/\t/'
# Multi-line join: join continuation lines (ending with \)
sed ':a;/\\$/N;s/\\\n//;ta' file.txt

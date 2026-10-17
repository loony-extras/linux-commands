#!/usr/bin/env bash
# =============================================================================
# awk — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### awk — Pattern scanning and data transformation
# ---------------------------------------------------------------------------
# Syntax: awk 'pattern { action }' file
# Fields: $0=whole line, $1=first field, $NF=last field, NF=field count, NR=line number

awk '{print $1}' file.txt                  # Print first field (whitespace delimited)
awk '{print $NF}' file.txt                 # Print last field
awk '{print $1, $3}' file.txt             # Print fields 1 and 3
awk -F: '{print $1}' /etc/passwd           # Use : as field separator
awk -F',' '{print $2}' data.csv            # CSV: print second column
awk 'NR==5' file.txt                       # Print line 5 only
awk 'NR>=5 && NR<=10' file.txt            # Print lines 5 through 10
awk 'NR%2==0' file.txt                     # Print even-numbered lines
awk '/pattern/' file.txt                   # Print lines matching pattern (like grep)
awk '!/pattern/' file.txt                  # Print lines NOT matching
awk '$3 > 100' file.txt                    # Print if field 3 is numerically > 100
awk '$1 == "root"' /etc/passwd             # Exact string match on field 1
awk 'length > 80' file.txt                 # Lines longer than 80 characters
awk '{sum += $1} END {print sum}' nums.txt # Sum column 1
awk '{sum += $1; count++} END {print sum/count}' nums.txt  # Average
awk 'BEGIN {print "Start"} {print} END {print "End"}' file.txt
awk '!seen[$0]++' file.txt                 # Remove duplicate lines (preserve order)
awk '{print NR": "$0}' file.txt            # Number all lines
awk -F: '{printf "%-20s %s\n", $1, $3}' /etc/passwd   # Formatted output
awk '{a[$1]++} END {for (k in a) print k, a[k]}' file.txt  # Frequency count
awk -F: '$3>=1000 && $7!~/nologin|false/ {print $1}' /etc/passwd  # Regular users
# Multi-file with filename tracking
awk 'FNR==1 {print "=== " FILENAME " ==="}' file1 file2
# Conditional with regex
awk '/ERROR/ {errors++} /WARN/ {warns++} END {print "E:"errors" W:"warns}' app.log
# String operations
awk '{print toupper($0)}' file.txt         # Uppercase entire line
awk '{print substr($0, 1, 10)}' file.txt  # First 10 characters
awk '{gsub(/old/,"new"); print}' file.txt  # Global substitution (like sed s//g)
awk '{print length($0)}' file.txt          # Length of each line
# Process CSV: calculate total from column 3 where column 1 = "prod"
awk -F',' '$1=="prod" {sum+=$3} END {printf "Total: %.2f\n", sum}' data.csv
# Apache/nginx log: count requests per hour
awk '{print substr($4,14,5)}' access.log | sort | uniq -c
# Extract values from key=value pairs
awk -F'=' '{print $2}' config.ini
# Top N values
awk '{print $1}' data.txt | sort | uniq -c | sort -rn | head -10
# Join two files on a common field (like SQL JOIN)
awk 'NR==FNR {map[$1]=$2; next} $1 in map {print $0, map[$1]}' file1 file2

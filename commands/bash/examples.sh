#!/usr/bin/env bash
# =============================================================================
# bash — annotated command examples
# Tier: 3 (Advanced), 4 (Expert)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### Pipes, Redirection, File Descriptors
# ---------------------------------------------------------------------------
## Standard file descriptors:
# 0 = stdin  (keyboard)
# 1 = stdout (screen)
# 2 = stderr (screen, separate from stdout)

## Basic redirection
command > file.txt              # Redirect stdout to file (overwrite)
command >> file.txt             # Redirect stdout to file (append)
command 2> error.txt            # Redirect stderr to file
command 2>> error.txt           # Append stderr to file
command &> out.txt              # Redirect both stdout and stderr (bash)
command > out.txt 2>&1          # Same (POSIX compatible — order matters!)
command 2>&1 > out.txt          # WRONG order: stderr goes to original stdout
command < input.txt             # Redirect stdin from file
command 2>/dev/null             # Discard stderr
command > /dev/null 2>&1        # Discard everything
command | tee file.txt          # Pipe to file AND stdout
command | tee -a file.txt       # Pipe and append to file
command 1>&2                    # Redirect stdout to stderr (for error messages)

## Pipes
cmd1 | cmd2                     # Pipe stdout of cmd1 to stdin of cmd2
cmd1 |& cmd2                    # Pipe stdout AND stderr (bash 4+)
cmd1 2>&1 | cmd2                # POSIX: pipe stdout and stderr
cmd1 | cmd2 | cmd3              # Pipeline chain

## Process substitution (bash/zsh)
diff <(ls dir1) <(ls dir2)     # Compare listings without temp files
sort <(cat a.txt) <(cat b.txt) # Sort combined files
tee >(gzip > out.gz) >(wc -l)  # Write to multiple destinations
while read line; do echo "$line"; done < <(cmd)  # Loop over command output

## Here documents and here strings
cat << 'EOF' > config.txt       # Write literal block to file
key=value
debug=false
EOF

cat << EOF > config.txt         # Variable expansion happens inside
server=$HOSTNAME
date=$(date)
EOF

grep "pattern" <<< "search in this string"  # Here string: feed string to stdin
base64 <<< "encode this"

## Named pipes (FIFO)
mkfifo /tmp/mypipe              # Create named pipe
cat /tmp/mypipe &               # Reader (blocks waiting)
echo "hello" > /tmp/mypipe     # Writer (blocks until reader connects)
rm /tmp/mypipe                  # Remove pipe

## File descriptor manipulation
exec 3> output.txt              # Open fd 3 for writing
echo "line" >&3                 # Write to fd 3
exec 3>&-                       # Close fd 3
exec 4< input.txt               # Open fd 4 for reading
read -u 4 line                  # Read from fd 4
exec 4<&-                       # Close fd 4
exec 5<> file.txt               # Open fd 5 for read+write

## /dev/fd and /proc/self/fd
ls -la /proc/self/fd            # Open file descriptors for this process
ls /proc/1234/fd                # Open FDs for PID 1234

# ---------------------------------------------------------------------------
### Bash Scripting — Loops, Functions, Conditionals, Error Handling
# ---------------------------------------------------------------------------
## Variables and parameter expansion
NAME="World"
echo "${NAME}"                  # Safe variable reference (always quote)
echo "${NAME:-default}"         # Use default if unset or empty
echo "${NAME:=default}"         # Assign default if unset or empty
echo "${NAME:?error message}"   # Abort with message if unset or empty
echo "${NAME:+alternate}"       # Use alternate if set; else empty
echo "${#NAME}"                 # Length of string
echo "${NAME^^}"                # Convert to uppercase (bash 4+)
echo "${NAME,,}"                # Convert to lowercase
echo "${NAME^}"                 # Capitalize first character
echo "${NAME:2:4}"              # Substring from pos 2, length 4
echo "${NAME::-2}"              # All except last 2 characters
echo "${NAME/old/new}"          # Replace first match
echo "${NAME//old/new}"         # Replace all matches
echo "${NAME/#prefix/}"         # Remove prefix if present
echo "${NAME/%suffix/}"         # Remove suffix if present
echo "${NAME%.*}"               # Strip shortest suffix match (. and after)
echo "${NAME%%.*}"              # Strip longest suffix match
echo "${NAME#*.}"               # Strip shortest prefix match (up to .)
echo "${NAME##*/}"              # Strip longest prefix (basename)
echo "${NAME%/*}"               # Strip suffix from / (dirname)

## readonly and unset
readonly PI=3.14159             # Cannot be changed or unset
unset NAME                      # Delete variable

## Arrays (indexed)
arr=("one" "two" "three")       # Define array
arr+=(four five)                # Append elements
echo "${arr[0]}"                # First element (0-indexed)
echo "${arr[-1]}"               # Last element
echo "${arr[@]}"                # All elements (each word-split separately)
echo "${arr[*]}"                # All elements as single string
echo "${#arr[@]}"               # Number of elements
echo "${!arr[@]}"               # All indices
unset arr[1]                    # Remove element at index 1
arr[0]="replaced"               # Replace element

## Associative arrays (bash 4+)
declare -A map
map[key1]="value1"
map["key with spaces"]="value2"
echo "${map[key1]}"
echo "${!map[@]}"               # All keys
echo "${map[@]}"                # All values
[[ -v map[key1] ]] && echo "key exists"  # Check key existence
unset map[key1]                 # Remove key

## Conditionals — [[ ]] preferred over [ ] in bash
if [[ -f /etc/passwd ]]; then
  echo "Regular file exists"
elif [[ -d /etc ]]; then
  echo "Directory exists"
else
  echo "Neither"
fi

# File tests
[[ -e path ]]   # exists (any type)
[[ -f path ]]   # regular file
[[ -d path ]]   # directory
[[ -l path ]]   # symbolic link
[[ -r path ]]   # readable
[[ -w path ]]   # writable
[[ -x path ]]   # executable
[[ -s path ]]   # non-empty file
[[ -p path ]]   # named pipe
[[ -S path ]]   # socket
[[ -b path ]]   # block device
[[ -c path ]]   # character device

# String tests
[[ -z "$str" ]]       # empty string
[[ -n "$str" ]]       # non-empty string
[[ "$a" == "$b" ]]    # string equality
[[ "$a" != "$b" ]]    # string inequality
[[ "$a" < "$b" ]]     # lexicographic less than
[[ "$a" > "$b" ]]     # lexicographic greater than
[[ "$str" =~ ^[0-9]+$ ]]  # regex match (result in BASH_REMATCH)

# Numeric tests
[[ $a -eq $b ]]       # equal
[[ $a -ne $b ]]       # not equal
[[ $a -lt $b ]]       # less than
[[ $a -le $b ]]       # less than or equal
[[ $a -gt $b ]]       # greater than
[[ $a -ge $b ]]       # greater than or equal
(( a > b ))           # arithmetic test (preferred for numbers)
(( a == b && c != d ))  # compound arithmetic test

# Compound conditions
[[ -f file && -r file ]]     # AND
[[ -f file || -l file ]]     # OR
[[ ! -f file ]]              # NOT

## Loops

# for loop — iterate list
for i in {1..10}; do echo "$i"; done
for i in {0..100..5}; do echo "$i"; done  # With step
for i in $(seq 1 10); do echo "$i"; done
for f in /etc/*.conf; do echo "$f"; done  # Glob expansion
for item in "apple" "banana" "cherry"; do echo "$item"; done

# C-style for loop
for ((i=0; i<10; i++)); do echo "$i"; done
for ((i=10; i>0; i-=2)); do echo "$i"; done

# while loop
count=0
while (( count < 10 )); do
  echo "$count"
  ((count++))
done

# Read lines from file
while IFS= read -r line; do
  echo "Processing: $line"
done < /etc/hosts

# Read lines from command output
while IFS= read -r line; do
  echo "$line"
done < <(find /var/log -name "*.log")

# until loop (opposite of while)
until [[ -f /tmp/done ]]; do
  sleep 1
done

# Loop control
for i in {1..10}; do
  [[ $i -eq 5 ]] && continue   # Skip to next iteration
  [[ $i -eq 8 ]] && break      # Exit loop
  echo "$i"
done

# Iterate over array
for item in "${arr[@]}"; do echo "$item"; done

# Iterate with index
for i in "${!arr[@]}"; do
  echo "Index $i: ${arr[$i]}"
done

## Functions
greet() {
  local name="${1:-World}"      # Local variables (don't pollute global scope)
  local greeting="Hello, $name!"
  echo "$greeting"
  return 0                      # Explicit return code (0=success)
}
greet "Alice"
result=$(greet "Bob")           # Capture output
echo "Exit code: $?"            # $? = exit code of last command

# Function with all features
process_file() {
  local file="$1"
  local output_dir="${2:-/tmp}"

  # Validate inputs
  [[ -z "$file" ]] && { echo "Usage: process_file <file> [output_dir]" >&2; return 1; }
  [[ -f "$file" ]] || { echo "File not found: $file" >&2; return 2; }
  [[ -d "$output_dir" ]] || mkdir -p "$output_dir"

  local basename
  basename=$(basename "$file" .txt)
  cp "$file" "${output_dir}/${basename}.bak"
  echo "Processed: $file → ${output_dir}/${basename}.bak"
}

## Error handling
set -euo pipefail               # Best practice for all scripts:
                                # -e: exit on error
                                # -u: error on unset variable
                                # -o pipefail: pipe fails if any command fails

# Trap for cleanup
cleanup() {
  local exit_code=$?
  echo "Script exiting with code: $exit_code"
  rm -f /tmp/lockfile           # Always clean up
  [[ $exit_code -ne 0 ]] && echo "Script FAILED" >&2
}
trap cleanup EXIT               # Run cleanup on any exit
trap 'echo "ERROR at line $LINENO" >&2' ERR  # Run on error

# Conditional error handling (when set -e is active)
command || true                 # Allow failure
command || { echo "Failed"; exit 1; }  # Custom error action
if ! command; then              # Test failure explicitly
  echo "command failed"
  exit 1
fi

## Arithmetic
result=$((3 * 4 + 2))          # Arithmetic expansion
((count++))                     # Increment in place
((total += 10))                 # Add to variable
let "x = 5 * 3"                # let command
x=$(echo "3.14 * 2" | bc)      # Floating point (bc)
x=$(python3 -c "print(3.14159 * 2)")  # Python for complex math

## String operations
str="Hello, World!"
echo "${#str}"                  # 13 (length)
echo "${str:7:5}"               # World (substr pos 7, len 5)
echo "${str,,}"                 # hello, world! (lowercase)
echo "${str^^}"                 # HELLO, WORLD! (uppercase)
echo "${str/World/Bash}"        # Hello, Bash! (replace)
printf '%s\n' "${str}" | tr 'a-z' 'A-Z'  # Uppercase via tr

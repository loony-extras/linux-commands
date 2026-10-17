#!/usr/bin/env bash
# =============================================================================
# Binary Tools — annotated command examples
# Tier: 5 (Extreme)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### gdb — GNU Debugger (C/C++)
# ---------------------------------------------------------------------------
gdb ./program                           # Debug a program
gdb ./program core                      # Analyze core dump
gdb -p 1234                             # Attach to running process
# Inside gdb:
# r args     = run program with args
# bt         = backtrace (stack trace)
# bt full    = full backtrace with locals
# p variable = print variable value
# l          = list source code
# b function = set breakpoint at function
# n          = next line (step over)
# s          = step into function
# c          = continue
# q          = quit

# ---------------------------------------------------------------------------
### addr2line — convert address to source line
# ---------------------------------------------------------------------------
addr2line -e ./program 0x1234abcd       # Translate crash address to file:line

# ---------------------------------------------------------------------------
### objdump — object file inspection
# ---------------------------------------------------------------------------
objdump -d /usr/bin/ls | head -50       # Disassemble binary
objdump -t /usr/bin/ls | head -20       # Symbol table

# ---------------------------------------------------------------------------
### nm — list symbols from object files
# ---------------------------------------------------------------------------
nm -D /usr/lib/x86_64-linux-gnu/libc.so.6 | grep malloc  # Find symbol
nm -u ./program                         # Undefined symbols (dependencies)

# ---------------------------------------------------------------------------
### file — determine file type
# ---------------------------------------------------------------------------
file /usr/bin/ls                        # ELF info: 64-bit, dynamically linked
file *.txt *.sh *.py                    # Batch type detection
file -i document.pdf                    # MIME type

# ---------------------------------------------------------------------------
### strings — extract printable strings from binary
# ---------------------------------------------------------------------------
strings /usr/bin/ls | grep -i "version"
strings /proc/1234/mem                  # Strings from process memory
strings -n 8 binary                     # Minimum length 8 chars

# ---------------------------------------------------------------------------
### od — octal dump (inspect file bytes)
# ---------------------------------------------------------------------------
od -c file.txt                          # Character dump
od -x file.txt                          # Hex dump
od -A x -t x1z file.txt | head          # Hex dump with printable chars (like xxd)
xxd file.txt | head                     # Hex dump (more readable)
xxd -r hex.txt > binary                 # Reverse: hex → binary

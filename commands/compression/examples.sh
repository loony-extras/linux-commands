#!/usr/bin/env bash
# =============================================================================
# compression — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### gzip / bzip2 / xz / zstd — Compression tools
# ---------------------------------------------------------------------------
gzip file.txt                  # Compress (replaces file with file.txt.gz)
gzip -d file.txt.gz            # Decompress
gzip -k file.txt               # Keep original (don't replace)
gzip -9 file.txt               # Maximum compression (slowest)
gzip -1 file.txt               # Minimum compression (fastest)
gzip -l file.txt.gz            # List compression stats
gzip -t file.txt.gz            # Test integrity
gzip -c file.txt > out.gz      # Compress to stdout (keep original)
zcat file.txt.gz               # View compressed file without decompressing
zgrep "pattern" file.gz        # Search in compressed file
zdiff file1.gz file2.gz        # Diff compressed files
zless file.gz                  # Page through compressed file

bzip2 file.txt                 # Better compression than gzip, slower
bzip2 -d file.txt.bz2          # Decompress
bzip2 -k file.txt              # Keep original
bzcat file.bz2                 # View without decompressing
bzgrep "pattern" file.bz2      # Search in bzip2 file

xz file.txt                    # Best compression, slowest
xz -d file.txt.xz              # Decompress
xz -9 file.txt                 # Maximum compression
xz -T 4 file.txt               # Use 4 threads (parallel compression)
xzcat file.xz                  # View without decompressing

zstd file.txt                  # Fast compression (Zstandard — apt install zstd)
zstd -d file.txt.zst           # Decompress
zstd -19 file.txt              # High compression (level 1–22)
zstdcat file.txt.zst           # View without decompressing

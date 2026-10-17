#!/usr/bin/env bash
# =============================================================================
# zip — annotated command examples
# Tier: 2 (Intermediate)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### zip / unzip — Cross-platform archives
# ---------------------------------------------------------------------------
zip archive.zip file1 file2    # Create zip
zip -r archive.zip dir/        # Recursive (include directory)
zip -e secure.zip file.txt     # Encrypt with password (prompted)
zip -9 archive.zip file.txt    # Maximum compression
zip -j archive.zip /path/file  # Junk path (don't store directory structure)
zip -u archive.zip newfile.txt # Update: add/replace newer files
zip -d archive.zip oldfile.txt # Delete from archive
zip -m archive.zip file.txt    # Move: delete original after adding
unzip archive.zip              # Extract to current directory
unzip archive.zip -d /dest/    # Extract to specified directory
unzip -l archive.zip           # List contents
unzip -t archive.zip           # Test integrity
unzip -p archive.zip file.txt  # Extract to stdout (pipe)
unzip -o archive.zip           # Overwrite without prompting
unzip -n archive.zip           # Never overwrite existing files
unzip "archive.zip" "*.conf"   # Extract files matching pattern

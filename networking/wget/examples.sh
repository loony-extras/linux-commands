#!/usr/bin/env bash
# =============================================================================
# wget — annotated command examples
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### wget — file downloader
# ---------------------------------------------------------------------------
wget http://example.com/file.tar.gz            # Download file
wget -O output.tar.gz http://example.com/file  # Save with different name
wget -q http://example.com                     # Quiet mode
wget -nv http://example.com                    # Non-verbose (show errors only)
wget -b http://example.com/bigfile             # Background download
wget -c http://example.com/bigfile             # Resume incomplete download
wget --limit-rate=1M http://example.com/file   # Rate limit
wget -r -np http://example.com/docs/          # Recursive, no parent
wget -r -l 2 http://example.com               # Recursive, depth 2
wget -p http://example.com                     # Download page + all resources
wget --mirror http://example.com               # Mirror entire site
wget -i urls.txt                               # Download from URL list file
wget --spider http://example.com/file          # Check if file exists (no download)
wget --user=admin --password=pass http://example.com  # Authentication
wget -P /download/dir/ http://example.com/file # Save to directory

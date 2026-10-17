#!/usr/bin/env bash
# =============================================================================
# mkdir — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### mkdir — Create directories
# ---------------------------------------------------------------------------
mkdir newdir                    # Create directory
mkdir -p /path/to/nested/dir    # Create full path (no error if exists)
mkdir -m 750 secure_dir         # Create with specific permissions
mkdir -v newdir                 # Verbose
# Create dated directory structure
mkdir -p logs/$(date +%Y/%m/%d)

#!/usr/bin/env bash
# =============================================================================
# pwd — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### pwd — Print working directory
# ---------------------------------------------------------------------------
pwd                             # Current directory (may follow symlinks)
pwd -P                          # Physical path — resolves all symlinks
pwd -L                          # Logical path — uses $PWD variable (default)
echo "$PWD"                     # Same as pwd -L (shell variable)
echo "$OLDPWD"                  # Previous directory (what cd - uses)

#!/usr/bin/env bash
# =============================================================================
# cd — annotated command examples
# Tier: 1 (Basic)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### cd — Change directory
# ---------------------------------------------------------------------------
cd /var/log                     # Absolute path
cd log                          # Relative path (from current dir)
cd ..                           # Parent directory
cd ../..                        # Two levels up
cd -                            # Toggle to previous directory (like alt-tab)
cd ~                            # Home directory of current user
cd ~username                    # Home directory of another user
cd "$HOME"                      # Same as cd ~ but works in scripts
# CDPATH — search path for cd (like PATH for executables)
export CDPATH=".:$HOME:$HOME/projects:/opt"
cd myproject                    # Searches CDPATH directories for "myproject"

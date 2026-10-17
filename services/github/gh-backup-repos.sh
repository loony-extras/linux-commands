#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Back up every GitHub repository of a user or organization
# =============================================================================
# Keeps a bare mirror (all branches, tags, refs) of each repo under DEST.
# First run clones with `git clone --mirror`; later runs fetch only changes.
# Restore a repo with:  git clone DEST/owner/repo.git
#
# Usage: bash gh-backup-repos.sh OWNER [OWNER...] [options]
#
# Options:
#   --dest DIR    Backup root (default: /var/backup/github)
#   --forks       Include forks (default: skip)
#   --archived    Include archived repos (default: include; --no-archived to skip)
#   --no-archived Skip archived repos
#   --wikis       Also mirror wikis
#   --https       Clone over HTTPS using gh's token (default: SSH)
#
# Needs: gh logged in (or GH_TOKEN) with read access to private repos you want.
# Schedule: e.g. daily from cron, or reuse system/backup's timer pattern.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DEST="/var/backup/github"
INCLUDE_FORKS=false
INCLUDE_ARCHIVED=true
INCLUDE_WIKIS=false
USE_HTTPS=false
OWNERS=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
ts()    { date +'%Y-%m-%d %H:%M:%S'; }
log()   { echo "$(ts) $*"; }
warn()  { echo "$(ts) [WARN] $*" >&2; }
error() { echo "$(ts) [ERROR] $*" >&2; exit 1; }

usage() { sed -n '/^# Usage:/,/^# Needs:/p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# git with gh as the credential helper (only matters for --https)
git_gh() { git -c credential.helper= -c 'credential.helper=!gh auth git-credential' "$@"; }

# Clone a mirror, or update it if it already exists. Returns non-zero on failure.
mirror() {
  local url="$1" path="$2"
  if [[ -d "$path" ]]; then
    git_gh -C "$path" remote set-url origin "$url"
    git_gh -C "$path" remote update --prune >/dev/null 2>&1
  else
    mkdir -p "$(dirname "$path")"
    git_gh clone --quiet --mirror "$url" "$path" 2>/dev/null
  fi
}

# ---------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dest)        DEST="${2:?--dest needs a directory}"; shift ;;
      --forks)       INCLUDE_FORKS=true ;;
      --archived)    INCLUDE_ARCHIVED=true ;;
      --no-archived) INCLUDE_ARCHIVED=false ;;
      --wikis)       INCLUDE_WIKIS=true ;;
      --https)       USE_HTTPS=true ;;
      -h|--help)     usage 0 ;;
      -*)            echo "Unknown option: $1" >&2; usage 1 ;;
      *)             OWNERS+=("$1") ;;
    esac
    shift
  done
  [[ ${#OWNERS[@]} -gt 0 ]] || usage 1
  for cmd in gh git jq; do
    command -v "$cmd" &>/dev/null || error "Missing: $cmd"
  done
  gh auth status &>/dev/null || error "gh is not logged in (run: gh auth login, or set GH_TOKEN)"
}

# ---------------------------------------------------------------------------
main() {
  parse_args "$@"
  export GIT_TERMINAL_PROMPT=0            # Never hang waiting for a password

  local ok=0 failed=0 skipped=0 owner
  for owner in "${OWNERS[@]}"; do
    log "Listing repositories of $owner"
    local list
    list=$(gh repo list "$owner" --limit 4000 \
      --json nameWithOwner,sshUrl,url,isFork,isArchived,hasWikiEnabled) \
      || error "Could not list repositories of $owner"

    while IFS=$'\t' read -r name ssh_url https_url is_fork is_archived has_wiki; do
      if [[ "$is_fork" == true && "$INCLUDE_FORKS" == false ]] \
         || [[ "$is_archived" == true && "$INCLUDE_ARCHIVED" == false ]]; then
        skipped=$((skipped + 1)); continue
      fi
      local url="$ssh_url"
      [[ "$USE_HTTPS" == true ]] && url="${https_url}.git"

      if mirror "$url" "$DEST/$name.git"; then
        ok=$((ok + 1)); log "OK      $name"
      else
        failed=$((failed + 1)); warn "FAILED  $name ($url)"
      fi

      if [[ "$INCLUDE_WIKIS" == true && "$has_wiki" == true ]]; then
        # A wiki that was never edited has no git repo: ignore failures
        mirror "${url%.git}.wiki.git" "$DEST/$name.wiki.git" && log "OK      $name (wiki)" || true
      fi
    done < <(jq -r '.[] | [.nameWithOwner, .sshUrl, .url, .isFork, .isArchived, .hasWikiEnabled] | @tsv' <<<"$list")
  done

  log "Done: $ok mirrored, $failed failed, $skipped skipped → $DEST"
  [[ $failed -eq 0 ]]
}

main "$@"

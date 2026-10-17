#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — GitHub Actions self-hosted runner (systemd service)
# =============================================================================
# Downloads the latest actions/runner release, verifies its SHA-256, registers it
# with a repo or organization and installs it as a systemd service running as a
# dedicated unprivileged user.
#
# Usage:
#   sudo bash github-runner-setup.sh --repo owner/repo [options]
#   sudo bash github-runner-setup.sh --org myorg [options]
#   sudo bash github-runner-setup.sh --remove --repo owner/repo [--dir DIR]
#
# Options:
#   --name NAME      Runner name (default: hostname)
#   --labels L1,L2   Extra labels (default: none; self-hosted,linux,x64 are automatic)
#   --dir DIR        Install directory (default: /opt/actions-runner)
#   --user USER      Service user (default: github-runner)
#   --dry-run        Resolve version/checksum and print the steps; change nothing
#
# Registration token: taken from $RUNNER_TOKEN if set (Settings → Actions → Runners
# → New runner), otherwise requested with `gh api` (gh must be logged in as a repo
# admin, or with admin:org for --org).
#
# WARNING: never attach self-hosted runners to PUBLIC repositories — any fork's
# pull request could run code on this machine.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
RUNNER_DIR="/opt/actions-runner"
RUNNER_USER="github-runner"
RUNNER_NAME="$(hostname -s)"
RUNNER_LABELS=""
REPO="" ORG="" REMOVE=false DRY_RUN=false
RELEASE_API="https://api.github.com/repos/actions/runner/releases/latest"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
ts()    { date +'%Y-%m-%d %H:%M:%S'; }
log()   { echo "$(ts) $*"; }
warn()  { echo "$(ts) [WARN] $*" >&2; }
error() { echo "$(ts) [ERROR] $*" >&2; exit 1; }

usage() { sed -n '/^# Usage:/,/^# WARNING/p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# Run a command, or just print it with --dry-run
run() {
  if [[ "$DRY_RUN" == true ]]; then echo "  [dry-run] $*"; else "$@"; fi
}

# Run as the runner user (config.sh refuses to run as root)
as_runner() { run runuser -u "$RUNNER_USER" -- "$@"; }

target_path() { [[ -n "$ORG" ]] && echo "orgs/$ORG" || echo "repos/$REPO"; }
target_url()  { echo "https://github.com/${ORG:-$REPO}"; }

# Registration or removal token: $RUNNER_TOKEN, else gh api
get_token() {
  local kind="$1"     # registration-token | remove-token
  if [[ -n "${RUNNER_TOKEN:-}" ]]; then echo "$RUNNER_TOKEN"; return; fi
  command -v gh &>/dev/null || error "Set RUNNER_TOKEN or install and log in to gh"
  if [[ "$DRY_RUN" == true ]]; then echo "<token>"; return; fi
  gh api -X POST "$(target_path)/actions/runners/$kind" --jq .token \
    || error "Could not get a $kind (need repo admin, or admin:org for --org)"
}

# ---------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)    REPO="${2:?--repo needs owner/repo}"; shift ;;
      --org)     ORG="${2:?--org needs a name}"; shift ;;
      --name)    RUNNER_NAME="${2:?}"; shift ;;
      --labels)  RUNNER_LABELS="${2:?}"; shift ;;
      --dir)     RUNNER_DIR="${2:?}"; shift ;;
      --user)    RUNNER_USER="${2:?}"; shift ;;
      --remove)  REMOVE=true ;;
      --dry-run) DRY_RUN=true ;;
      -h|--help) usage 0 ;;
      *) echo "Unknown option: $1" >&2; usage 1 ;;
    esac
    shift
  done
  [[ -n "$REPO" || -n "$ORG" ]] || usage 1
  [[ -z "$REPO" || -z "$ORG" ]] || error "Use --repo or --org, not both"
  [[ -z "$REPO" || "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || error "--repo must be owner/repo"
  [[ "$DRY_RUN" == true || $EUID -eq 0 ]] || error "Run as root (or use --dry-run)"
  for cmd in curl jq tar sha256sum; do
    command -v "$cmd" &>/dev/null || error "Missing: $cmd"
  done
}

warn_if_public() {
  [[ -n "$REPO" ]] && command -v gh &>/dev/null || return 0
  local private
  private=$(gh api "repos/$REPO" --jq .private 2>/dev/null || echo unknown)
  if [[ "$private" == false ]]; then
    warn "$REPO is PUBLIC: pull requests from forks could run code on this host."
    warn "Use GitHub-hosted runners for public repos. Continuing in 10s (Ctrl-C to abort)..."
    [[ "$DRY_RUN" == true ]] || sleep 10
  fi
}

# ---------------------------------------------------------------------------
install_runner() {
  local arch
  case "$(uname -m)" in
    x86_64)  arch=x64 ;;
    aarch64) arch=arm64 ;;
    *) error "Unsupported architecture: $(uname -m)" ;;
  esac

  # Resolve latest version and its published checksum
  local release version file sha
  release=$(curl -fsSL "$RELEASE_API") || error "Could not query $RELEASE_API"
  version=$(jq -r '.tag_name | ltrimstr("v")' <<<"$release")
  file="actions-runner-linux-${arch}-${version}.tar.gz"
  sha=$(jq -r '.body' <<<"$release" | sed -n "s/.*BEGIN SHA linux-${arch} -->\([0-9a-f]\{64\}\)<.*/\1/p" | head -1)
  [[ -n "$sha" ]] || error "No checksum for $file in the release notes"
  log "Runner $version ($arch), sha256 $sha"

  warn_if_public

  # Service user
  if ! id "$RUNNER_USER" &>/dev/null; then
    run useradd --system --create-home --home-dir "/home/$RUNNER_USER" --shell /usr/sbin/nologin "$RUNNER_USER"
  fi

  # Download, verify, extract
  if [[ -x "$RUNNER_DIR/config.sh" ]]; then
    warn "$RUNNER_DIR already contains a runner — reusing it (use --remove first to reinstall)"
  else
    run mkdir -p "$RUNNER_DIR"
    local tmp="/tmp/$file"
    run curl -fsSL -o "$tmp" "https://github.com/actions/runner/releases/download/v${version}/${file}"
    if [[ "$DRY_RUN" == false ]]; then
      echo "$sha  $tmp" | sha256sum -c --quiet - || { rm -f "$tmp"; error "Checksum mismatch for $file"; }
    fi
    run tar xzf "$tmp" -C "$RUNNER_DIR"
    run rm -f "$tmp"
    run chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"
    run "$RUNNER_DIR/bin/installdependencies.sh"      # .NET runtime deps (libicu, etc.)
  fi

  # Register and install the service
  local token
  token=$(get_token registration-token)
  local args=(--unattended --url "$(target_url)" --token "$token" --name "$RUNNER_NAME" --work _work --replace)
  [[ -n "$RUNNER_LABELS" ]] && args+=(--labels "$RUNNER_LABELS")
  ( cd "$RUNNER_DIR" 2>/dev/null || [[ "$DRY_RUN" == true ]]
    as_runner ./config.sh "${args[@]}"
    run ./svc.sh install "$RUNNER_USER"
    run ./svc.sh start )

  log "Runner '$RUNNER_NAME' registered to $(target_url)"
  log "Check: systemctl list-units 'actions.runner.*'   and   Settings → Actions → Runners"
}

remove_runner() {
  [[ -x "$RUNNER_DIR/config.sh" || "$DRY_RUN" == true ]] || error "No runner in $RUNNER_DIR"
  local token
  token=$(get_token remove-token)
  ( cd "$RUNNER_DIR" 2>/dev/null || [[ "$DRY_RUN" == true ]]
    run ./svc.sh stop || true
    run ./svc.sh uninstall || true
    as_runner ./config.sh remove --token "$token" )
  log "Runner removed from $(target_url). Delete $RUNNER_DIR and user $RUNNER_USER if no longer needed."
}

# ---------------------------------------------------------------------------
main() {
  parse_args "$@"
  if [[ "$REMOVE" == true ]]; then remove_runner; else install_runner; fi
}

main "$@"

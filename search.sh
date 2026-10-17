#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Search & Navigation Tool
# =============================================================================
# Searches across every <category>/<program>/ folder: READMEs, examples.sh,
# scripts and configs.
#
# USAGE:
#   ./search.sh                       Interactive menu
#   ./search.sh nginx                 Search "nginx" everywhere
#   ./search.sh -t grep               Show examples for a program/command
#   ./search.sh -s 3                  List tier 3 (Advanced) commands
#   ./search.sh -d ssh                Open a program's README
#   ./search.sh -l                    List all categories and programs
#   ./search.sh -f firewall           Find files related to "firewall"
#   ./search.sh -c awk                Examples + README + mentions for awk
#
# KEYBOARD SHORTCUT (add to ~/.bashrc):
#   alias lls='bash /path/to/linux-commands/search.sh'
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate repo root (works from any directory)
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CATEGORIES=(commands system storage networking security monitoring debugging devops guides)

TIER_NAMES=([1]="Basic" [2]="Intermediate" [3]="Advanced" [4]="Expert" [5]="Extreme")

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'  # No Color

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
banner() {
  echo -e "${BOLD}${BLUE}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║       LOONY LINUX — Search & Navigate        ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

hr() { echo -e "${DIM}$(printf '─%.0s' {1..60})${NC}"; }

label()   { echo -e "${CYAN}${BOLD}$*${NC}"; }
result()  { echo -e "${GREEN}$*${NC}"; }
heading() { echo -e "\n${YELLOW}${BOLD}$*${NC}"; }
info()    { echo -e "${DIM}$*${NC}"; }
err()     { echo -e "${RED}[!] $*${NC}" >&2; }

rel() { echo "${1#"$REPO_ROOT/"}"; }

# All program folders, as paths relative to the repo root (e.g. networking/ssh)
program_dirs() {
  local c
  for c in "${CATEGORIES[@]}"; do
    [[ -d "$REPO_ROOT/$c" ]] || continue
    find "$REPO_ROOT/$c" -mindepth 1 -maxdepth 1 -type d | sort | while read -r d; do rel "$d"; done
  done
}

# One-line description of a program, taken from its category README table
program_desc() {
  local dir="$1" cat="${1%%/*}" name="${1#*/}"
  grep -m1 "^| \[${name}\](${name}/)" "$REPO_ROOT/$cat/README.md" 2>/dev/null | \
    awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}' || true
}

# Friendly names that don't match a folder name
declare -A ALIASES=(
  [k8s]="devops/kubernetes" [kube]="devops/kubernetes" [kubectl]="devops/kubernetes"
  [compose]="devops/docker" [cicd]="devops/ci-cd" [github]="devops/ci-cd"
  [install]="system/installation" [setup]="system/installation" [boot]="system/grub"
  [dpkg]="system/apt" [package]="system/apt" [packages]="system/apt"
  [process]="system/processes" [ps]="system/processes" [top]="system/processes"
  [htop]="system/processes" [kill]="system/processes" [nice]="system/processes"
  [user]="system/users" [useradd]="system/users" [chmod]="system/permissions"
  [chown]="system/permissions" [acl]="system/permissions" [timer]="system/systemd"
  [timers]="system/systemd" [journalctl]="system/journald" [crontab]="system/cron"
  [proc]="system/kernel" [module]="system/kernel" [modprobe]="system/kernel" [dmesg]="system/kernel"
  [fs]="storage/filesystems" [fstab]="storage/mount" [disk]="storage/partitioning"
  [fdisk]="storage/partitioning" [parted]="storage/partitioning" [mdadm]="storage/raid"
  [network]="networking/ip" [netplan]="networking/ip" [route]="networking/ip"
  [ufw]="networking/firewall" [nftables]="networking/firewall" [iptables]="networking/firewall"
  [scp]="networking/ssh" [sshd]="networking/ssh" [ss]="networking/diagnostics"
  [netstat]="networking/diagnostics" [tcpdump]="networking/diagnostics" [ping]="networking/diagnostics"
  [harden]="security/hardening" [selinux]="security/apparmor-selinux" [apparmor]="security/apparmor-selinux"
  [logs]="monitoring/logs" [log]="monitoring/logs" [performance]="monitoring/performance"
  [vmstat]="monitoring/performance" [iostat]="monitoring/performance" [free]="monitoring/performance"
  [ltrace]="debugging/strace" [gdb]="debugging/binary-tools" [objdump]="debugging/binary-tools"
  [flamegraph]="debugging/perf" [ebpf]="debugging/bpftrace"
  [head]="commands/head-tail" [tail]="commands/head-tail" [gzip]="commands/compression"
  [xz]="commands/compression" [zstd]="commands/compression" [bzip2]="commands/compression"
  [unzip]="commands/zip" [tmux]="commands/job-control" [nohup]="commands/job-control"
  [troubleshoot]="guides/troubleshooting" [debug]="guides/troubleshooting"
  [best]="guides/best-practices" [practices]="guides/best-practices" [dr]="guides/best-practices"
  [template]="guides/production-server" [project]="guides/production-server" [production]="guides/production-server"
)

# Resolve a name to a program folder (prints e.g. "networking/ssh"), or a
# category folder (prints e.g. "networking") when the name is a category.
resolve() {
  local q="${1,,}" d
  q="${q%/}"
  [[ -d "$REPO_ROOT/$q" && -f "$REPO_ROOT/$q/README.md" ]] && { echo "$q"; return; }
  # 1. Exact program folder name
  d=$(program_dirs | awk -F/ -v q="$q" '$2 == q {print; exit}')
  [[ -n "$d" ]] && { echo "$d"; return; }
  # 2. Alias
  [[ -n "${ALIASES[$q]:-}" ]] && { echo "${ALIASES[$q]}"; return; }
  # 3. Category name
  local c
  for c in "${CATEGORIES[@]}"; do [[ "$c" == "$q" ]] && { echo "$c"; return; }; done
  # 4. A "### <q> ..." block title inside some examples.sh
  d=$(grep -lis "^### ${q}\b" "$REPO_ROOT"/*/*/examples.sh 2>/dev/null | head -1 || true)
  [[ -n "$d" ]] && { rel "$(dirname "$d")"; return; }
  # 5. Partial folder name
  d=$(program_dirs | grep -i -m1 "/[^/]*${q}" || true)
  [[ -n "$d" ]] && { echo "$d"; return; }
  return 1
}

# Print a bash examples file with simple syntax highlighting
highlight_sh() {
  local pat_h3='^\#\#\#' pat_h2='^\#\#' pat_h1='^\#' pat_comment='\#'
  grep -v "^$" | while IFS= read -r line; do
    if [[ "$line" =~ $pat_h3 ]]; then
      echo -e "\n${YELLOW}${BOLD}${line}${NC}"
    elif [[ "$line" =~ $pat_h2 ]]; then
      echo -e "${CYAN}${line}${NC}"
    elif [[ "$line" =~ $pat_h1 ]]; then
      echo -e "${DIM}${line}${NC}"
    elif [[ "$line" =~ $pat_comment ]]; then
      code="${line%%#*}"
      comment="#${line#*#}"
      echo -e "${GREEN}${code}${NC}${DIM}${comment}${NC}"
    else
      echo -e "${GREEN}${line}${NC}"
    fi
  done
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  echo -e "${BOLD}LOONY LINUX SEARCH${NC}"
  echo ""
  echo -e "${BOLD}USAGE:${NC}"
  echo "  $(basename "$0") [OPTIONS] [KEYWORD]"
  echo ""
  echo -e "${BOLD}OPTIONS:${NC}"
  printf "  ${CYAN}%-20s${NC} %s\n" "<keyword>"    "Search all files for keyword"
  printf "  ${CYAN}%-20s${NC} %s\n" "-t <tool>"    "Show examples for a program/command (e.g. -t awk)"
  printf "  ${CYAN}%-20s${NC} %s\n" "-c <tool>"    "Examples + README + mentions elsewhere"
  printf "  ${CYAN}%-20s${NC} %s\n" "-s <1-5>"     "List commands in a tier (1=Basic…5=Extreme)"
  printf "  ${CYAN}%-20s${NC} %s\n" "-d <name>"    "Open a program or category README (e.g. -d ssh)"
  printf "  ${CYAN}%-20s${NC} %s\n" "-f <word>"    "Find files with 'word' in name or content"
  printf "  ${CYAN}%-20s${NC} %s\n" "-l"           "List all categories and programs"
  printf "  ${CYAN}%-20s${NC} %s\n" "-a"           "Show all headings across every README"
  printf "  ${CYAN}%-20s${NC} %s\n" "-h"           "Show this help"
  echo ""
  echo -e "${BOLD}EXAMPLES:${NC}"
  echo "  $(basename "$0") nginx              Search 'nginx' across all files"
  echo "  $(basename "$0") -t grep            Show grep examples"
  echo "  $(basename "$0") -t gdb             Show just the gdb block (debugging/binary-tools)"
  echo "  $(basename "$0") -c awk             awk examples, README and mentions"
  echo "  $(basename "$0") -s 5               Tier 5: debugging / performance / kernel"
  echo "  $(basename "$0") -d networking      Open the networking category index"
  echo "  $(basename "$0") -d k8s             Open devops/kubernetes/README.md"
  echo "  $(basename "$0") -f firewall        Find firewall-related files"
  echo ""
  echo -e "${BOLD}INTERACTIVE:${NC}"
  echo "  $(basename "$0")                    Launch interactive menu"
  echo ""
  echo -e "${DIM}Repo: $REPO_ROOT${NC}"
}

# ---------------------------------------------------------------------------
# FEATURE: List all categories and programs
# ---------------------------------------------------------------------------
list_all() {
  local c d
  for c in "${CATEGORIES[@]}"; do
    [[ -d "$REPO_ROOT/$c" ]] || continue
    heading "$(echo "${c^^}")  ${DIM}$c/"
    hr
    find "$REPO_ROOT/$c" -mindepth 1 -maxdepth 1 -type d | sort | while read -r d; do
      d=$(rel "$d")
      local files
      files=$(find "$REPO_ROOT/$d" -maxdepth 1 -type f ! -name README.md -printf '%f ' | tr ' ' '\n' | sort | tr '\n' ' ')
      printf "  ${CYAN}%-28s${NC} %-50s ${DIM}%s${NC}\n" "$d" "$(program_desc "$d")" "$files"
    done
  done
}

# ---------------------------------------------------------------------------
# FEATURE: Show examples for a program / command
# ---------------------------------------------------------------------------
find_tool() {
  local tool="${1,,}" dir
  if ! dir=$(resolve "$tool"); then
    err "No program matching '${tool}'."
    info "Run './search.sh -l' to list every program."
    return 1
  fi

  heading "TOOL: $tool  ${DIM}→ $dir/"
  hr

  local ex="$REPO_ROOT/$dir/examples.sh"
  if [[ ! -f "$ex" ]]; then
    info "No examples.sh in $dir/ — showing README.md"
    echo ""
    cat "$REPO_ROOT/$dir/README.md"
    return
  fi

  # If one "### <tool>" block matches, print only that block; else the whole file
  local start_line end_line
  start_line=$(grep -ni "^### ${tool}\b" "$ex" | head -1 | cut -d: -f1 || true)
  if [[ -n "$start_line" && "$(grep -c '^### ' "$ex")" -gt 1 ]]; then
    end_line=$(awk -v s="$start_line" 'NR > s && /^### /{print NR - 2; exit}' "$ex")
    [[ -z "$end_line" ]] && end_line=$(wc -l < "$ex")
    sed -n "${start_line},${end_line}p" "$ex" | highlight_sh
    echo ""
    info "Lines $start_line–$end_line of $dir/examples.sh"
  else
    highlight_sh < "$ex"
    echo ""
    info "$dir/examples.sh"
  fi
}

# ---------------------------------------------------------------------------
# FEATURE: Examples + README + mentions in other READMEs
# ---------------------------------------------------------------------------
show_tool_examples() {
  local tool="${1,,}" dir
  heading "ALL ABOUT: $tool"
  hr

  echo -e "${BOLD}[ Examples ]${NC}"
  find_tool "$tool" || return 1
  dir=$(resolve "$tool")

  echo ""
  echo -e "${BOLD}[ $dir/README.md ]${NC}"
  hr
  cat "$REPO_ROOT/$dir/README.md"

  local hits
  hits=$(grep -rn --include="*.md" -iw "$tool" "${CATEGORIES[@]/#/$REPO_ROOT/}" 2>/dev/null | \
    grep -v "^$REPO_ROOT/$dir/" | head -20 || true)
  if [[ -n "$hits" ]]; then
    echo ""
    echo -e "${BOLD}[ Mentioned elsewhere ]${NC}"
    hr
    echo "$hits" | while IFS=: read -r file linenum content; do
      printf "${CYAN}%-45s${NC} ${DIM}:%s${NC}  %s\n" "$(rel "$file")" "$linenum" "$content"
    done
  fi
}

# ---------------------------------------------------------------------------
# FEATURE: List commands in a tier (1–5)
# ---------------------------------------------------------------------------
show_section() {
  local n="$1"
  local name="${TIER_NAMES[$n]:-}"
  if [[ -z "$name" ]]; then
    err "Invalid tier: $n (valid: 1–5)"
    for k in 1 2 3 4 5; do echo "  $k: ${TIER_NAMES[$k]}"; done
    return 1
  fi

  heading "TIER $n — ${name^^}"
  hr

  local files
  files=$(grep -l "^# Tier:.*\b${n} (" "$REPO_ROOT"/*/*/examples.sh 2>/dev/null || true)
  echo -e "${BOLD}Programs with tier-$n commands:${NC}"
  local f
  for f in $files; do
    local d; d=$(rel "$(dirname "$f")")
    printf "  ${CYAN}▸${NC} %-28s ${DIM}%s${NC}\n" "$d" "$(grep '^### ' "$f" | sed 's/^### //;s/ —.*//' | paste -sd, -)"
  done

  echo ""
  read -r -p "$(echo -e "${YELLOW}Show all examples? [y/N/tool name]: ${NC}")" choice
  case "${choice,,}" in
    y|yes)
      for f in $files; do
        echo -e "\n${MAGENTA}${BOLD}══ $(rel "$f") ══${NC}"
        highlight_sh < "$f"
      done | less -R
      ;;
    n|no|"")
      info "Use './search.sh -t <toolname>' to show a specific tool"
      ;;
    *)
      find_tool "$choice" | less -R
      ;;
  esac
}

# ---------------------------------------------------------------------------
# FEATURE: Open a program or category README
# ---------------------------------------------------------------------------
open_doc() {
  local dir
  if ! dir=$(resolve "$1"); then
    err "Nothing matching '$1'."
    echo ""
    echo "Categories: ${CATEGORIES[*]}"
    info "Run './search.sh -l' to list every program."
    return 1
  fi
  echo -e "${DIM}Opening: $dir/README.md${NC}"
  less -R "$REPO_ROOT/$dir/README.md"
}

# ---------------------------------------------------------------------------
# FEATURE: Full-text search, grouped by category
# ---------------------------------------------------------------------------
search_all() {
  local keyword="$1"
  local results_found=0 c

  heading "SEARCH: \"$keyword\""
  hr

  for c in "${CATEGORIES[@]}"; do
    [[ -d "$REPO_ROOT/$c" ]] || continue
    local hits
    hits=$(grep -rn -i -- "$keyword" "$REPO_ROOT/$c" 2>/dev/null || true)
    [[ -z "$hits" ]] && continue

    label "▶ ${c^}"
    echo "$hits" | head -20 | while IFS=: read -r file linenum content; do
      printf "  ${CYAN}%-45s${NC}${DIM}:%-5s${NC} %s\n" "$(rel "$file")" "$linenum" "${content:0:120}"
    done
    local total; total=$(echo "$hits" | wc -l)
    [[ $total -gt 20 ]] && info "  ... and $(( total - 20 )) more matches"
    echo ""
    results_found=$(( results_found + 1 ))
  done

  if (( results_found == 0 )); then
    err "No results found for: $keyword"
    echo ""
    echo "Try:"
    echo "  ./search.sh -l            List all programs"
    echo "  ./search.sh -a            Show all headings"
    return 1
  fi

  hr
  info "Tip: Use './search.sh -t ${keyword}' to show examples for a specific tool"
}

# ---------------------------------------------------------------------------
# FEATURE: Find files related to a topic
# ---------------------------------------------------------------------------
find_files() {
  local keyword="$1"
  heading "FILES RELATED TO: \"$keyword\""
  hr

  echo -e "${BOLD}Matching file and folder names:${NC}"
  find "${CATEGORIES[@]/#/$REPO_ROOT/}" -iname "*${keyword}*" 2>/dev/null | sort | \
    while read -r f; do
      printf "  ${GREEN}%s${NC}\n" "$(rel "$f")"
    done

  echo ""
  echo -e "${BOLD}Files containing \"$keyword\":${NC}"
  grep -rl -i -- "$keyword" "${CATEGORIES[@]/#/$REPO_ROOT/}" 2>/dev/null | sort | \
    while read -r f; do
      local count; count=$(grep -ic -- "$keyword" "$f" 2>/dev/null || echo 0)
      printf "  ${CYAN}%-55s${NC} ${DIM}(%s matches)${NC}\n" "$(rel "$f")" "$count"
    done
}

# ---------------------------------------------------------------------------
# FEATURE: Show all headings across every README
# ---------------------------------------------------------------------------
show_all_headings() {
  heading "ALL SECTIONS AND HEADINGS"
  hr
  local c d
  for c in "${CATEGORIES[@]}"; do
    [[ -d "$REPO_ROOT/$c" ]] || continue
    echo -e "\n${MAGENTA}${BOLD}${c^^}${NC}"
    program_dirs | grep "^$c/" | while read -r d; do
      echo -e "\n  ${YELLOW}${BOLD}$d/${NC}"
      grep "^## \|^### " "$REPO_ROOT/$d/README.md" 2>/dev/null | sed 's/^/    /' || true
    done
  done
}

# ---------------------------------------------------------------------------
# INTERACTIVE MENU (no fzf)
# ---------------------------------------------------------------------------
interactive_menu() {
  banner

  while true; do
    echo -e "${BOLD}What do you want to do?${NC}"
    echo ""
    printf "  ${CYAN}1${NC}  Search for a keyword or command\n"
    printf "  ${CYAN}2${NC}  Browse commands by tier (1=Basic … 5=Extreme)\n"
    printf "  ${CYAN}3${NC}  Look up a specific tool (grep, awk, curl, ...)\n"
    printf "  ${CYAN}4${NC}  Open a program or category README\n"
    printf "  ${CYAN}5${NC}  Find related files\n"
    printf "  ${CYAN}6${NC}  List all categories and programs\n"
    printf "  ${CYAN}7${NC}  Show all headings (map of the repo)\n"
    printf "  ${CYAN}q${NC}  Quit\n"
    echo ""
    read -r -p "$(echo -e "${YELLOW}Choice: ${NC}")" choice

    case "${choice,,}" in
      1)
        read -r -p "$(echo -e "${YELLOW}Keyword to search: ${NC}")" kw
        [[ -n "$kw" ]] && search_all "$kw" | less -R
        ;;
      2)
        echo ""
        for k in 1 2 3 4 5; do echo "  $k: ${TIER_NAMES[$k]}"; done
        echo ""
        read -r -p "$(echo -e "${YELLOW}Tier (1-5): ${NC}")" snum
        [[ -n "$snum" ]] && show_section "$snum"
        ;;
      3)
        echo ""
        echo -e "${BOLD}Programs:${NC}"
        program_dirs | sed 's|.*/||' | column
        echo ""
        read -r -p "$(echo -e "${YELLOW}Tool name: ${NC}")" tool
        [[ -n "$tool" ]] && find_tool "$tool" | less -R
        ;;
      4)
        echo ""
        echo -e "${BOLD}Categories:${NC} ${CATEGORIES[*]}"
        echo ""
        read -r -p "$(echo -e "${YELLOW}Program or category (e.g. ssh, lvm, security): ${NC}")" doc
        [[ -n "$doc" ]] && open_doc "$doc"
        ;;
      5)
        read -r -p "$(echo -e "${YELLOW}Topic to find files for: ${NC}")" topic
        [[ -n "$topic" ]] && find_files "$topic" | less -R
        ;;
      6)
        list_all | less -R
        ;;
      7)
        show_all_headings | less -R
        ;;
      q|quit|exit)
        echo ""
        info "Tip: Run './search.sh <keyword>' directly to skip the menu."
        break
        ;;
      *)
        # If they just typed a word, treat it as a search
        if [[ -n "$choice" ]]; then
          search_all "$choice" | less -R
        fi
        ;;
    esac

    echo ""
    hr
    echo ""
  done
}

# =============================================================================
# MAIN — Parse arguments and dispatch
# =============================================================================
main() {
  # No arguments → interactive menu
  if [[ $# -eq 0 ]]; then
    interactive_menu
    exit 0
  fi

  case "$1" in
    -h|--help)
      usage
      ;;
    -l|--list)
      list_all | less -R
      ;;
    -a|--all-headings)
      show_all_headings | less -R
      ;;
    -t|--tool)
      [[ -z "${2:-}" ]] && { err "Provide a tool name: -t grep"; exit 1; }
      find_tool "$2" | less -R
      ;;
    -c|--command|--examples)
      [[ -z "${2:-}" ]] && { err "Provide a tool name: -c awk"; exit 1; }
      show_tool_examples "$2" | less -R
      ;;
    -s|--section|--tier)
      [[ -z "${2:-}" ]] && { err "Provide tier number: -s 3"; exit 1; }
      show_section "$2"
      ;;
    -d|--doc)
      [[ -z "${2:-}" ]] && { err "Provide a name: -d ssh"; exit 1; }
      open_doc "$2"
      ;;
    -f|--files)
      [[ -z "${2:-}" ]] && { err "Provide a topic: -f firewall"; exit 1; }
      find_files "$2" | less -R
      ;;
    -*)
      err "Unknown option: $1"
      echo ""
      usage
      exit 1
      ;;
    *)
      # Bare keyword → search everywhere
      search_all "$1" | less -R
      ;;
  esac
}

main "$@"

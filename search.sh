#!/usr/bin/env bash
# =============================================================================
# LOONY LINUX — Search & Navigation Tool
# =============================================================================
# Searches across all docs, scripts, configs, and reference files.
#
# USAGE:
#   ./search.sh                       Interactive menu
#   ./search.sh nginx                 Search "nginx" everywhere
#   ./search.sh -t grep               Find a specific tool/command
#   ./search.sh -s 3                  Show Section 3 (Advanced Commands)
#   ./search.sh -l                    List all available tools
#   ./search.sh -f firewall           Find files related to "firewall"
#   ./search.sh -c awk                Show all awk examples
#
# KEYBOARD SHORTCUT (add to ~/.bashrc):
#   alias lls='bash /path/to/linux-commands/search.sh'
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate repo root (works from any directory)
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMMAND_LIB="$REPO_ROOT/scripts/commands/command-library.sh"
DOCS_DIR="$REPO_ROOT/docs"
CHEATSHEETS_DIR="$REPO_ROOT/cheatsheets"
SCRIPTS_DIR="$REPO_ROOT/scripts"
CONFIGS_DIR="$REPO_ROOT/configs"
SECURITY_DIR="$REPO_ROOT/security"
SERVICES_DIR="$REPO_ROOT/services"

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

# Check if fzf is available for interactive mode
HAS_FZF=0
command -v fzf &>/dev/null && HAS_FZF=1

# ---------------------------------------------------------------------------
# Detect terminal width for output formatting
# ---------------------------------------------------------------------------
COLS=$(tput cols 2>/dev/null || echo 80)
(( COLS > 120 )) && COLS=120

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
  printf "  ${CYAN}%-20s${NC} %s\n" "<keyword>"   "Search all files for keyword"
  printf "  ${CYAN}%-20s${NC} %s\n" "-t <tool>"   "Find a specific command/tool (e.g. -t awk)"
  printf "  ${CYAN}%-20s${NC} %s\n" "-c <tool>"   "Show ALL examples for a tool"
  printf "  ${CYAN}%-20s${NC} %s\n" "-s <1-5>"    "Show a section (1=Basic…5=Extreme)"
  printf "  ${CYAN}%-20s${NC} %s\n" "-f <word>"   "Find files with 'word' in name or content"
  printf "  ${CYAN}%-20s${NC} %s\n" "-l"          "List all documented tools and sections"
  printf "  ${CYAN}%-20s${NC} %s\n" "-d <section>" "Open a doc (e.g. -d networking)"
  printf "  ${CYAN}%-20s${NC} %s\n" "-a"          "Show all section headings across every file"
  printf "  ${CYAN}%-20s${NC} %s\n" "-h"          "Show this help"
  echo ""
  echo -e "${BOLD}EXAMPLES:${NC}"
  echo "  $(basename "$0") nginx              Search 'nginx' across all files"
  echo "  $(basename "$0") -t grep            Show grep examples from command library"
  echo "  $(basename "$0") -c awk             Full awk section with all examples"
  echo "  $(basename "$0") -s 3               Show Section 3: Advanced Commands"
  echo "  $(basename "$0") -s 5               Show Section 5: Extreme / Debugging"
  echo "  $(basename "$0") -f firewall        Find firewall-related files"
  echo "  $(basename "$0") -d networking      Open networking doc"
  echo "  $(basename "$0") -l                 List every documented tool"
  echo ""
  echo -e "${BOLD}INTERACTIVE:${NC}"
  echo "  $(basename "$0")                    Launch interactive menu"
  echo ""
  echo -e "${DIM}Repo: $REPO_ROOT${NC}"
}

# ---------------------------------------------------------------------------
# FEATURE: List all documented tools / sections
# ---------------------------------------------------------------------------
list_all() {
  heading "DOCUMENTED TOOLS IN COMMAND LIBRARY"
  hr
  grep "^### " "$COMMAND_LIB" | sed 's/^### /  /' | \
    awk '{printf "  %-45s\n", $0}' | \
    sed 's/—.*//' | \
    column
  echo ""

  heading "COMMAND LIBRARY SECTIONS"
  hr
  grep "^# SECTION" "$COMMAND_LIB" | sed 's/^# /  /'
  echo ""

  heading "DOCUMENTATION GUIDES"
  hr
  for f in "$DOCS_DIR"/*.md; do
    local name
    name=$(basename "$f" .md)
    local title
    title=$(head -2 "$f" | grep "^# " | sed 's/^# //')
    printf "  ${CYAN}%-30s${NC} %s\n" "$name" "$title"
  done
  echo ""

  heading "CHEATSHEETS"
  hr
  find "$CHEATSHEETS_DIR" -name "*.md" | sort | while read -r f; do
    local rel
    rel="${f#"$REPO_ROOT/"}"
    local title
    title=$(grep -m1 "^# " "$f" | sed 's/^# //' || true)
    printf "  ${CYAN}%-45s${NC} %s\n" "$rel" "$title"
  done
  echo ""

  heading "SCRIPTS"
  hr
  find "$SCRIPTS_DIR" -name "*.sh" | sort | while read -r f; do
    local rel
    rel="${f#"$REPO_ROOT/"}"
    local desc
    desc=$(grep -m1 "^# ===\|^# Description\|^# LOONY LINUX" "$f" 2>/dev/null | \
           sed 's/^# //;s/=//g;s/LOONY LINUX — //' | head -c 50 || echo "")
    printf "  ${GREEN}%-40s${NC} %s\n" "$rel" "$desc"
  done
  echo ""

  heading "CONFIG FILES"
  hr
  find "$CONFIGS_DIR" "$SECURITY_DIR" "$SERVICES_DIR" -type f 2>/dev/null | sort | \
    while read -r f; do
      printf "  %s\n" "${f#"$REPO_ROOT/"}"
    done
}

# ---------------------------------------------------------------------------
# FEATURE: Search a specific tool section in command-library.sh
# ---------------------------------------------------------------------------
find_tool() {
  local tool="${1,,}"   # lowercase
  heading "TOOL: $tool — Quick Reference"
  hr

  # Find the ### header for this tool (case-insensitive)
  local start_line
  start_line=$(grep -ni "^### .*${tool}" "$COMMAND_LIB" | head -1 | cut -d: -f1)

  if [[ -z "$start_line" ]]; then
    err "Tool '${tool}' not found in command library."
    echo ""
    echo "Available tools:"
    grep "^### " "$COMMAND_LIB" | sed 's/^### /  /' | grep -i "${tool}" || \
      grep "^### " "$COMMAND_LIB" | sed 's/^### /  /' | head -30
    return 1
  fi

  # Find where the next ### section starts (so we print only this tool's block)
  local end_line
  end_line=$(awk "NR > $start_line && /^### /{print NR; exit}" "$COMMAND_LIB")

  if [[ -z "$end_line" ]]; then
    end_line=$(wc -l < "$COMMAND_LIB")
  else
    end_line=$(( end_line - 1 ))
  fi

  # Print the block with syntax highlighting simulation
  # (patterns stored in vars to avoid bash [[ regex parsing issues with \ ] ))
  local pat_h3='^\#\#\#' pat_h2='^\#\#' pat_h1='^\#' pat_comment='\#'
  sed -n "${start_line},${end_line}p" "$COMMAND_LIB" | \
    grep -v "^$" | \
    while IFS= read -r line; do
      if [[ "$line" =~ $pat_h3 ]]; then
        echo -e "${YELLOW}${BOLD}${line}${NC}"
      elif [[ "$line" =~ $pat_h2 ]]; then
        echo -e "${CYAN}${line}${NC}"
      elif [[ "$line" =~ $pat_h1 ]]; then
        echo -e "${DIM}${line}${NC}"
      elif [[ "$line" =~ $pat_comment ]]; then
        # Line with inline comment: split at first #
        code="${line%%#*}"
        comment="#${line#*#}"
        echo -e "${GREEN}${code}${NC}${DIM}${comment}${NC}"
      else
        echo -e "${GREEN}${line}${NC}"
      fi
    done

  echo ""
  info "Lines $start_line–$end_line of $(basename "$COMMAND_LIB")"
}

# ---------------------------------------------------------------------------
# FEATURE: Show all examples for a tool (alias for find_tool but verbose)
# ---------------------------------------------------------------------------
show_tool_examples() {
  local tool="${1,,}"
  heading "ALL EXAMPLES: $tool"
  hr

  # Search in command library
  echo -e "${BOLD}[ Command Library ]${NC}"
  find_tool "$tool"

  # Also search docs
  local doc_hits
  doc_hits=$(grep -rn --include="*.md" -i "${tool}" "$DOCS_DIR" "$CHEATSHEETS_DIR" 2>/dev/null | \
    grep -i "^.*${tool}.*$" | head -20 || true)

  if [[ -n "$doc_hits" ]]; then
    echo ""
    echo -e "${BOLD}[ Documentation Mentions ]${NC}"
    hr
    echo "$doc_hits" | while IFS=: read -r file linenum content; do
      local relfile="${file#"$REPO_ROOT/"}"
      printf "${CYAN}%-40s${NC} ${DIM}:%s${NC}  %s\n" "$relfile" "$linenum" "$content"
    done
  fi
}

# ---------------------------------------------------------------------------
# FEATURE: Show a section by number (1–5)
# ---------------------------------------------------------------------------
show_section() {
  local section_num="$1"

  local section_map=(
    [1]="SECTION 1 — BASIC"
    [2]="SECTION 2 — INTERMEDIATE"
    [3]="SECTION 3 — ADVANCED"
    [4]="SECTION 4 — EXPERT"
    [5]="SECTION 5 — EXTREME"
  )

  local section_label="${section_map[$section_num]:-}"
  if [[ -z "$section_label" ]]; then
    err "Invalid section number: $section_num (valid: 1–5)"
    echo "Sections:"
    for k in "${!section_map[@]}"; do
      echo "  $k: ${section_map[$k]}"
    done | sort
    return 1
  fi

  heading "SECTION $section_num"
  hr

  # Find section boundaries
  local start_line
  start_line=$(grep -n "# SECTION ${section_num} " "$COMMAND_LIB" | cut -d: -f1 | head -1)

  if [[ -z "$start_line" ]]; then
    err "Could not locate section $section_num in command library"
    return 1
  fi

  local next_section=$(( section_num + 1 ))
  local end_line
  end_line=$(awk "NR > $start_line && /^# SECTION ${next_section} /{print NR; exit}" "$COMMAND_LIB")

  if [[ -z "$end_line" ]]; then
    end_line=$(wc -l < "$COMMAND_LIB")
  else
    end_line=$(( end_line - 1 ))
  fi

  # List tools in this section first
  echo -e "${BOLD}Tools in this section:${NC}"
  sed -n "${start_line},${end_line}p" "$COMMAND_LIB" | \
    grep "^### " | sed 's/^### /  /' | \
    while read -r tool_line; do
      echo -e "  ${CYAN}▸${NC} $tool_line"
    done

  echo ""
  read -r -p "$(echo -e "${YELLOW}Show full section? [y/N/tool name]: ${NC}")" choice

  case "${choice,,}" in
    y|yes)
      local p3='^\#\#\#' p2='^\#\#' p_sec='^\# SECTION' p1='^\#' pc='\#'
      sed -n "${start_line},${end_line}p" "$COMMAND_LIB" | \
        while IFS= read -r line; do
          if [[ "$line" =~ $p3 ]]; then
            echo -e "\n${YELLOW}${BOLD}${line}${NC}"
          elif [[ "$line" =~ $p_sec ]]; then
            echo -e "${MAGENTA}${BOLD}${line}${NC}"
          elif [[ "$line" =~ $p2 ]]; then
            echo -e "${CYAN}${line}${NC}"
          elif [[ "$line" =~ $p1 ]]; then
            echo -e "${DIM}${line}${NC}"
          elif [[ -n "$line" && "$line" =~ $pc ]]; then
            code="${line%%#*}"
            comment="#${line#*#}"
            echo -e "${GREEN}${code}${NC}${DIM}${comment}${NC}"
          elif [[ -n "$line" ]]; then
            echo -e "${GREEN}${line}${NC}"
          fi
        done | less -R
      ;;
    n|no|"")
      info "Use './search.sh -t <toolname>' to show a specific tool"
      ;;
    *)
      # They typed a tool name
      find_tool "$choice"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# FEATURE: Open a documentation guide
# ---------------------------------------------------------------------------
open_doc() {
  local query="${1,,}"

  # Map friendly names to doc numbers
  declare -A doc_map=(
    ["01"]="01" ["installation"]="01" ["install"]="01" ["disk"]="01" ["grub"]="01" ["boot"]="01" ["lvm"]="01"
    ["02"]="02" ["filesystem"]="02" ["fs"]="02" ["storage"]="02" ["fstab"]="02" ["raid"]="02" ["permissions"]="02"
    ["03"]="03" ["commands"]="03" ["cmd"]="03" ["cli"]="03"
    ["04"]="04" ["process"]="04" ["systemd"]="04" ["service"]="04" ["journald"]="04"
    ["05"]="05" ["user"]="05" ["users"]="05" ["pam"]="05" ["sudo"]="05" ["apparmor"]="05"
    ["06"]="06" ["network"]="06" ["networking"]="06" ["firewall"]="06" ["ssh"]="06" ["dns"]="06" ["ip"]="06"
    ["07"]="07" ["security"]="07" ["harden"]="07" ["hardening"]="07" ["fail2ban"]="07" ["audit"]="07"
    ["08"]="08" ["package"]="08" ["apt"]="08" ["dpkg"]="08" ["build"]="08"
    ["09"]="09" ["devops"]="09" ["ansible"]="09" ["docker"]="09" ["kubernetes"]="09" ["k8s"]="09" ["cicd"]="09"
    ["10"]="10" ["monitoring"]="10" ["monitor"]="10" ["prometheus"]="10" ["grafana"]="10" ["performance"]="10"
    ["11"]="11" ["troubleshoot"]="11" ["debug"]="11" ["trouble"]="11"
    ["12"]="12" ["kernel"]="12" ["sysctl"]="12" ["proc"]="12" ["module"]="12"
    ["13"]="13" ["project"]="13" ["template"]="13" ["production"]="13"
    ["15"]="15" ["best"]="15" ["practices"]="15" ["migration"]="15" ["backup"]="15" ["dr"]="15"
  )

  local section_num="${doc_map[$query]:-}"

  if [[ -z "$section_num" ]]; then
    # Try partial match on filenames
    local match
    match=$(ls "$DOCS_DIR"/*.md 2>/dev/null | grep -i "$query" | head -1)
    if [[ -n "$match" ]]; then
      less -R "$match"
      return
    fi
    err "Doc '${query}' not found."
    echo ""
    echo "Available docs:"
    for f in "$DOCS_DIR"/*.md; do
      local name; name=$(basename "$f" .md)
      local title; title=$(head -2 "$f" | grep "^# " | sed 's/^# //')
      printf "  ${CYAN}%-15s${NC} %s\n" "$name" "$title"
    done
    return 1
  fi

  local docfile
  docfile=$(ls "$DOCS_DIR"/${section_num}-*.md 2>/dev/null | head -1)
  if [[ -z "$docfile" ]]; then
    err "Documentation file not found for section $section_num"
    return 1
  fi

  echo -e "${DIM}Opening: ${docfile#"$REPO_ROOT/"}${NC}"
  less -R "$docfile"
}

# ---------------------------------------------------------------------------
# FEATURE: Full-text search across all repo files
# ---------------------------------------------------------------------------
search_all() {
  local keyword="$1"
  local results_found=0

  heading "SEARCH: \"$keyword\""
  hr

  # --- Command Library (highest priority) ---
  local cmd_hits
  cmd_hits=$(grep -n -i "$keyword" "$COMMAND_LIB" 2>/dev/null | grep -v "^[0-9]*:#" || true)

  if [[ -n "$cmd_hits" ]]; then
    label "▶ Command Library — scripts/commands/command-library.sh"
    echo "$cmd_hits" | head -30 | while IFS=: read -r linenum content; do
      # Show context: what ### section is this line in?
      local section_header
      section_header=$(awk "NR<=$linenum && /^### /{last=\$0} END{print last}" "$COMMAND_LIB")
      printf "  ${DIM}line %-5s${NC} ${GREEN}%s${NC}  ${DIM}[%s]${NC}\n" \
        "$linenum" "$content" "$section_header"
    done
    local total; total=$(echo "$cmd_hits" | wc -l)
    [[ $total -gt 30 ]] && info "  ... and $(( total - 30 )) more matches"
    echo ""
    (( results_found++ ))
  fi

  # --- Documentation files ---
  local doc_hits
  doc_hits=$(grep -rn -i "$keyword" "$DOCS_DIR" 2>/dev/null || true)

  if [[ -n "$doc_hits" ]]; then
    label "▶ Documentation"
    echo "$doc_hits" | head -25 | while IFS=: read -r file linenum content; do
      local relfile="${file#"$REPO_ROOT/"}"
      printf "  ${CYAN}%-40s${NC}${DIM}:%s${NC}  %s\n" "$relfile" "$linenum" "$content"
    done
    local total; total=$(echo "$doc_hits" | wc -l)
    [[ $total -gt 25 ]] && info "  ... and $(( total - 25 )) more matches"
    echo ""
    (( results_found++ ))
  fi

  # --- Cheatsheets ---
  local cheat_hits
  cheat_hits=$(grep -rn -i "$keyword" "$CHEATSHEETS_DIR" 2>/dev/null || true)

  if [[ -n "$cheat_hits" ]]; then
    label "▶ Cheatsheets"
    echo "$cheat_hits" | head -25 | while IFS=: read -r file linenum content; do
      local relfile="${file#"$REPO_ROOT/"}"
      printf "  ${CYAN}%-45s${NC}${DIM}:%s${NC}  %s\n" "$relfile" "$linenum" "$content"
    done
    local total; total=$(echo "$cheat_hits" | wc -l)
    [[ $total -gt 25 ]] && info "  ... and $(( total - 25 )) more matches"
    echo ""
    (( results_found++ ))
  fi

  # --- Scripts ---
  local script_hits
  script_hits=$(grep -rn -i "$keyword" "$SCRIPTS_DIR" \
    --exclude="command-library.sh" 2>/dev/null || true)

  if [[ -n "$script_hits" ]]; then
    label "▶ Scripts"
    echo "$script_hits" | head -20 | while IFS=: read -r file linenum content; do
      local relfile="${file#"$REPO_ROOT/"}"
      printf "  ${CYAN}%-50s${NC}${DIM}:%s${NC}  %s\n" "$relfile" "$linenum" "$content"
    done
    echo ""
    (( results_found++ ))
  fi

  # --- Configs, Security, Services ---
  local cfg_hits
  cfg_hits=$(grep -rn -i "$keyword" "$CONFIGS_DIR" "$SECURITY_DIR" "$SERVICES_DIR" \
    "$REPO_ROOT/docker" "$REPO_ROOT/kubernetes" "$REPO_ROOT/monitoring" \
    "$REPO_ROOT/ansible" 2>/dev/null || true)

  if [[ -n "$cfg_hits" ]]; then
    label "▶ Configs / Services / Infra"
    echo "$cfg_hits" | head -20 | while IFS=: read -r file linenum content; do
      local relfile="${file#"$REPO_ROOT/"}"
      printf "  ${CYAN}%-55s${NC}${DIM}:%s${NC}  %s\n" "$relfile" "$linenum" "$content"
    done
    echo ""
    (( results_found++ ))
  fi

  if (( results_found == 0 )); then
    err "No results found for: $keyword"
    echo ""
    echo "Try:"
    echo "  ./search.sh -l            List all documented tools"
    echo "  ./search.sh -a            Show all section headings"
    return 1
  fi

  hr
  info "Tip: Use './search.sh -t ${keyword}' to show all examples for a specific tool"
}

# ---------------------------------------------------------------------------
# FEATURE: Find files related to a topic
# ---------------------------------------------------------------------------
find_files() {
  local keyword="$1"
  heading "FILES RELATED TO: \"$keyword\""
  hr

  echo -e "${BOLD}Matching filenames:${NC}"
  find "$REPO_ROOT" -not -path '*/.git/*' -type f \
    \( -iname "*${keyword}*" \) 2>/dev/null | \
    while read -r f; do
      printf "  ${GREEN}%s${NC}\n" "${f#"$REPO_ROOT/"}"
    done

  echo ""
  echo -e "${BOLD}Files containing \"$keyword\":${NC}"
  grep -rl -i "$keyword" \
    "$DOCS_DIR" "$CHEATSHEETS_DIR" "$SCRIPTS_DIR" "$CONFIGS_DIR" "$SECURITY_DIR" \
    "$SERVICES_DIR" "$REPO_ROOT/docker" "$REPO_ROOT/kubernetes" \
    "$REPO_ROOT/ansible" 2>/dev/null | \
    sort | \
    while read -r f; do
      local relfile="${f#"$REPO_ROOT/"}"
      local count; count=$(grep -ic "$keyword" "$f" 2>/dev/null || echo 0)
      printf "  ${CYAN}%-55s${NC} ${DIM}(%s matches)${NC}\n" "$relfile" "$count"
    done
}

# ---------------------------------------------------------------------------
# FEATURE: Show all section headings across every file
# ---------------------------------------------------------------------------
show_all_headings() {
  heading "ALL SECTIONS AND HEADINGS"
  hr

  echo -e "${BOLD}Command Library Sections:${NC}"
  grep -n "^# SECTION\|^### " "$COMMAND_LIB" | \
    while IFS=: read -r linenum content; do
      if [[ "$content" =~ ^#\ SECTION ]]; then
        echo -e "\n  ${MAGENTA}${BOLD}${content}${NC}  ${DIM}(line $linenum)${NC}"
      else
        echo -e "    ${CYAN}${content}${NC}"
      fi
    done

  echo ""
  echo -e "${BOLD}Documentation Sections:${NC}"
  for f in "$DOCS_DIR"/*.md; do
    local relfile; relfile=$(basename "$f")
    echo -e "\n  ${YELLOW}${BOLD}${relfile}${NC}"
    grep "^## \|^### " "$f" | sed 's/^/    /'
  done

  echo ""
  echo -e "${BOLD}Cheatsheet Sections:${NC}"
  find "$CHEATSHEETS_DIR" -name "*.md" | sort | while read -r f; do
    echo -e "\n  ${YELLOW}${BOLD}${f#"$CHEATSHEETS_DIR/"}${NC}"
    grep "^## \|^### " "$f" | sed 's/^/    /' || true
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
    printf "  ${CYAN}2${NC}  Browse by section (1=Basic … 5=Extreme)\n"
    printf "  ${CYAN}3${NC}  Look up a specific tool (grep, awk, curl, ...)\n"
    printf "  ${CYAN}4${NC}  Open a documentation guide\n"
    printf "  ${CYAN}5${NC}  Find related files\n"
    printf "  ${CYAN}6${NC}  List all documented tools\n"
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
        echo -e "${BOLD}Sections:${NC}"
        grep "^# SECTION" "$COMMAND_LIB" | sed 's/^# /  /'
        echo ""
        read -r -p "$(echo -e "${YELLOW}Section number (1-5): ${NC}")" snum
        [[ -n "$snum" ]] && show_section "$snum"
        ;;
      3)
        echo ""
        echo -e "${BOLD}Available tools:${NC}"
        grep "^### " "$COMMAND_LIB" | sed 's/^### /  /' | \
          awk '{printf "  %-45s\n", $0}' | sed 's/—.*//'
        echo ""
        read -r -p "$(echo -e "${YELLOW}Tool name: ${NC}")" tool
        [[ -n "$tool" ]] && find_tool "$tool" | less -R
        ;;
      4)
        echo ""
        echo -e "${BOLD}Available docs:${NC}"
        for f in "$DOCS_DIR"/*.md; do
          local name; name=$(basename "$f" .md)
          local title; title=$(head -2 "$f" | grep "^# " | sed 's/^# //')
          printf "  ${CYAN}%-15s${NC} %s\n" "$name" "$title"
        done
        echo ""
        read -r -p "$(echo -e "${YELLOW}Doc name (e.g. networking, security, kernel): ${NC}")" doc
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
    -s|--section)
      [[ -z "${2:-}" ]] && { err "Provide section number: -s 3"; exit 1; }
      show_section "$2"
      ;;
    -d|--doc)
      [[ -z "${2:-}" ]] && { err "Provide a doc name: -d networking"; exit 1; }
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

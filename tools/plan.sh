#!/usr/bin/env bash
set -euo pipefail

# Plan: preview what `make apply` would do, using only dry-run checks.

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)"

log "Preparing current and desired snapshots…"
bash "$REPO_ROOT/tools/generate_desired.sh" > /tmp/homesetup.plan.desired.out 2>&1 || true
bash "$REPO_ROOT/tools/snapshot_current.sh" > /tmp/homesetup.plan.snapshot.out 2>&1 || true

log "Generating diff report (current vs desired)…"
bash "$REPO_ROOT/tools/diff_state.sh" > /tmp/homesetup.plan.diff.out 2>&1 || true
report_line=$(grep -Eo "Diff report written to: .*" /tmp/homesetup.plan.diff.out | tail -n1 || true)
if [[ -n "$report_line" ]]; then
  log "$report_line"
else
  warn "Could not find diff report path in output. See snapshots/diff/."
fi

echo "---"
# Summarize concrete actions apply would take
echo "---"
log "Planned Actions"

DIFF_DIR="$REPO_ROOT/snapshots/diff/latest"
show_list() { # file title tag max
  local f="$1"; local title="$2"; local tag="$3"; local max=${4:-20}
  if [[ -s "$f" ]]; then
    local cnt; cnt=$(wc -l < "$f" | tr -d ' ')
    echo "- $title: $cnt"
    local n=0
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      echo "  • $tag $line"
      n=$((n+1)); [[ $n -ge $max ]] && break || true
    done < "$f"
    if (( cnt > n )); then echo "  • … (+$((cnt-n)) more)"; fi
  else
    echo "- $title: 0"
  fi
}

show_defaults() { # issues.tsv
  local f="$1"; local max=${2:-10}
  if [[ -s "$f" ]]; then
    local cnt; cnt=$(wc -l < "$f" | tr -d ' ')
    echo "- Defaults to change: $cnt"
    local n=0
    while IFS=$'\t' read -r domain key current desired; do
      [[ -n "$domain" ]] || continue
      echo "  • [CHANGE] $domain $key: $current -> $desired"
      n=$((n+1)); [[ $n -ge $max ]] && break || true
    done < "$f"
    if (( cnt > n )); then echo "  • … (+$((cnt-n)) more)"; fi
  else
    echo "- Defaults to change: 0"
  fi
}

show_dotfiles() { # issues.tsv
  local f="$1"; local max=${2:-20}
  if [[ -s "$f" ]]; then
    local cnt; cnt=$(wc -l < "$f" | tr -d ' ')
    echo "- Dotfiles to link/fix: $cnt"
    local n=0 conflicts=0 fixes=0 links=0
    while IFS=$'\t' read -r target state pkg rel; do
      [[ -n "$target" ]] || continue
      local tag="[INFO]"
      case "$state" in
        missing) tag="[LINK]"; links=$((links+1));;
        symlink_other) tag="[FIX]"; fixes=$((fixes+1));;
        conflict_file|conflict_dir) tag="[CONFLICT]"; conflicts=$((conflicts+1));;
        linked_ok) tag="[OK]";;
      esac
      if [[ "$tag" == "[LINK]" ]] || { [[ "$tag" == "[FIX]" ]] && [[ "${PLAN_SHOW_FIXES:-0}" == "1" ]]; } || { [[ "$tag" == "[CONFLICT]" ]] && [[ "${PLAN_SHOW_CONFLICTS:-0}" == "1" ]]; }; then
        echo "  • $tag $target ($pkg/$rel): state=$state"
        n=$((n+1)); [[ $n -ge $max ]] && break || true
      fi
    done < "$f"
    if (( cnt > n )); then echo "  • … (+$((cnt-n)) more; adjust PLAN_SHOW_* and max)"; fi
    echo "  • Summary (all states): links=$links fixes=$fixes conflicts=$conflicts"
  else
    echo "- Dotfiles to link/fix: 0"
  fi
}

show_list "$DIFF_DIR/_brew_to_install.txt" "Brew formulae to install" "[INSTALL]"
show_list "$DIFF_DIR/_casks_to_install.txt" "Casks to install" "[INSTALL]"
show_list "$DIFF_DIR/_mas_to_install.txt" "MAS apps to install (ids)" "[INSTALL]"
show_defaults "$DIFF_DIR/_defaults_issues.tsv"
show_dotfiles "$DIFF_DIR/_dotfiles_issues.tsv"

echo "---"
echo "See full report: ${report_line#*: }"

# If there are conflicts, suggest backing them up before apply
if [[ -s "$DIFF_DIR/_dotfiles_issues.tsv" ]]; then
  conflicts=$(grep -E $'\tconflict_(file|dir)\t' "$DIFF_DIR/_dotfiles_issues.tsv" | wc -l | tr -d ' ' || true)
  if (( conflicts > 0 )); then
    echo "Hint: run 'bash tools/prepare_apply.sh' before apply to safely backup conflicts."
  fi
fi

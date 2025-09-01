#!/usr/bin/env bash
set -euo pipefail

# Prune snapshots/* directories, keeping the latest N by name (timestamp-based).
# Dry-run by default.

KEEP=5
DRY_RUN=true

usage() {
  cat << 'USAGE'
prune_snapshots.sh [--keep N] [--apply]

Prune old snapshot directories under snapshots/, snapshots/desired/, snapshots/diff/ (keeps symlinks).
Defaults to dry-run; pass --apply to actually remove.
USAGE
}

for ((i = 1; i <= $#; i++)); do
  case "${!i}" in
    --keep)
      j=$((i + 1))
      KEEP=${!j:-5}
      ;;
    --apply)
      DRY_RUN=false
      ;;
    -h | --help)
      usage
      exit 0
      ;;
  esac
done

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

prune_dir() { # (path)
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  # Build list of child directories (names only), sorted ascending
  local list
  list=$(find "$dir" -mindepth 1 -maxdepth 1 -type d -not -type l -printf '%f\n' 2> /dev/null | sort || true)
  local all=()
  if [[ -n "$list" ]]; then
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      all+=("$name")
    done <<< "$list"
  fi
  local count=${#all[@]}
  ((count <= KEEP)) && return 0
  local start=0
  local end=$((count - KEEP))
  local idx
  for ((idx = start; idx < end; idx++)); do
    run rm -rf -- "$dir/${all[$idx]}"
  done
}

log "Pruning snapshots, keeping last $KEEP (dry-run=$DRY_RUN)"
prune_dir snapshots || true
prune_dir snapshots/desired || true
prune_dir snapshots/diff || true
log "Done."

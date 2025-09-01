#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
apply-hidutil.sh [--apply] [--reset]

Apply keyboard modifier remaps via macOS hidutil.

Behavior:
  - By default, performs a dry-run and prints what would be applied.
  - Reads config from config/hidutil.json (if present).
  - Use --apply to execute. Use --reset to clear mappings.

Notes:
  - This is per-user and non-destructive. You can re-run anytime.
  - For login persistence, consider a LaunchAgent calling this script at login.
USAGE
}

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

require_macos

DO_APPLY=false
DO_RESET=false
while (("$#")); do
  case "$1" in
    --apply)
      DO_APPLY=true
      shift
      ;;
    --reset)
      DO_RESET=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      warn "Ignoring unknown arg: $1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

CFG_PATH="$REPO_ROOT/config/hidutil.json"

if [[ "$DO_RESET" == "true" ]]; then
  payload='{"UserKeyMapping":[]}'
  log "Resetting hidutil mappings to empty."
else
  if [[ -f "$CFG_PATH" ]]; then
    payload="$(cat "$CFG_PATH")"
  else
    warn "No config at config/hidutil.json. Add one (see config/examples/hidutil.json)."
    exit 0
  fi
fi

log "hidutil payload preview:" && while IFS= read -r line; do printf "  %s\n" "$line"; done <<< "$payload"

if [[ "$DO_APPLY" == "true" ]]; then
  if ! command -v hidutil > /dev/null 2>&1; then
    die "hidutil not found. Requires macOS 10.12+."
  fi
  log "Applying hidutil mapping…"
  hidutil property --set "$payload"
  log "hidutil apply done."
else
  log "Dry-run. Re-run with --apply to execute."
fi

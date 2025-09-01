#!/usr/bin/env bash
set -euo pipefail

# Manage homesetup profiles (personas/flavors)
# Profiles live under config/profiles/<name>/profile.env
# Active profile is copied to ~/.config/homesetup/profile.env

DRY_RUN=true
CMD="list"
PROFILE=""

usage() {
  cat << 'USAGE'
profile.sh [list|activate <name>] [--apply]

Manage profiles:
  list                    List available profile names
  activate <name>         Set the active profile (writes ~/.config/homesetup/profile.env)

Flags:
  --apply                 Perform changes (default: dry-run)
USAGE
}

case "${1:-}" in
  list) CMD=list; shift || true ;;
  activate) CMD=activate; PROFILE=${2:-}; shift 2 || true ;;
  -h|--help|"") usage; exit 0 ;;
  *) usage; echo "Unknown command: $1" >&2; exit 2 ;;
esac

for arg in "$@"; do
  case "$arg" in
    --apply) DRY_RUN=false ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

profiles_dir="$REPO_ROOT/config/profiles"

if [[ "$CMD" == "list" ]]; then
  if [[ ! -d "$profiles_dir" ]]; then die "No profiles dir: $profiles_dir"; fi
  # Portable directory enumeration (BSD/macOS compatible)
  for d in "$profiles_dir"/*; do
    [[ -d "$d" ]] || continue
    basename "$d"
  done | sort
  exit 0
fi

if [[ "$CMD" == "activate" ]]; then
  [[ -n "$PROFILE" ]] || die "Missing profile name."
  src="$profiles_dir/$PROFILE/profile.env"
  [[ -f "$src" ]] || die "Profile not found: $PROFILE"
  dest="$HOME/.config/homesetup/profile.env"
  run "mkdir -p \"$HOME/.config/homesetup\""
  run "cp -f \"$src\" \"$dest\""
  log "Activated profile '$PROFILE' (dry-run=${DRY_RUN}). Open a new shell to take effect."
  exit 0
fi

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
switch_profile.sh <name> [--no-apply]

Activate a homesetup profile and optionally apply the full setup.
By default, runs `make apply` after activation.

Examples:
  bash tools/switch_profile.sh dev          # activate + apply
  bash tools/switch_profile.sh minimal      # activate + apply
  bash tools/switch_profile.sh dev --no-apply  # activate only
USAGE
}

PROFILE=${1:-}
APPLY=true
shift || true
for arg in "$@"; do
  case "$arg" in
    --no-apply) APPLY=false ;;
    -h|--help) usage; exit 0 ;;
  esac
done

if [[ -z "$PROFILE" ]]; then
  usage; exit 2
fi

log() { printf "[+] %s\n" "$*"; }

log "Activating profile: $PROFILE"
bash "$(dirname "$0")/profile.sh" activate "$PROFILE" --apply

if [[ "$APPLY" == true ]]; then
  log "Applying setup for profile: $PROFILE"
  make apply
else
  log "Profile activated. Skipping apply."
fi


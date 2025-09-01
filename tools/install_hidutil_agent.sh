#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
install_hidutil_agent.sh [--remove]

Install (or remove) a LaunchAgent to apply hidutil mappings at login.

Behavior:
  - Installs: copies template config/hidutil.launchagent.example.plist to
    ~/Library/LaunchAgents/com.homesetup.hidutil.plist with the repo path baked in.
  - Loads/unloads with launchctl for the current user.
  - Use --remove to unload and remove the LaunchAgent.
USAGE
}

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

require_macos

DO_REMOVE=false
while (("$#")); do
  case "$1" in
    --remove) DO_REMOVE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Ignoring unknown arg: $1"; shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
LOG_DIR="$REPO_ROOT/snapshots/logs"
mkdir -p "$LOG_DIR"

PLIST_TEMPLATE="$REPO_ROOT/config/hidutil.launchagent.example.plist"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
DEST_PLIST="$LAUNCH_DIR/com.homesetup.hidutil.plist"

mkdir -p "$LAUNCH_DIR"

if [[ "$DO_REMOVE" == true ]]; then
  if [[ -f "$DEST_PLIST" ]]; then
    log "Unloading LaunchAgent…"
    launchctl unload "$DEST_PLIST" || true
    rm -f "$DEST_PLIST"
    log "Removed: $DEST_PLIST"
  else
    warn "No agent found at $DEST_PLIST"
  fi
  exit 0
fi

[[ -f "$PLIST_TEMPLATE" ]] || die "Template not found: $PLIST_TEMPLATE"

# Bake repo path into template safely
escaped_root=${REPO_ROOT//\//\/}
sed "s/__REPO_ROOT__/$escaped_root/g" "$PLIST_TEMPLATE" > "$DEST_PLIST"

log "Loading LaunchAgent: $DEST_PLIST"
launchctl unload "$DEST_PLIST" 2>/dev/null || true
launchctl load -w "$DEST_PLIST"
log "Installed and loaded. It will apply your mapping at login."

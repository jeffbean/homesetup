#!/usr/bin/env bash
set -euo pipefail

# Orchestrate apply flow: bootstrap, dotfiles, assistants policy, and session reload.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

log "Applying desired state…"
bash "$REPO_ROOT/setup/bootstrap_macos.sh"
bash "$REPO_ROOT/tools/apply_dotfiles.sh"

# Assistants install policy: apply only if ASSISTANTS=1
ASS="${ASSISTANTS:-}"
if [[ "$ASS" == "1" || "$ASS" == "true" ]]; then
  bash "$REPO_ROOT/setup/install-assistants.sh" --apply || true
else
  log "Skipping assistants (set ASSISTANTS=1 to apply)"
fi

# Reload tmux + zsh
bash "$REPO_ROOT/tools/reload_sessions.sh" || true
log "Apply complete."

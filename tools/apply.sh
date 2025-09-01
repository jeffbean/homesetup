#!/usr/bin/env bash
set -euo pipefail

# Orchestrate apply flow: bootstrap, dotfiles, assistants policy, and session reload.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

load_profile_env

log "Applying desired state…"
bash "$REPO_ROOT/setup/bootstrap_macos.sh"
bash "$REPO_ROOT/tools/apply_dotfiles.sh"

# Assistants install policy mirrors previous Makefile logic
ASS="${ASSISTANTS:-}"
if [[ "$ASS" == "1" || "$ASS" == "true" ]]; then
  bash "$REPO_ROOT/setup/install-assistants.sh" --apply || true
elif [[ "$ASS" == "0" || "$ASS" == "false" ]]; then
  log "Skipping assistants (ASSISTANTS=$ASS)"
else
  # default: read profile assistants.env to decide
  WANT_APPLY=0
  if [[ -r "$REPO_ROOT/config/profiles/$HS_PROFILE/assistants.env" ]]; then
    # shellcheck disable=SC1090
    source "$REPO_ROOT/config/profiles/$HS_PROFILE/assistants.env"
    if [[ "${INSTALL_CODEX:-0}" == "1" || "${INSTALL_CODEX:-false}" == "true" ]]; then WANT_APPLY=1; fi
    if [[ "${INSTALL_CLAUDE:-0}" == "1" || "${INSTALL_CLAUDE:-false}" == "true" ]]; then WANT_APPLY=1; fi
  fi
  if [[ "$WANT_APPLY" == "1" ]]; then
    log "Assistants enabled by profile '$HS_PROFILE' → applying"
    bash "$REPO_ROOT/setup/install-assistants.sh" --apply || true
  else
    log "Assistants disabled by profile '$HS_PROFILE' → skipping"
  fi
fi

# Reload tmux + zsh
bash "$REPO_ROOT/tools/reload_sessions.sh" || true
log "Apply complete."


#!/usr/bin/env bash
set -euo pipefail

# Reload tmux and trigger a zsh reload in the current pane (if inside tmux).
# Safe to run multiple times; avoids touching parent process if not in tmux.

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

# 1) Reload tmux config for current server if inside tmux
if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" || true
  log "tmux config reloaded."
fi

# 2) Ask current pane to exec a fresh login zsh so OMZ theme takes effect
# Only if inside tmux; outside tmux we cannot affect the parent shell safely.
if [[ -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
  # Delay slightly so it runs after make completes and prompt is idle
  ( sleep 0.2; tmux send-keys -t "$TMUX_PANE" "exec zsh -l" Enter ) >/dev/null 2>&1 &
  log "scheduled zsh reload in current tmux pane."
else
  log "not in tmux; run 'exec zsh -l' to reload shell."
fi

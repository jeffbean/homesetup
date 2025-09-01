#!/usr/bin/env bash
set -euo pipefail

# Link dotfiles packages into $HOME via stow (idempotent). Overlays applied per profile.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

load_profile_env

if [[ ! -d "$REPO_ROOT/dotfiles" ]] || [[ -z "$(ls -A "$REPO_ROOT/dotfiles" 2>/dev/null)" ]]; then
  echo "dotfiles/ is empty. Add packages (subfolders) to stow."
  exit 0
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "stow not installed. Install with: brew install stow"
  exit 0
fi

shopt -s nullglob
for pkg in "$REPO_ROOT/dotfiles"/*; do
  [[ -d "$pkg" ]] || continue
  echo "Stowing package: ${pkg##*/}"
  stow --no-folding -d "$REPO_ROOT/dotfiles" -vt "$HOME" "${pkg##*/}"
done

if [[ -n "$HS_PROFILE" ]] && [[ -d "$REPO_ROOT/dotfiles/overlays/$HS_PROFILE" ]]; then
  for pkg in "$REPO_ROOT/dotfiles/overlays/$HS_PROFILE"/*; do
    [[ -d "$pkg" ]] || continue
    echo "Stowing overlay ($HS_PROFILE): ${pkg##*/}"
    stow --no-folding -d "$REPO_ROOT/dotfiles/overlays/$HS_PROFILE" -vt "$HOME" "${pkg##*/}"
  done
fi

log "dotfiles apply complete (profile=$HS_PROFILE)"


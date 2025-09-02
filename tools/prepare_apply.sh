#!/usr/bin/env bash
set -euo pipefail

# Prepare $HOME for stow by removing or backing up blocking files.
# Strategy:
# - If target exists and is a symlink: leave as-is (stow will repoint if needed)
# - If target exists and is a regular file:
#     - If corresponding repo file is tracked by git, remove target (no backup)
#       (we rely on git for versioned content; stow will create the symlink)
#     - If untracked (not in git), back it up to <path>.backup.<timestamp>
# - If target exists and is a directory:
#     - If empty, remove; otherwise back it up to <path>.backup.<timestamp>

TS="$(date +%s)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)"
DOT_ROOT="$REPO_ROOT/dotfiles"

echo "[+] Preparing for stow (timestamp=$TS)…"

shopt -s nullglob
for pkg in "$DOT_ROOT"/*; do
  [[ -d "$pkg" ]] || continue
  while IFS= read -r -d '' f; do
    rel=${f#"$pkg/"}
    target="$HOME/$rel"
    # Only act when a blocking path exists
    if [[ -e "$target" ]]; then
      # If it's a symlink, let stow handle it
      if [[ -L "$target" ]]; then
        continue
      fi
      # If it's a regular file
      if [[ -f "$target" ]]; then
        # Determine if the repo file is tracked by git
        # Convert absolute repo path to repo-relative
        repo_rel=${f#"$REPO_ROOT/"}
        if (cd "$REPO_ROOT" && git ls-files --error-unmatch "$repo_rel" >/dev/null 2>&1); then
          echo "[+] Removing tracked file to allow symlink: $target"
          rm -f "$target"
        else
          bkp="$target.backup.$TS"
          echo "[+] Backing up untracked file: $target -> $bkp"
          mv "$target" "$bkp"
        fi
        continue
      fi
      # If it's a directory
      if [[ -d "$target" ]]; then
        if [[ -z "$(ls -A "$target" 2>/dev/null)" ]]; then
          echo "[+] Removing empty directory: $target"
          rmdir "$target" || true
        else
          bkp="$target.backup.$TS"
          echo "[+] Backing up directory: $target -> $bkp"
          mv "$target" "$bkp"
        fi
      fi
    fi
  done < <(find "$pkg" -type f -not -path '*/.git/*' -print0)
done

echo "[+] Prep complete. Any backups end with .backup.$TS"

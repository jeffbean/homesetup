#!/usr/bin/env bash
set -euo pipefail

# Backup conflicting files in $HOME that would block stow from linking.
# Creates backups as <path>.backup.<timestamp> and removes originals.

TS="$(date +%s)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)"
DOT_ROOT="$REPO_ROOT/dotfiles"

echo "[+] Scanning for conflicts to backup (timestamp=$TS)…"

shopt -s nullglob
for pkg in "$DOT_ROOT"/*; do
  [[ -d "$pkg" ]] || continue
  while IFS= read -r -d '' f; do
    rel=${f#"$pkg/"}
    target="$HOME/$rel"
    # only backup regular files that exist and are not symlinks
    if [[ -e "$target" && ! -L "$target" ]]; then
      bkp="$target.backup.$TS"
      mkdir -p "$(dirname "$target")"
      echo "[+] Backing up: $target -> $bkp"
      mv "$target" "$bkp"
    fi
  done < <(find "$pkg" -type f -not -path '*/.git/*' -print0)
done

echo "[+] Backup complete. You can restore by moving *.backup.$TS back."


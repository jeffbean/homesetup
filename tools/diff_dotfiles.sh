#!/usr/bin/env bash
set -euo pipefail

# Produce a unified diff between repo dotfiles and current $HOME content.

log() { printf "[+] %s\n" "$*"; }
error() {
  printf "[x] %s\n" "$*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || error "This tool targets macOS (Darwin)."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$REPO_ROOT/snapshots/diff/$STAMP"
mkdir -p "$OUT_DIR"
PATCH="$OUT_DIR/dotfiles.patch"

DOT_ROOT="$REPO_ROOT/dotfiles"
[[ -d "$DOT_ROOT" ]] || {
  echo "No dotfiles/ directory found." > "$PATCH"
  log "Wrote: $PATCH"
  exit 0
}

changes=0

shopt -s nullglob
for pkg in "$DOT_ROOT"/*; do
  [[ -d "$pkg" ]] || continue
  pkgname=$(basename "$pkg")
  while IFS= read -r -d '' src; do
    rel=${src#"$pkg/"}
    # skip macOS cruft
    [[ "$(basename "$src")" == ".DS_Store" ]] && continue
    dest="$HOME/$rel"
    label_src="repo:$pkgname/$rel"
    label_dst="home:$dest"
    if [[ -e "$dest" || -L "$dest" ]]; then
      if cmp -s "$src" "$dest"; then
        continue
      else
        echo "diff -u $label_src $label_dst" >> "$PATCH"
        diff -u --label "$label_src" --label "$label_dst" "$src" "$dest" >> "$PATCH" || true
        echo >> "$PATCH"
        changes=$((changes + 1))
      fi
    else
      # New file that would be created
      echo "diff -u $label_src $label_dst (new file)" >> "$PATCH"
      diff -u --label "$label_src" --label "$label_dst" /dev/null "$src" >> "$PATCH" || true
      echo >> "$PATCH"
      changes=$((changes + 1))
    fi
  done < <(find "$pkg" -type f -not -path '*/.git/*' -print0)
done

if [[ $changes -eq 0 ]]; then
  echo "No dotfile content differences found." > "$PATCH"
fi

ln -sfn "$OUT_DIR" "$REPO_ROOT/snapshots/diff/latest"
log "Dotfiles content diff written to: $PATCH"
echo "Summary: $changes file(s) differ."
[[ -s "$PATCH" ]] && {
  echo "---"
  sed -n '1,200p' "$PATCH"
} || true

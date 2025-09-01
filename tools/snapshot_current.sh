#!/usr/bin/env bash
set -euo pipefail

# Snapshot current machine state for diffing against desired setup.
# Captures: Homebrew formulae/casks, MAS apps, selected macOS defaults, dotfiles link status.

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

require_macos

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$REPO_ROOT/snapshots/$STAMP"
mkdir -p "$OUT_DIR"

# ---------- Homebrew ----------
if command -v brew > /dev/null 2>&1; then
  log "Capturing Homebrew packages…"
  brew --version | head -n1 > "$OUT_DIR/brew_version.txt" || true
  brew list --formula --versions | sort > "$OUT_DIR/brew_formulae.txt" || true
  brew list --cask --versions | sort > "$OUT_DIR/brew_casks.txt" || true
  brew leaves | sort > "$OUT_DIR/brew_leaves.txt" || true
else
  warn "Homebrew not found; skipping brew snapshot."
fi

# ---------- Mac App Store (mas) ----------
if command -v mas > /dev/null 2>&1; then
  log "Capturing MAS apps…"
  mas version > "$OUT_DIR/mas_version.txt" || true
  mas list | sort -k1,1 > "$OUT_DIR/mas_apps.txt" || true
else
  warn "mas CLI not found; skipping MAS snapshot. (brew install mas)"
fi

# ---------- macOS defaults (only those touched by setup/defaults.sh) ----------
DEFAULTS_SCRIPT="$REPO_ROOT/setup/defaults.sh"
if [[ -f "$DEFAULTS_SCRIPT" ]]; then
  log "Capturing macOS defaults referenced in setup/defaults.sh…"
  KEYS_FILE="$OUT_DIR/_defaults_keys.tsv"
  : > "$KEYS_FILE"
  {
    sed -nE 's/^[[:space:]]*run[[:space:]]*"([^"]*)".*/\1/p' "$DEFAULTS_SCRIPT"
    sed -nE '/^[[:space:]]*defaults[[:space:]]+(-currentHost[[:space:]]+)?write[[:space:]]+/p' "$DEFAULTS_SCRIPT"
  } | while IFS= read -r line; do
    set -- "$line"
    # strip leading tokens: defaults [-currentHost] write
    [[ "${1:-}" == "defaults" ]] && shift || true
    [[ "${1:-}" == "-currentHost" ]] && shift || true
    [[ "${1:-}" == "write" ]] && shift || true
    domain=${1:-}
    key=${2:-}
    if [[ -n "$domain" && -n "$key" ]]; then
      printf "%s %s\n" "$domain" "$key" >> "$KEYS_FILE"
    fi
  done
  sort -u "$KEYS_FILE" -o "$KEYS_FILE" || true

  {
    echo "# domain key = current_value"
    while read -r domain key; do
      [[ -n "$domain" && -n "$key" ]] || continue
      if out=$(defaults read "$domain" "$key" 2> /dev/null); then
        printf "%s %s = %s\n" "$domain" "$key" "$out"
      else
        printf "%s %s = <not set>\n" "$domain" "$key"
      fi
    done < "$KEYS_FILE"
  } > "$OUT_DIR/defaults_values.txt"
else
  warn "No setup/defaults.sh found; skipping defaults snapshot."
fi

# ---------- Dotfiles link status (stow targets) ----------
log "Capturing dotfiles link status…"

DOT_ROOT="$REPO_ROOT/dotfiles"
{
  echo -e "package\trelpath\tstate\ttarget\tlink_target"
  if [[ -d "$DOT_ROOT" ]]; then
    shopt -s nullglob
    for pkg in "$DOT_ROOT"/*; do
      [[ -d "$pkg" ]] || continue
      pkgname=$(basename "$pkg")
      while IFS= read -r -d '' f; do
        relpath=${f#"$pkg/"}
        target="$HOME/$relpath"
        state="missing"
        link_target=""
        base="$(basename "$f")"
        [[ "$base" == ".DS_Store" ]] && continue
        if [[ -L "$target" ]]; then
          lt=$(readlink "$target" || true)
          link_target="$lt"
          # try to resolve both and compare
          if [[ "$(resolve_path "$target")" == "$(resolve_path "$f")" ]]; then
            state="linked_ok"
          else
            state="symlink_other"
          fi
        elif [[ -e "$target" ]]; then
          if [[ -d "$target" ]]; then state="conflict_dir"; else state="conflict_file"; fi
        else
          state="missing"
        fi
        printf "%s\t%s\t%s\t%s\t%s\n" "$pkgname" "$relpath" "$state" "$target" "$link_target"
      done < <(find "$pkg" -type f -not -path '*/.git/*' -not -name '.DS_Store' -print0)
    done
  fi
} > "$OUT_DIR/dotfiles_status.tsv"

# ---------- Latest symlink ----------
ln -sfn "$OUT_DIR" "$REPO_ROOT/snapshots/latest"

log "Snapshot written to: $OUT_DIR"

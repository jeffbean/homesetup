#!/usr/bin/env bash
set -euo pipefail

# Generate desired state from this repo: Brewfile, defaults, and dotfiles.

log() { printf "[+] %s\n" "$*"; }
error() {
  printf "[x] %s\n" "$*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || error "This tool targets macOS (Darwin)."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

# Load active profile if present
if [[ -r "$HOME/.config/homesetup/profile.env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/homesetup/profile.env"
fi
: "${HS_PROFILE:=base}"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$REPO_ROOT/snapshots/desired/$STAMP"
mkdir -p "$OUT_DIR"

# ---------- Brewfile parsing ----------
# Compose Brewfile with profile extras if available
BREWFILE="$REPO_ROOT/Brewfile"
if [[ -n "${HS_PROFILE:-}" && -f "$REPO_ROOT/config/profiles/${HS_PROFILE}/Brewfile.extra" ]]; then
  TMP_COMPOSED="$REPO_ROOT/snapshots/logs/Brewfile.composed.$STAMP"
  mkdir -p "$REPO_ROOT/snapshots/logs"
  {
    cat "$REPO_ROOT/Brewfile"
    printf "\n# --- Profile: %s extras ---\n" "${HS_PROFILE}"
    cat "$REPO_ROOT/config/profiles/${HS_PROFILE}/Brewfile.extra"
  } > "$TMP_COMPOSED"
  BREWFILE="$TMP_COMPOSED"
fi
if [[ -f "$BREWFILE" ]]; then
  log "Parsing Brewfile…"
  # formulae
  sed -nE 's/^[[:space:]]*brew[[:space:]]+"([^"]+)".*$/\1/p' "$BREWFILE" | sort -u > "$OUT_DIR/desired_brew_formulae.txt" || true
  # casks
  sed -nE 's/^[[:space:]]*cask[[:space:]]+"([^"]+)".*$/\1/p' "$BREWFILE" | sort -u > "$OUT_DIR/desired_brew_casks.txt" || true
  # mas apps: extract id and name
  sed -nE 's/^[[:space:]]*mas[[:space:]]+"([^"]+)".*,[[[:space:]]]*id:[[:space:]]*([0-9]+).*/\2\t\1/p' "$BREWFILE" | sort -u > "$OUT_DIR/desired_mas_apps.tsv" || true
else
  : > "$OUT_DIR/desired_brew_formulae.txt"
  : > "$OUT_DIR/desired_brew_casks.txt"
  : > "$OUT_DIR/desired_mas_apps.tsv"
fi

# ---------- Defaults desired values ----------
DEFAULTS_SCRIPT="$REPO_ROOT/setup/defaults.sh"
DESIRED_DEFAULTS="$OUT_DIR/defaults_desired.tsv"
if [[ -f "$DEFAULTS_SCRIPT" ]]; then
  log "Extracting desired macOS defaults…"
  # Extract the actual defaults command from lines like: run "defaults write …" or plain defaults lines
  {
    sed -nE 's/^[[:space:]]*run[[:space:]]*"([^"]*)".*/\1/p' "$DEFAULTS_SCRIPT"
    sed -nE '/^[[:space:]]*defaults[[:space:]]+(-currentHost[[:space:]]+)?write[[:space:]]+/p' "$DEFAULTS_SCRIPT"
  } |
    while IFS= read -r cmd; do
      # tokenize
      read -r -a toks <<< "$cmd"
      # toks[0]=defaults
      idx=1
      if [[ "${toks[$idx]:-}" == "-currentHost" ]]; then
        ((idx++))
      fi
      [[ "${toks[$idx]:-}" == "write" ]] || continue
      ((idx++))
      domain="${toks[$idx]:-}"
      ((idx++))
      key="${toks[$idx]:-}"
      ((idx++))
      type="${toks[$idx]:-}"
      value=""
      if [[ "$type" =~ ^-(bool|int|float|string)$ ]]; then
        ((idx++))
        value="${toks[$idx]:-}"
        # normalize value by type
        case "$type" in
          -bool) value=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
          -int | -float | -string) : ;; # keep as-is
        esac
      else
        # no explicit type; capture remainder as value string
        rest=("${toks[@]:$idx}")
        value="${rest[*]}"
      fi
      printf "%s\t%s\t%s\t%s\n" "$domain" "$key" "$type" "$value"
    done | sort -u > "$DESIRED_DEFAULTS"
else
  : > "$DESIRED_DEFAULTS"
fi

# ---------- Dotfiles expected links ----------
DOT_ROOT="$REPO_ROOT/dotfiles"
DESIRED_DOTFILES="$OUT_DIR/dotfiles_expected.tsv"
{
  echo -e "package\trelpath\ttarget"
  if [[ -d "$DOT_ROOT" ]]; then
    shopt -s nullglob
    for pkg in "$DOT_ROOT"/*; do
      [[ -d "$pkg" ]] || continue
      pkgname=$(basename "$pkg")
      while IFS= read -r -d '' f; do
        relpath=${f#"$pkg/"}
        target="$HOME/$relpath"
        printf "%s\t%s\t%s\n" "$pkgname" "$relpath" "$target"
      done < <(find "$pkg" -type f -not -path '*/.git/*' -not -name '.DS_Store' -print0)
    done
  fi
} > "$DESIRED_DOTFILES"

# ---------- Latest symlink ----------
ln -sfn "$OUT_DIR" "$REPO_ROOT/snapshots/desired/latest"

log "Desired state written to: $OUT_DIR"

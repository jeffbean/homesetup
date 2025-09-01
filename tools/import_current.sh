#!/usr/bin/env bash
set -euo pipefail

# Import the current machine state into this repo (Brewfile, defaults, dotfiles).
# By default, runs in dry-run mode and writes proposals under snapshots/proposed/.
# Use --apply to write into repo files.

usage() {
  cat << 'USAGE'
import_current.sh [--apply] [--pkg NAME]

Actions:
  - Generate Brewfile from current Homebrew install (brew bundle dump)
  - Generate setup/defaults.sh from current values (based on snapshot/defaults)
  - Copy selected $HOME paths (from config/dotfiles_paths.txt) into dotfiles/<pkg>/

Flags:
  --apply       Write into repo (Brewfile, setup/defaults.sh, dotfiles/)
  --pkg NAME    Dotfiles package folder name (default: base)
  -h, --help    Show help

Notes:
  - Uses snapshots/latest/defaults_values.txt if present; runs snapshot if missing.
  - Only paths listed in config/dotfiles_paths.txt are imported.
USAGE
}

APPLY=false
PKG="base"
while (("$#")); do
  case "$1" in
    --apply)
      APPLY=true
      shift
      ;;
    --pkg)
      PKG="${2:-base}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) shift ;;
  esac
done

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

require_macos
STAMP="$(date +%Y%m%d-%H%M%S)"
PROPOSED_DIR="$REPO_ROOT/snapshots/proposed/$STAMP"
mkdir -p "$PROPOSED_DIR"

# Ensure we have a current snapshot for defaults
CUR_SNAP="$REPO_ROOT/snapshots/latest"
if [[ ! -d "$CUR_SNAP" ]]; then
  log "No current snapshot found; running snapshot…"
  bash "$REPO_ROOT/tools/snapshot_current.sh"
fi
CUR_SNAP="$REPO_ROOT/snapshots/latest"

# ---------- Brewfile ----------
if command -v brew > /dev/null 2>&1; then
  log "Generating Brewfile from current system (brew bundle dump)…"
  tmp_brew="$PROPOSED_DIR/Brewfile"
  mkdir -p "$(dirname "$tmp_brew")"
  # Prefer descriptive entries; fall back gracefully if option unsupported
  brew bundle dump --file "$tmp_brew" --describe --force > /dev/null 2>&1 ||
    brew bundle dump --file "$tmp_brew" --force > /dev/null 2>&1 ||
    brew bundle dump --file "$tmp_brew" --force || true
  if [[ "$APPLY" == "true" ]]; then
    log "Writing Brewfile to config/Brewfile."
    mkdir -p "$REPO_ROOT/config"
    cp "$tmp_brew" "$REPO_ROOT/config/Brewfile"
  else
    log "Dry-run: proposed Brewfile at $tmp_brew"
  fi
else
  warn "Homebrew not found; skipping Brewfile generation."
fi

# ---------- Defaults ----------
CUR_DEFAULTS="$CUR_SNAP/defaults_values.txt"
gen_defaults() {
  local out="$1"
  cat > "$out" << 'HDR'
#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      cat <<'USAGE'
defaults.sh (generated)

Apply macOS system defaults captured from the current machine.
Use --dry-run to print the commands without applying changes.
USAGE
      exit 0
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

echo "Applying macOS defaults (DRY_RUN=$DRY_RUN)…"
HDR
  # read current defaults and emit write commands
  # expected format: "domain key = value" or value "<not set>"
  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    domain=$(echo "$line" | awk '{print $1}')
    key=$(echo "$line" | awk '{print $2}')
    rest=${line#*= }
    [[ -z "$domain" || -z "$key" ]] && continue
    if [[ "$rest" == "<not set>" || -z "$rest" ]]; then
      continue
    fi
    val="$rest"
    # detect type
    low=$(echo "$val" | tr '[:upper:]' '[:lower:]')
    if [[ "$low" == "true" || "$low" == "false" || "$val" == "1" || "$val" == "0" ]]; then
      # normalize to true/false
      case "$val" in 1) val=true ;; 0) val=false ;; esac
      echo "run \"defaults write $domain $key -bool $val\"" >> "$out"
    elif [[ "$val" =~ ^-?[0-9]+$ ]]; then
      echo "run \"defaults write $domain $key -int $val\"" >> "$out"
    elif [[ "$val" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
      echo "run \"defaults write $domain $key -float $val\"" >> "$out"
    else
      # escape double quotes in strings
      sval=${val//\"/\\\"}
      echo "run \"defaults write $domain $key -string \"$sval\"\"" >> "$out"
    fi
  done < "$CUR_DEFAULTS"
  echo -e "\necho \"Done. Some changes may require logout/restart of apps.\"" >> "$out"
}

if [[ -f "$CUR_DEFAULTS" ]]; then
  log "Generating defaults script from current values…"
  tmp_defaults="$PROPOSED_DIR/defaults.sh"
  gen_defaults "$tmp_defaults"
  chmod +x "$tmp_defaults"
  if [[ "$APPLY" == "true" ]]; then
    log "Writing generated defaults to setup/defaults.sh"
    mkdir -p "$REPO_ROOT/setup"
    cp "$tmp_defaults" "$REPO_ROOT/setup/defaults.sh"
  else
    log "Dry-run: proposed defaults at $tmp_defaults"
  fi
else
  warn "No defaults snapshot found at $CUR_DEFAULTS; run make snapshot first."
fi

# ---------- Dotfiles ----------
CONF_FILE="$REPO_ROOT/config/dotfiles_paths.txt"
if [[ ! -f "$CONF_FILE" ]]; then
  log "Creating template config/dotfiles_paths.txt (edit to include files to import)."
  mkdir -p "$REPO_ROOT/config"
  cat > "$CONF_FILE" << 'TPL'
# List paths relative to $HOME to import into dotfiles/<pkg>/
# Examples:
# .zshrc
# .gitconfig
# .config/karabiner/karabiner.json
# .config/kitty/kitty.conf
TPL
fi

copy_in() {
  local src="$1" dest_root="$2"
  local dest="$dest_root/$src"
  mkdir -p "$(dirname "$dest")"
  # Prefer rsync if available for robust copy; fall back to cp -RL
  if command -v rsync > /dev/null 2>&1; then
    rsync -aL --exclude ".DS_Store" "$HOME/$src" "$dest" 2> /dev/null || rsync -aL --exclude ".DS_Store" "$HOME/$src" "$dest_root/"
  else
    if [[ -d "$HOME/$src" ]]; then
      cp -RL "$HOME/$src" "$dest_root/$src"
    else
      cp -L "$HOME/$src" "$dest"
    fi
  fi
}

DOT_DEST="$REPO_ROOT/dotfiles/$PKG"
mkdir -p "$DOT_DEST"
imported=0
while IFS= read -r line; do
  # strip comments/whitespace
  line="${line%%#*}"
  line="${line%%$'\r'}"
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  if [[ -e "$HOME/$line" ]]; then
    log "Importing $HOME/$line -> dotfiles/$PKG/$line"
    if [[ "$APPLY" == "true" ]]; then
      copy_in "$line" "$DOT_DEST"
    else
      mkdir -p "$PROPOSED_DIR/dotfiles/$PKG/$(dirname "$line")"
      if [[ -d "$HOME/$line" ]]; then
        (cd "$HOME" && tar -cf - "$line") | (cd "$PROPOSED_DIR/dotfiles/$PKG" && tar -xf -)
      else
        cp -L "$HOME/$line" "$PROPOSED_DIR/dotfiles/$PKG/$line"
      fi
    fi
    imported=$((imported + 1))
  else
    warn "Path not found in HOME: $line"
  fi
done < "$CONF_FILE"

if [[ "$APPLY" == "true" ]]; then
  log "Import completed (pkg=$PKG, files imported=$imported)."
else
  log "Dry-run completed. Proposed files under: $PROPOSED_DIR"
  ln -sfn "$PROPOSED_DIR" "$REPO_ROOT/snapshots/proposed/latest"
fi

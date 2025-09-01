#!/usr/bin/env bash
set -euo pipefail

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

usage() {
  cat << 'USAGE'
bootstrap_macos.sh

Bootstraps a personal macOS machine:
  - Ensures Homebrew is installed
  - Runs `brew bundle` if Brewfile exists
  - Executes macOS defaults if `setup/defaults.sh` exists

Flags:
  --yes        Non-interactive; auto-approve actions
  --no-bundle  Skip `brew bundle`
  --no-defaults  Skip `setup/defaults.sh`
USAGE
}


AUTO_YES=false
DO_BUNDLE=true
DO_DEFAULTS=true
for arg in "$@"; do
  case "$arg" in
    --yes) AUTO_YES=true ;;
    --no-bundle) DO_BUNDLE=false ;;
    --no-defaults) DO_DEFAULTS=false ;;
    -h | --help)
      usage
      exit 0
      ;;
  esac
done

require_macos

# Xcode Command Line Tools (optional, but recommended)
if ! xcode-select -p > /dev/null 2>&1; then
  warn "Xcode Command Line Tools not found. Some builds may fail."
  if confirm "Install Xcode Command Line Tools now?"; then
    xcode-select --install || true
    warn "Installer launched. Re-run bootstrap after installation completes."
  fi
fi

# Homebrew
if ! command -v brew > /dev/null 2>&1; then
  log "Installing Homebrew…"
  if confirm "Run the official Homebrew installer?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($(command -v brew) shellenv)"
  else
    warn "Skipped Homebrew install. You can install later from https://brew.sh."
  fi
else
  log "Homebrew already installed: $(brew --version | head -n1)"
fi

if command -v brew > /dev/null 2>&1; then
  log "Updating Homebrew…"
  brew update || true
fi

# Brew bundle
if [[ "$DO_BUNDLE" == "true" ]]; then
  BF="$(brewfile_path)"
  if [[ -f "$BF" ]]; then
    log "Applying Brewfile (brew bundle)…"
    # No profile composition; use config/Brewfile directly
    COMPOSED_BREWFILE="$BF"
    # Preview/check, then install without upgrading. Capture verbose logs.
    TS="$(date +%Y%m%d-%H%M%S)"
    LOG_DIR="snapshots/logs"
    mkdir -p "$LOG_DIR"
    CHECK_LOG="$LOG_DIR/brew_bundle_check.$TS.log"
    APPLY_LOG="$LOG_DIR/brew_bundle_apply.$TS.log"
    brew bundle check --file="$COMPOSED_BREWFILE" > "$CHECK_LOG" 2>&1 || true
    HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle --file="$COMPOSED_BREWFILE" --no-upgrade > "$APPLY_LOG" 2>&1 || warn "brew bundle encountered issues. See $APPLY_LOG"
  else
    warn "Brewfile not found. Create one at config/Brewfile."
  fi
else
  warn "Skipping brew bundle per flag."
fi

# macOS defaults
if [[ "$DO_DEFAULTS" == "true" ]]; then
  if [[ -f setup/defaults.sh ]]; then
    log "Applying macOS defaults…"
    bash setup/defaults.sh || true
  else
    warn "No defaults script at setup/defaults.sh."
  fi
fi

log "Bootstrap completed. Reboot is not required unless defaults changed system UI."

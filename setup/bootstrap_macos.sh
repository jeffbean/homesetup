#!/usr/bin/env bash
set -euo pipefail

confirm() {
  local msg=${1:-"Proceed?"}
  if [[ "${AUTO_YES:-false}" == "true" ]]; then return 0; fi
  read -r -p "$msg [y/N] " reply || true
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
error() {
  printf "[x] %s\n" "$*" >&2
  exit 1
}

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

[[ "$(uname -s)" == "Darwin" ]] || error "This script is for macOS (Darwin) only."

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
  if [[ -f Brewfile ]]; then
    log "Applying Brewfile (brew bundle)…"
    # Preview/check, then install without upgrading. Capture verbose logs to snapshots/logs.
    TS="$(date +%Y%m%d-%H%M%S)"
    LOG_DIR="snapshots/logs"
    mkdir -p "$LOG_DIR"
    CHECK_LOG="$LOG_DIR/brew_bundle_check.$TS.log"
    APPLY_LOG="$LOG_DIR/brew_bundle_apply.$TS.log"
    brew bundle check --file=Brewfile > "$CHECK_LOG" 2>&1 || true
    HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle --file=Brewfile --no-upgrade > "$APPLY_LOG" 2>&1 || warn "brew bundle encountered issues. See $APPLY_LOG"
  else
    warn "Brewfile not found. Create one at repo root."
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

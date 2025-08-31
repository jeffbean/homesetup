#!/usr/bin/env bash
set -euo pipefail

# Install git-spice CLI (dry-run by default). Attempt Homebrew first.

DRY_RUN=true

usage() {
  cat << 'USAGE'
install-git-spice.sh [--apply]

Safely install git-spice on macOS. Defaults to dry-run; pass --apply to execute.

Strategy:
  1) If Homebrew has a formula/cask named "git-spice", install via brew.
  2) Otherwise, print manual install instructions with a placeholder URL.

Examples:
  bash setup/install-git-spice.sh          # dry-run
  bash setup/install-git-spice.sh --apply  # perform installation
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --apply) DRY_RUN=false ;;
    -h|--help) usage; exit 0 ;;
  esac
done

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
die() { printf "[x] %s\n" "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "This installer targets macOS."

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "+ $*"
  else
    eval "$*"
  fi
}

if command -v git >/dev/null 2>&1; then :; else die "git is required"; fi

if command -v git >/dev/null 2>&1 && git spice --version >/dev/null 2>&1; then
  log "git-spice already installed."
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  # Probe if a formula/cask exists
  if brew search --formula --exact git-spice >/dev/null 2>&1; then
    log "Installing via Homebrew formula: git-spice"
    run "brew install git-spice"
    exit 0
  fi
  if brew search --cask --exact git-spice >/dev/null 2>&1; then
    log "Installing via Homebrew cask: git-spice"
    run "brew install --cask git-spice"
    exit 0
  fi
  warn "No git-spice formula/cask found."
else
  warn "Homebrew not available."
fi

cat << 'MSG'
Manual install (dry-run output):
  1) Locate the official git-spice repository or release page.
  2) Install per upstream instructions (e.g., brew tap, curl|sh avoided, or manual binary).
  3) Ensure `git spice --version` works in your shell.

Once installed, open a new shell to pick up the binary on PATH.
MSG

exit 0


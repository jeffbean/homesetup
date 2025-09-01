#!/usr/bin/env bash
set -euo pipefail

# Repo root -> load shared lib
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

# Install local dev tools used by make check/test. Dry-run by default.

DRY_RUN=true
TOOLS=(shellcheck shfmt yamllint bats-core)

for arg in "$@"; do
  case "$arg" in
    --apply) DRY_RUN=false ;;
    -h | --help)
      cat << 'USAGE'
install-dev-tools.sh

Install developer tools required by repo targets (dry-run by default).
Tools: shellcheck, shfmt, yamllint, bats-core

Examples:
  bash setup/install-dev-tools.sh          # dry-run
  bash setup/install-dev-tools.sh --apply  # perform installation
USAGE
      exit 0
      ;;
  esac
done

if ! command -v brew > /dev/null 2>&1; then
  echo "[x] Homebrew not found. Please install Homebrew first: https://brew.sh" >&2
  exit 1
fi

log "Installing dev tools via Homebrew (DRY_RUN=${DRY_RUN})"
for pkg in "${TOOLS[@]}"; do
  if brew list --versions "$pkg" > /dev/null 2>&1; then
    log "$pkg already installed"
  else
    run "brew install $pkg"
  fi
done

log "Done."

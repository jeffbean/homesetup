#!/usr/bin/env bash
set -euo pipefail

# Install Codex CLI (dry-run by default). Requires explicit --apply to perform changes.

DRY_RUN=true
METHOD="auto" # auto|brew|npm

usage() {
  cat << 'USAGE'
install-codex.sh

Safely install Codex CLI on macOS.
Defaults to dry-run (prints commands). Pass --apply to execute.

Options:
  --apply           Perform installation (not just print)
  --method <name>   Install method: auto|brew|npm (default: auto)
  -h, --help        Show this help

Examples:
  bash setup/install-codex.sh                 # dry-run, show suggested commands
  bash setup/install-codex.sh --apply --method brew
  bash setup/install-codex.sh --apply --method npm

Notes:
  - Homebrew method expects a brew formula or tap that provides `codex`.
  - npm method expects a published package providing the `codex` binary.
  - This script avoids guessing concrete package names; confirm in docs first.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --apply) DRY_RUN=false ;;
    --method)
      shift || true
      METHOD="${1:-auto}"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
  esac
done

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
die() {
  printf "[x] %s\n" "$*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || die "This installer targets macOS."

if command -v codex > /dev/null 2>&1; then
  ver=$(codex --version 2> /dev/null || true)
  log "Codex already installed: ${ver:-unknown}"
  exit 0
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "+ $*"
  else
    eval "$*"
  fi
}

detect_method() {
  case "$METHOD" in
    brew)
      echo brew
      return
      ;;
    npm)
      echo npm
      return
      ;;
    auto)
      if command -v brew > /dev/null 2>&1; then
        echo brew
        return
      fi
      if command -v npm > /dev/null 2>&1; then
        echo npm
        return
      fi
      ;;
  esac
  echo none
}

method=$(detect_method)
[[ "$method" != none ]] || die "No supported installer found (need Homebrew or npm)."

case "$method" in
  brew)
    log "Using Homebrew method."
    cat << 'INSTR'
Notes:
  - Ensure the correct formula/tap name for Codex CLI.
  - If a tap is required (e.g., openai/codex), add `brew tap openai/codex` first.
Suggested commands:
INSTR
    run "brew tap openai/codex || true"
    run "brew install codex"
    ;;
  npm)
    log "Using npm method."
    cat << 'INSTR'
Notes:
  - Ensure the correct npm package name provides `codex` (e.g., @openai/codex-cli). Confirm in docs.
Suggested commands:
INSTR
    run "npm install -g @openai/codex-cli"
    ;;
esac

if [[ "$DRY_RUN" == true ]]; then
  log "Dry-run complete. Re-run with --apply to perform installation."
fi

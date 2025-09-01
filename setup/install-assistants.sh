#!/usr/bin/env bash
set -euo pipefail

# Install multiple AI coding assistants (dry-run by default): Codex, Claude.
# Uses existing per-tool installers when available. Never runs sudo. Idempotent.

DRY_RUN=true
INSTALL_CODEX=true
INSTALL_CLAUDE=true
CLAUDE_METHOD="auto" # auto|brew|url
CLAUDE_CASK="claude" # override if the cask name differs

usage() {
  cat << 'USAGE'
install-assistants.sh

Install AI assistants: Codex CLI and Claude Desktop.
Defaults to dry-run. Pass --apply to perform changes.

Options:
  --apply                  Execute installation commands
  --only codex|claude      Limit to a specific assistant (repeatable)
  --claude-method <m>      auto|brew|url (default: auto)
  --claude-cask <name>     Homebrew cask name (default: claude)
  -h, --help               Show help

Examples:
  bash setup/install-assistants.sh                      # dry-run for both
  bash setup/install-assistants.sh --only codex --apply # install Codex only
  bash setup/install-assistants.sh --apply --claude-method brew
USAGE
}

# Load active profile + profile-specific assistants env (so profiles can toggle installs)
if [[ -r "$HOME/.config/homesetup/profile.env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/homesetup/profile.env"
fi
 : "${HS_PROFILE:=base}"
if [[ -n "${HS_PROFILE:-}" && -r "$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)/config/profiles/${HS_PROFILE}/assistants.env" ]]; then
  # shellcheck disable=SC1090
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)/config/profiles/${HS_PROFILE}/assistants.env"
fi

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
die() {
  printf "[x] %s\n" "$*" >&2
  exit 1
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "+ $*"
  else
    eval "$*"
  fi
}

ONLY_SET=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      DRY_RUN=false
      shift
      ;;
    --only)
      ONLY_SET=true
      case "${2:-}" in
        codex)
          INSTALL_CODEX=true
          INSTALL_CLAUDE=false
          ;;
        claude)
          INSTALL_CODEX=false
          INSTALL_CLAUDE=true
          ;;
        *) die "Unknown assistant for --only: ${2:-}" ;;
      esac
      shift 2
      ;;
    --claude-method)
      CLAUDE_METHOD="${2:-auto}"
      shift 2
      ;;
    --claude-cask)
      CLAUDE_CASK="${2:-claude}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      warn "Ignoring unknown arg: $1"
      shift
      ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || die "This installer targets macOS."

# -- Codex --
install_codex() {
  if command -v codex > /dev/null 2>&1; then
    log "Codex already installed: $(codex --version 2> /dev/null || echo unknown)"
    return 0
  fi
  if [[ -f "$(dirname "$0")/install-codex.sh" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      run "bash setup/install-codex.sh"
    else
      bash setup/install-codex.sh --apply --method auto
    fi
  else
    warn "install-codex.sh not found; printing suggested commands."
    run "brew tap openai/codex || true"
    run "brew install codex"
  fi
}

# -- Claude --
is_claude_installed() {
  # Check common install locations for Claude Desktop app
  [[ -d "/Applications/Claude.app" ]] && return 0
  [[ -d "$HOME/Applications/Claude.app" ]] && return 0
  # Try mdfind by bundle id (best-effort)
  if command -v mdfind > /dev/null 2>&1; then
    mdfind 'kMDItemCFBundleIdentifier == "com.anthropic.claude.mac"' | grep -q "/Claude.app$" && return 0 || true
  fi
  return 1
}

install_claude() {
  if is_claude_installed; then
    log "Claude Desktop already installed"
    return 0
  fi
  local method="$CLAUDE_METHOD"
  if [[ "$method" == "auto" ]]; then
    if command -v brew > /dev/null 2>&1; then method=brew; else method=url; fi
  fi
  case "$method" in
    brew)
      if ! command -v brew > /dev/null 2>&1; then
        warn "Homebrew not available. Falling back to URL install instructions."
        method=url
      fi
      ;;
  esac
  case "$method" in
    brew)
      log "Using Homebrew cask for Claude (cask=$CLAUDE_CASK)."
      run "brew install --cask $CLAUDE_CASK"
      ;;
    url)
      log "Provide manual install link for Claude Desktop."
      cat << 'MSG'
Manual install steps (dry-run output):
  1) Download Claude Desktop for macOS from: https://www.anthropic.com/claude
  2) Open the .dmg and drag Claude.app into /Applications
  3) Launch Claude and sign in.
MSG
      ;;
    *)
      warn "Unknown claude method: $method"
      ;;
  esac
}

# Orchestration
if [[ "$INSTALL_CODEX" == true && "$ONLY_SET" == false ]]; then
  log "Selected assistants: Codex, Claude"
fi

[[ "$INSTALL_CODEX" == true ]] && install_codex || true
[[ "$INSTALL_CLAUDE" == true ]] && install_claude || true

if [[ "$DRY_RUN" == true ]]; then
  log "Dry-run complete. Re-run with --apply to perform installation."
fi

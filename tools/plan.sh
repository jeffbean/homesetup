#!/usr/bin/env bash
set -euo pipefail

# Plan: preview what `make apply` would do, using only dry-run checks.

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)"

log "Generating diff report (current vs desired)…"
bash "$REPO_ROOT/tools/diff_state.sh" > /tmp/homesetup.plan.diff.out 2>&1 || true
report_line=$(grep -Eo "Diff report written to: .*" /tmp/homesetup.plan.diff.out | tail -n1 || true)
if [[ -n "$report_line" ]]; then
  log "$report_line"
else
  warn "Could not find diff report path in output. See snapshots/diff/."
fi

echo "---"
log "Homebrew dry-run (brew bundle check)…"
if command -v brew > /dev/null 2>&1; then
  if [[ -f "$REPO_ROOT/Brewfile" ]]; then
    brew bundle check --file="$REPO_ROOT/Brewfile" || true
  else
    warn "Brewfile not found"
  fi
else
  warn "Homebrew not installed; skipping bundle check"
fi

echo "---"
log "Dotfiles stow preview (no changes)…"
if command -v stow > /dev/null 2>&1; then
  if [[ -d "$REPO_ROOT/dotfiles" ]]; then
    while IFS= read -r -d '' pkg; do
      pkgname=$(basename "$pkg")
      stow -nvt "$HOME" -d "$REPO_ROOT/dotfiles" "$pkgname" || true
    done < <(find "$REPO_ROOT/dotfiles" -mindepth 1 -maxdepth 1 -type d -print0)
  else
    warn "dotfiles/ directory not found"
  fi
else
  warn "stow not installed (brew install stow)"
fi

echo "---"
log "Assistants status (Codex / Claude)…"
if command -v codex > /dev/null 2>&1; then
  echo "codex: installed ($("codex" --version 2> /dev/null || echo unknown))"
else
  echo "codex: not installed"
fi
if [[ -d "/Applications/Claude.app" || -d "$HOME/Applications/Claude.app" ]]; then
  echo "claude: installed"
else
  echo "claude: not installed"
fi

echo "---"
log "Next steps"
cat << 'NEXT'
- Review the diff report above for package/defaults/dotfiles differences.
- Run `make apply` to apply Homebrew bundle, macOS defaults, and link dotfiles.
- Optional: `ASSISTANTS=1 make apply` to also install Codex + Claude.
- Validate with `make test`.
NEXT

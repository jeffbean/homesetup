#!/usr/bin/env bash
set -euo pipefail

# Thin wrapper to run repo checks and optionally apply formatting.
# Use FIX=1 to write changes; otherwise runs in check/diff mode.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$REPO_ROOT/tools/lib.sh"

fix="${FIX:-0}"

# Static analysis on shell scripts (no autofix)
if command -v shellcheck > /dev/null 2>&1; then
  shellcheck -x setup/*.sh tools/*.sh 2> /dev/null || true
else
  warn "shellcheck not installed (brew install shellcheck)"
fi

# shfmt
if command -v shfmt > /dev/null 2>&1; then
  if [[ "$fix" == "1" ]]; then
    shfmt -w -i 2 -ci -sr setup tools
  else
    while IFS= read -r -d '' f; do shfmt -d -i 2 -ci -sr "$f" || true; done < <(find setup tools -type f -name '*.sh' -print0)
  fi
else
  warn "shfmt not installed (brew install shfmt)"
fi

# prettier for config/docs
if command -v prettier > /dev/null 2>&1; then
  if [[ "$fix" == "1" ]]; then
    prettier -w "**/*.{yml,yaml,json,md}" || true
  else
    prettier -c "**/*.{yml,yaml,json,md}" || true
  fi
fi

# yamllint
if command -v yamllint > /dev/null 2>&1; then
  yamllint -s . || true
else
  warn "yamllint not installed (brew install yamllint)"
fi

log "check complete (FIX=${fix})"

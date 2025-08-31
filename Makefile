SHELL := /bin/bash

.PHONY: help bootstrap apply check fmt test snapshot desired diff diff-dotfiles import import-apply

help:
	@echo "Common targets:"
	@echo "  bootstrap  - Install Homebrew, brew bundle, run defaults"
	@echo "  apply      - Link dotfiles to $$HOME (via stow)"
	@echo "  check      - Run linters and static checks"
	@echo "  fmt        - Apply formatters"
	@echo "  test       - Run tests (bats)"
	@echo "  snapshot   - Capture current system state into snapshots/"
	@echo "  desired    - Generate desired state from repo into snapshots/desired/"
	@echo "  diff       - Compare snapshots/latest vs desired/latest and write report"
	@echo "  diff-dotfiles - Unified diff between dotfiles/ and $${HOME}"
	@echo "  import     - Propose updates from current system into repo"
	@echo "  import-apply - Apply updates from current system into repo"

bootstrap:
	@bash setup/bootstrap_macos.sh

apply:
	@set -euo pipefail; \
	if [ -d dotfiles ] && [ "`ls -A dotfiles 2>/dev/null | wc -l`" -gt 0 ]; then \
	  if command -v stow >/dev/null 2>&1; then \
	    stow -vt "$$HOME" dotfiles; \
	  else \
	    echo "stow not installed. Install with: brew install stow"; \
	  fi; \
	else \
	  echo "dotfiles/ is empty. Add packages (subfolders) to stow."; \
	fi

check:
	@set -e; \
	if command -v shellcheck >/dev/null 2>&1; then \
	  shellcheck -x setup/*.sh 2>/dev/null || true; \
	else echo "shellcheck not installed (brew install shellcheck)"; fi; \
	if command -v shfmt >/dev/null 2>&1; then \
	  shfmt -d -i 2 -ci -sr . || true; \
	else echo "shfmt not installed (brew install shfmt)"; fi; \
	if command -v yamllint >/dev/null 2>&1; then \
	  yamllint -s . || true; \
	else echo "yamllint not installed (brew install yamllint)"; fi

fmt:
	@set -e; \
	if command -v shfmt >/dev/null 2>&1; then \
	  shfmt -w -i 2 -ci -sr setup; \
	fi; \
	if command -v prettier >/dev/null 2>&1; then \
	  prettier -w "**/*.{yml,yaml,json,md}" || true; \
	fi

test:
	@set -e; \
	if command -v bats >/dev/null 2>&1; then \
	  bats tests; \
	else echo "bats not installed (brew install bats-core)"; fi

snapshot:
	@bash tools/snapshot_current.sh

desired:
	@bash tools/generate_desired.sh

diff: desired snapshot
	@bash tools/diff_state.sh

diff-dotfiles:
	@bash tools/diff_dotfiles.sh

import:
	@bash tools/import_current.sh

import-apply:
	@bash tools/import_current.sh --apply

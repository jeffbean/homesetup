SHELL := /bin/bash

.PHONY: help plan diff test apply init update \
        bootstrap apply-dotfiles check fmt snapshot desired diff-dotfiles import import-apply \
        prune-snapshots diff-open profile

help:
	@echo "Simple interface:"
	@echo "  plan       - Preview what apply would do (dry-run)"
	@echo "  diff       - Compute current vs desired state and report"
	@echo "  test       - Lint and run tests"
	@echo "  apply      - Apply desired state (brew bundle, defaults, dotfiles)"
	@echo "  init       - First-time setup on a new machine (everything)"
	@echo "  update     - Re-apply and update everything"
	@echo ""
	@echo "Other targets:"
	@echo "  bootstrap  - Install Homebrew, brew bundle, run defaults"
	@echo "  apply-dotfiles - Link dotfiles to $$HOME (via stow)"
	@echo "  check      - Run linters; use FIX=1 to auto-format"
	@echo "  fmt        - Apply formatters"
	@echo "  snapshot   - Capture current system state into snapshots/"
	@echo "  desired    - Generate desired state to snapshots/desired/"
	@echo "  diff-dotfiles - Unified diff between dotfiles/ and $${HOME}"
	@echo "  import     - Propose updates from current system into repo"
	@echo "  import-apply - Apply updates from current system into repo"
		@echo "  prune-snapshots        - Dry-run prune to keep last N snapshots (KEEP=N)"
		@echo "  diff-open              - Open latest diff report in default viewer"
		@echo "  profile PROFILE=<name> - Activate a profile and apply setup"
		@echo "  home-git-init          - Init bare git in HOME (dry-run; use APPLY=1 to exec)"
		@echo "  home-git-status        - Status of bare git in HOME"
 

# --- Simple interface ---

plan:
	@bash tools/plan.sh

diff: desired snapshot
	@bash tools/diff_state.sh

test:
	@$(MAKE) check
	@set -e; \
	if command -v bats >/dev/null 2>&1; then \
	  bats -r tests; \
	else echo "bats not installed (brew install bats-core)"; fi

# Apply desired state: Homebrew bundle + macOS defaults + dotfiles
apply:
	@bash tools/apply.sh

# Initial setup: everything end-to-end.
# Flags:
#   SKIP_DEV=1        Skip installing dev tools
#   SKIP_ASSISTANTS=1 Skip installing Codex/Claude
#   BACKUP_CONFLICTS=0 Do not backup conflicting files before stow
init:
	@echo "[+] Initial setup (inclusive)…"
	@bash setup/bootstrap_macos.sh --yes || true
	@# Optionally backup conflicting files before linking dotfiles
	@if [ "$$BACKUP_CONFLICTS" != "0" ]; then \
	  bash tools/prepare_apply.sh || true; \
	fi
	@$(MAKE) apply-dotfiles
	@if [ "$$SKIP_DEV" != "1" ]; then \
	  bash setup/install-dev-tools.sh --apply || true; \
	fi
	@if [ "$$SKIP_ASSISTANTS" != "1" ]; then \
	  bash setup/install-assistants.sh --apply || true; \
	fi
	@$(MAKE) snapshot
	@echo "[+] Initial setup complete."

# Update flow: re-apply everything idempotently.
# Flags mirror init: SKIP_DEV, SKIP_ASSISTANTS, BACKUP_CONFLICTS
update:
	@echo "[+] Update (inclusive)…"
	@$(MAKE) plan
	@bash setup/bootstrap_macos.sh --yes || true
	@if [ "$$BACKUP_CONFLICTS" = "1" ]; then \
	  bash tools/prepare_apply.sh || true; \
	fi
	@$(MAKE) apply-dotfiles
	@if [ "$$SKIP_DEV" != "1" ]; then \
	  bash setup/install-dev-tools.sh --apply || true; \
	fi
	@if [ "$$SKIP_ASSISTANTS" != "1" ]; then \
	  bash setup/install-assistants.sh --apply || true; \
	fi
	@$(MAKE) diff
	@$(MAKE) test
	@echo "[+] Update complete."

bootstrap:
	@bash setup/bootstrap_macos.sh


# Link dotfiles only (idempotent)
apply-dotfiles:
	@bash tools/apply_dotfiles.sh

check:
	@bash tools/check.sh

fmt:
	@set -e; \
	if command -v shfmt >/dev/null 2>&1; then \
	  shfmt -w -i 2 -ci -sr setup tools; \
	fi; \
	if command -v prettier >/dev/null 2>&1; then \
	  prettier -w "**/*.{yml,yaml,json,md}" || true; \
	fi

snapshot:
	@bash tools/snapshot_current.sh

desired:
	@bash tools/generate_desired.sh

diff-dotfiles:
	@bash tools/diff_dotfiles.sh

prune-snapshots:
	@bash tools/prune_snapshots.sh ${KEEP:+--keep ${KEEP}}

diff-open:
	@open snapshots/diff/latest/report.md || true

snapshots-clean:
	@bash tools/prune_snapshots.sh ${KEEP:+--keep ${KEEP}} --apply || true

# Activate a profile and apply the full setup
profile:
	@if [ -z "$(PROFILE)" ]; then echo "Usage: make profile PROFILE=<name>"; exit 2; fi
	@bash tools/profile.sh activate "$(PROFILE)" --apply
	@echo "[+] Profile activated: $(PROFILE)"
	@$(MAKE) apply

home-git-init:
	@bash tools/home_git.sh init ${APPLY:+--apply} ${DIR:+--dir ${DIR}}

home-git-status:
	@bash tools/home_git.sh status ${DIR:+--dir ${DIR}} || true

### Go CLI targets removed for now; design is on the roadmap

import:
	@bash tools/import_current.sh

import-apply:
	@bash tools/import_current.sh --apply

### Removed setup-* shortcuts. Call scripts directly, e.g.:
# bash setup/install-dev-tools.sh [--apply]
# bash setup/install-assistants.sh [--apply]
# bash setup/apply-hidutil.sh [--apply]
# bash tools/install_hidutil_agent.sh [--remove]
# bash setup/install-git-spice.sh [--apply]

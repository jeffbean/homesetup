SHELL := /bin/bash

.PHONY: help plan diff test apply init update \
        bootstrap apply-dotfiles check fmt snapshot desired diff-dotfiles import import-apply \
        setup-codex setup-codex-apply setup-dev-tools setup-dev-tools-apply setup-assistants setup-assistants-apply \
        setup-hidutil setup-hidutil-apply setup-hidutil-agent setup-hidutil-agent-remove \
        setup-git-spice setup-git-spice-apply prune-snapshots diff-open profile

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
	@echo "  check      - Run linters and static checks"
	@echo "  fmt        - Apply formatters"
	@echo "  snapshot   - Capture current system state into snapshots/"
	@echo "  desired    - Generate desired state to snapshots/desired/"
	@echo "  diff-dotfiles - Unified diff between dotfiles/ and $${HOME}"
	@echo "  import     - Propose updates from current system into repo"
	@echo "  import-apply - Apply updates from current system into repo"
	@echo "  setup-codex - Dry-run install steps for Codex CLI"
	@echo "  setup-codex-apply - Install Codex CLI (executes commands)"
	@echo "  setup-dev-tools - Dry-run install for linters/tests"
	@echo "  setup-dev-tools-apply - Install linters/tests (executes)"
		@echo "  setup-assistants - Dry-run install for Codex + Claude"
		@echo "  setup-assistants-apply - Install Codex + Claude (executes)"
		@echo "  setup-hidutil          - Preview applying hidutil keyboard mappings"
		@echo "  setup-hidutil-apply    - Apply hidutil keyboard mappings"
		@echo "  setup-hidutil-agent    - Install/login-load a LaunchAgent to apply hidutil"
		@echo "  setup-hidutil-agent-remove - Remove the LaunchAgent"
		@echo "  setup-git-spice        - Dry-run install for git-spice"
		@echo "  setup-git-spice-apply  - Install git-spice (executes)"
		@echo "  prune-snapshots        - Dry-run prune to keep last N snapshots (KEEP=N)"
		@echo "  diff-open              - Open latest diff report in default viewer"
		@echo "  profile PROFILE=<name> - Activate a profile and apply setup"

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
	@echo "[+] Applying desired state…"
	@bash setup/bootstrap_macos.sh
	@$(MAKE) apply-dotfiles
	@# Assistants install policy:
	@# - ASSISTANTS=1  -> apply (executes)
	@# - ASSISTANTS=0  -> skip regardless of profile
		@# - default       -> apply if profile enables; otherwise skip
		@if [ "$$ASSISTANTS" = "1" ] || [ "$$ASSISTANTS" = "true" ]; then \
		  bash setup/install-assistants.sh --apply || true; \
		elif [ "$$ASSISTANTS" = "0" ] || [ "$$ASSISTANTS" = "false" ]; then \
		  echo "[+] Skipping assistants (ASSISTANTS=$$ASSISTANTS)"; \
		else \
		  HS_PROFILE_TMP=base; \
		  [ -r "$$HOME/.config/homesetup/profile.env" ] && . "$$HOME/.config/homesetup/profile.env" || true; \
		  : "$${HS_PROFILE:=$$HS_PROFILE_TMP}"; \
		  if [ -r "config/profiles/$$HS_PROFILE/assistants.env" ]; then . "config/profiles/$$HS_PROFILE/assistants.env"; fi; \
		  WANT_APPLY=0; \
		  { [ "$$INSTALL_CODEX" = "1" ] || [ "$$INSTALL_CODEX" = "true" ]; } && WANT_APPLY=1 || true; \
		  { [ "$$INSTALL_CLAUDE" = "1" ] || [ "$$INSTALL_CLAUDE" = "true" ]; } && WANT_APPLY=1 || true; \
		  if [ "$$WANT_APPLY" = "1" ]; then \
		    echo "[+] Assistants enabled by profile '$$HS_PROFILE' → applying"; \
		    bash setup/install-assistants.sh --apply || true; \
		  else \
		    echo "[+] Assistants disabled by profile '$$HS_PROFILE' → skipping"; \
		  fi; \
		fi
	@echo "[+] Apply complete."

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
	@set -euo pipefail; \
	# Load active profile if present, default to base
	if [ -r "$$HOME/.config/homesetup/profile.env" ]; then . "$$HOME/.config/homesetup/profile.env"; fi; \
	: "$${HS_PROFILE:=base}"; \
	if [ -d dotfiles ] && [ "`ls -A dotfiles 2>/dev/null | wc -l`" -gt 0 ]; then \
	  if command -v stow >/dev/null 2>&1; then \
	    for pkg in dotfiles/*; do \
	      [ -d "$$pkg" ] || continue; \
	      echo "Stowing package: $${pkg##*/}"; \
	      stow -d dotfiles -vt "$$HOME" "$${pkg##*/}"; \
	    done; \
	    if [ -n "$$HS_PROFILE" ] && [ -d "dotfiles/overlays/$$HS_PROFILE" ]; then \
	      for pkg in dotfiles/overlays/$$HS_PROFILE/*; do \
	        [ -d "$$pkg" ] || continue; \
	        echo "Stowing overlay ($$HS_PROFILE): $${pkg##*/}"; \
	        stow -d "dotfiles/overlays/$$HS_PROFILE" -vt "$$HOME" "$${pkg##*/}"; \
	      done; \
	    fi; \
	  else \
	    echo "stow not installed. Install with: brew install stow"; \
	  fi; \
	else \
	  echo "dotfiles/ is empty. Add packages (subfolders) to stow."; \
	fi

check:
	@set -e; \
	if command -v shellcheck >/dev/null 2>&1; then \
	  shellcheck -x setup/*.sh tools/*.sh 2>/dev/null || true; \
	else echo "shellcheck not installed (brew install shellcheck)"; fi; \
	if command -v shfmt >/dev/null 2>&1; then \
	  while IFS= read -r -d '' f; do shfmt -d -i 2 -ci -sr "$${f}" || true; done < <(find setup tools -type f -name '*.sh' -print0); \
	else echo "shfmt not installed (brew install shfmt)"; fi; \
	if command -v yamllint >/dev/null 2>&1; then \
	  yamllint -s . || true; \
	else echo "yamllint not installed (brew install yamllint)"; fi

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

import:
	@bash tools/import_current.sh

import-apply:
	@bash tools/import_current.sh --apply

setup-codex:
	@bash setup/install-codex.sh

setup-codex-apply:
	@bash setup/install-codex.sh --apply --method auto

setup-dev-tools:
	@bash setup/install-dev-tools.sh

setup-dev-tools-apply:
	@bash setup/install-dev-tools.sh --apply

setup-assistants:
	@bash setup/install-assistants.sh

setup-assistants-apply:
	@bash setup/install-assistants.sh --apply

setup-hidutil:
	@bash setup/apply-hidutil.sh || true

setup-hidutil-apply:
	@bash setup/apply-hidutil.sh --apply || true

setup-hidutil-agent:
	@bash tools/install_hidutil_agent.sh || true

setup-hidutil-agent-remove:
	@bash tools/install_hidutil_agent.sh --remove || true

setup-git-spice:
	@bash setup/install-git-spice.sh || true

setup-git-spice-apply:
	@bash setup/install-git-spice.sh --apply || true

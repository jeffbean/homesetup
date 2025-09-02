SHELL := /bin/bash

.PHONY: help brew apply-dotfiles plan apply

help:
	@echo "Simple commands:"
	@echo "  plan            - Dry-run: brew bundle check + stow preview"
	@echo "  brew            - Install packages from config/Brewfile (or HS_BREWFILE)"
	@echo "  apply-dotfiles  - Stow dotfiles/* packages into \"$$HOME\""
	@echo "  apply           - Stow dotfiles and reload tmux + zsh"

brew:
	@if command -v brew >/dev/null 2>&1; then \
	  FILE=$${HS_BREWFILE:-config/Brewfile}; \
	  if [ -f "$$FILE" ]; then brew bundle --file="$$FILE"; else echo "Brewfile not found: $$FILE"; fi; \
	else echo "Homebrew not installed"; fi

apply-dotfiles:
	@if command -v stow >/dev/null 2>&1; then \
	  if [ -d dotfiles ]; then \
	    for pkg in dotfiles/*; do [ -d "$$pkg" ] || continue; echo "Stowing: $${pkg##*/}"; stow --no-folding -d dotfiles -vt "$$HOME" "$${pkg##*/}"; done; \
	  else echo "dotfiles directory not found"; fi; \
	else echo "stow not installed (brew install stow)"; fi

apply: apply-dotfiles
	@# Reload tmux config if inside tmux
	@if command -v tmux >/dev/null 2>&1; then \
	  if [ -n "$$TMUX" ]; then tmux source-file "$$HOME/.tmux.conf" || true; fi; \
	else :; fi
	@# Ask current tmux pane to exec a fresh login zsh, otherwise print a hint
	@if command -v tmux >/dev/null 2>&1 && [ -n "$$TMUX_PANE" ]; then \
	  ( sleep 0.1; tmux send-keys -t "$$TMUX_PANE" "exec zsh -l" Enter ) >/dev/null 2>&1 || true; \
	  echo "[+] Reloaded tmux and scheduled zsh reload in current pane."; \
	else \
	  echo "[+] Not in tmux; run 'exec zsh -l' to reload your shell."; \
	fi

plan:
	@echo "[+] Homebrew dry-run (bundle check)"
	@if command -v brew >/dev/null 2>&1; then \
	  FILE=$${HS_BREWFILE:-config/Brewfile}; \
	  if [ -f "$$FILE" ]; then brew bundle check --file="$$FILE" || true; else echo "Brewfile not found: $$FILE"; fi; \
	else echo "Homebrew not installed"; fi

	@echo "---"
	@echo "[+] Dotfiles stow preview (no changes)"
	@if command -v stow >/dev/null 2>&1; then \
	  if [ -d dotfiles ]; then \
	    for pkg in dotfiles/*; do \
	      [ -d "$$pkg" ] || continue; pkgname=$${pkg##*/}; echo "Preview: $$pkgname"; \
	      stow -nvt "$$HOME" -d dotfiles "$$pkgname" || true; \
	    done; \
	  else echo "dotfiles directory not found"; fi; \
	else echo "stow not installed (brew install stow)"; fi

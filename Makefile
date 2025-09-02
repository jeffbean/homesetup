SHELL := /bin/bash

.PHONY: help brew apply-dotfiles plan apply build

help:
	@echo "Simple commands:"
	@echo "  plan            - Dry-run: brew bundle check + stow preview"
	@echo "  brew            - Install packages from config/Brewfile (or HS_BREWFILE)"
	@echo "  apply-dotfiles  - Stow dotfiles/* packages into \"$$HOME\""
	@echo "  apply           - Stow dotfiles and reload tmux + zsh"
	@echo "  build           - Build Go CLI to ./bin/homesetup"

brew:
	@if [ -x bin/homesetup ]; then bin/homesetup brew; \
	elif command -v go >/dev/null 2>&1; then go run ./cmd/homesetup brew; \
	else echo "Build CLI with 'make build' or install Go."; fi

apply-dotfiles:
	@if [ -x bin/homesetup ]; then bin/homesetup apply-dotfiles; \
	elif command -v go >/dev/null 2>&1; then go run ./cmd/homesetup apply-dotfiles; \
	else echo "Build CLI with 'make build' or install Go."; fi

apply:
	@if [ -x bin/homesetup ]; then bin/homesetup apply; \
	elif command -v go >/dev/null 2>&1; then go run ./cmd/homesetup apply; \
	else echo "Build CLI with 'make build' or install Go."; fi

plan:
	@if [ -x bin/homesetup ]; then bin/homesetup plan; \
	elif command -v go >/dev/null 2>&1; then go run ./cmd/homesetup plan; \
	else echo "Build CLI with 'make build' or install Go."; fi

build:
	@mkdir -p bin
	@if command -v go >/dev/null 2>&1; then \
	  go build -o bin/homesetup ./cmd/homesetup; \
	  echo "[+] Built ./bin/homesetup"; \
	else echo "Go not installed"; fi

SHELL := /bin/bash

.PHONY: help brew apply-dotfiles plan apply build lint fmt lint fmt

help:
	@echo "Simple commands:"
	@echo "  plan            - Dry-run: brew bundle check + stow preview"
	@echo "  brew            - Install packages from config/Brewfile (or HS_BREWFILE)"
	@echo "  apply-dotfiles  - Stow dotfiles/* packages into \"$$HOME\""
	@echo "  apply           - Stow dotfiles and reload tmux + zsh"
	@echo "  build           - Build Go CLI to ./bin/homesetup"
	@echo "  lint            - go vet + gofmt check + go test"
	@echo "  fmt             - go fmt ./..."

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

lint:
	@set -e; \
	if command -v go >/dev/null 2>&1; then \
	  echo "[+] go vet"; go vet ./...; \
	  echo "[+] gofmt check"; FMT=$$(gofmt -l . | grep -E '\\.go$$' || true); \
	  if [ -n "$$FMT" ]; then echo "gofmt issues:"; echo "$$FMT"; exit 1; fi; \
	  echo "[+] go test"; go test ./...; \
	else echo "Go not installed"; exit 1; fi

fmt:
	@if command -v go >/dev/null 2>&1; then go fmt ./...; else echo "Go not installed"; fi


devpod-shell:
	@if [ -x bin/homesetup ]; then bin/homesetup devpod shell; \
	elif command -v go >/dev/null 2>&1; then go run ./cmd/homesetup devpod shell; \
	else echo "Build CLI with 'make build' or install Go."; fi

devpod-down:
	@if [ -x bin/homesetup ]; then bin/homesetup devpod down; \
	elif command -v go >/dev/null 2>&1; then go run ./cmd/homesetup devpod down; \
	else echo "Build CLI with 'make build' or install Go."; fi

# macOS Home Setup (Idempotent)

This repo provisions and maintains a healthy macOS setup for a personal machine. It’s idempotent and safe to re‑run.

Built with a mix of pragmatic shell and as much AI assistance as is sane — all changes remain small, testable, and reversible.

## Quick Start

- Clone the repo and review `config/Brewfile`.
- Install packages: `make brew`
- Link dotfiles: `make apply-dotfiles`

## Profiles
Profiles and overlays were removed to simplify the core plan/diff engine. We may reintroduce them later.

## What it does

- Homebrew: installs via `brew bundle` (from `config/Brewfile`)
- Dotfiles: stows `dotfiles/*` into your home directory

## Commands

- `make brew` — install packages from `config/Brewfile`
- `make apply-dotfiles` — link dotfiles with stow (idempotent)
- `make apply` — stow + reload tmux (run `exec zsh -l` to reload your shell)

### Optional Go CLI

You can use the tiny Go CLI instead of Make targets:

- `go run ./cmd/homesetup plan` — brew bundle check + stow preview (dry-run)
- `go run ./cmd/homesetup brew` — install packages from `config/Brewfile`
- `go run ./cmd/homesetup apply-dotfiles` — stow dotfiles
- `go run ./cmd/homesetup apply` — stow + reload tmux

## Repository Layout

- `config/` — Inputs to the setup (no secrets)
  - `Brewfile`: Homebrew formulae/casks and MAS apps (source of truth)
- `*.example` configs for tools (ssh, gpg-agent, starship, hidutil, etc.)
- `dotfiles/` — Dotfile packages to be stowed into `$HOME`
- `setup/`, `tools/`, `tests/` — removed to simplify; focus on `config/` + `dotfiles/`
- `docs/` — notes and procedures

Top level stays minimal: a Makefile that delegates to `tools/` and eventually the Go CLI.

## Design Principles (Expandable)

- Inputs live under `config/` so we can evolve the engine without moving data.
- Scripts are idempotent and safe; destructive actions require explicit flags.
- Environment knobs (optional):
  - `HS_BREWFILE`: override path to Brewfile (else `config/Brewfile`)
- Makefile remains a thin entrypoint; the Go CLI will absorb orchestration over time while keeping the same UX (`plan`, `diff`, `apply`).

## Optional: mise (tool/runtime manager)

- If desired, manage tools with mise.
- Use `config/examples/mise.toml` as a starting point for tools like `go`, `golangci-lint`, `goreleaser`, `buf`, `protoc`.
- For per‑project setup, add `.envrc` from `config/examples/envrc.mise` and `direnv allow`.

## Dotfiles & Secrets

- Shared git config: `dotfiles/base/.gitconfig` (aliases, shared settings)
- Personal overrides: `~/.gitconfig.local` (see `config/examples/gitconfig.local`)
- Local overrides: files ending in `*.local` (e.g., `~/.zshrc.local`) are never linked or tracked. They’re user-specific. We ship a Stow ignore (`dotfiles/.stow-global-ignore`) and skip them in diff/desired tools.
- Never commit secrets. 1Password and 1Password CLI are installed via Brewfile; use them for secrets in automation.

## Contributing

- Keep changes small and idempotent. Prefer declarative lists and tests.
- Use Conventional Commits and update `docs/TODO.md` as you go.

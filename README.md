# macOS Home Setup (Idempotent)

This repo provisions and maintains a healthy macOS setup for a personal machine. It’s idempotent and safe to re‑run.

AI Experiment
- This repo is essentially fully coded with Codex as my next AI experiment. I use Codex for everything in this repo as an experiment.

## Quick Start

- Clone the repo and review `config/Brewfile`.
- Install packages: `make brew`
- Link dotfiles and reload tmux/zsh: `make apply`


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

- `config/`
  - `Brewfile`: Homebrew formulae/casks and MAS apps
  - `examples/`: example configs (ssh, gpg-agent, starship, etc.)
- `dotfiles/`: stow packages (e.g., `base`, `zsh`)
- `cmd/homesetup`: Go CLI entrypoint
- `internal/actions`: Go actions (plan/apply/brew)
- `bin/`: optional build output (`make build`)
- `.github/workflows/ci.yml`: Go build + lint CI

Top level stays minimal: a Makefile that delegates to the Go CLI.

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
- Local overrides: files ending in `*.local` (e.g., `~/.zshrc.local`) are user-specific. We ship a Stow ignore (`dotfiles/.stow-global-ignore`).
- Never commit secrets. 1Password and 1Password CLI are installed via Brewfile; use them for secrets in automation.

## Contributing

- Keep changes small and idempotent. Prefer declarative lists and tests.
- Use Conventional Commits and update `docs/TODO.md` as you go.

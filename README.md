# macOS Home Setup (Idempotent)

This repo provisions and maintains a healthy macOS setup for a personal machine. It’s idempotent and safe to re‑run.

Built with a mix of pragmatic shell and as much AI assistance as is sane — all changes remain small, testable, and reversible.

## Quick Start

- Clone the repo and review `config/Brewfile` and `setup/defaults.sh`.
- Profiles are currently disabled to simplify core mechanics.
- Preview & diff:
  - `make plan` (dry‑run checks)
  - `make diff` and `make diff-open`

## Profiles
Profiles and overlays were removed to simplify the core plan/diff engine. We may reintroduce them later.

## What it does

- Homebrew: installs via `brew bundle`
- Defaults: applies macOS defaults
- Dotfiles: stows `dotfiles/*`
- Assistants: profile‑aware toggles (auto‑applies in profiles that enable it; override with `ASSISTANTS=0/1`)
- Optional mise: multi‑language/tool manager that can pin Go/tooling and other CLIs, enabled by default in the `wip` profile

## Commands

- `make plan` — dry‑run checks (bundle check, stow preview)
- `make apply` — apply brew bundle, defaults, dotfiles
- `make diff` / `make diff-open` — snapshot + report
- `make prune-snapshots KEEP=N` — preview prune; `make snapshots-clean KEEP=N` to apply
- `make check` / `make test` — lint and tests (`FIX=1` to auto‑format)

## Repository Layout

- `config/` — Inputs to the setup (no secrets)
  - `Brewfile`: Homebrew formulae/casks and MAS apps (source of truth)
- `*.example` configs for tools (ssh, gpg-agent, starship, hidutil, etc.)
- `dotfiles/` — Dotfile packages to be stowed into `$HOME`
- `setup/` — macOS bootstrap scripts (temporary until Go CLI replaces)
- `tools/` — thin orchestration + shared `lib.sh` helpers (entrypoint scripts)
- Go CLI: planned future work to replace shell orchestration while keeping inputs under `config/`.
- `tests/` — bats tests for scripts and defaults
- `snapshots/` — artifacts: current/desired state and diffs
- `docs/` — notes and procedures

Top level stays minimal: a Makefile that delegates to `tools/` and eventually the Go CLI.

## Design Principles (Expandable)

- Inputs live under `config/` so we can evolve the engine without moving data.
- Scripts are idempotent and safe; destructive actions require explicit flags.
- `tools/lib.sh` centralizes logging, DRY‑RUN, and path resolution.
- Environment knobs:
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

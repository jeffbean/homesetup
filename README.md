# macOS Home Setup (Profile‑Aware, Idempotent)

This repo provisions and maintains a healthy macOS setup for a personal machine. It’s profile‑aware (swap personas in one command), idempotent, and safe to re‑run.

Built with a mix of pragmatic shell and as much AI assistance as is sane — all changes remain small, testable, and reversible.

## Quick Start

- Clone the repo and review `config/Brewfile` and `setup/defaults.sh`.
- Base is the default profile (Starship, assistants off).
- Pick a profile and apply:
  - `make profile PROFILE=base` (Starship prompt, assistants disabled)
  - `make profile PROFILE=wip` (Starship prompt, assistants enabled + extras)
- Preview & diff:
  - `make plan` (dry‑run checks)
  - `make diff` and `make diff-open`

## Profiles

Profiles live under `config/profiles/<name>/`:
- `profile.env`: `HS_PROFILE`, `SHELL_STACK` (omz|starship), `PROMPT_FLAVOR`
- `Brewfile.extra`: merged with base Brewfile (`config/Brewfile`) during apply/desired
- `assistants.env`: toggles for assistants install

Optional per‑profile layers:
- `setup/defaults.d/<name>.sh`: profile macOS defaults
- `dotfiles/overlays/<name>/*`: overlay packages, stowed on top of base

Switch in one command:
- `make profile PROFILE=<name>`
- or `bash tools/switch_profile.sh <name>` (`--no-apply` to only activate)

## What it does

- Homebrew: installs via `brew bundle` (composed per profile)
- Defaults: applies macOS defaults (base + `defaults.d/<profile>.sh`)
- Dotfiles: stows `dotfiles/*` then overlays `dotfiles/overlays/<profile>/*`
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
  - `profiles/<name>/`: `profile.env`, `Brewfile.extra`, optional `assistants.env`
  - `*.example` configs for tools (ssh, gpg-agent, starship, hidutil, etc.)
- `dotfiles/` — Dotfile packages to be stowed into `$HOME`
  - `overlays/<profile>/` for profile‑specific files layered on top
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
- `tools/lib.sh` centralizes logging, DRY‑RUN, profile loading, and path resolution.
- Environment knobs:
  - `HS_PROFILE`: active profile (defaults to `base`)
  - `HS_BREWFILE`: override path to Brewfile (else `config/Brewfile`)
- Makefile remains a thin entrypoint; the Go CLI will absorb orchestration over time while keeping the same UX (`plan`, `diff`, `apply`).

## Optional: mise (tool/runtime manager)

- WIP profile includes `mise` in its Brewfile extras and loads it in shell.
- Use `config/mise.example.toml` as a starting point for tools like `go`, `golangci-lint`, `goreleaser`, `buf`, `protoc`.
- For per‑project setup, add `.envrc` from `config/envrc.mise.example` and `direnv allow`.

## Dotfiles & Secrets

- Shared git config: `dotfiles/base/.gitconfig` (aliases, shared settings)
- Personal overrides: `~/.gitconfig.local` (see `config/gitconfig.local.example`)
- Never commit secrets. 1Password and 1Password CLI are installed via Brewfile; use them for secrets in automation.

## Contributing

- Keep changes small and idempotent. Prefer declarative lists and tests.
- Use Conventional Commits and update `docs/TODO.md` as you go.

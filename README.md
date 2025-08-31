# macOS Home Setup (Profile‑Aware, Idempotent)

This repo provisions and maintains a healthy macOS setup for a personal machine. It’s profile‑aware (swap personas in one command), idempotent, and safe to re‑run.

Built with a mix of pragmatic shell and as much AI assistance as is sane — all changes remain small, testable, and reversible.

## Quick Start

- Clone the repo and review the `Brewfile` and `setup/defaults.sh`.
- Pick a profile and apply:
  - `make profile PROFILE=dev` (Starship prompt, assistants enabled)
  - `make profile PROFILE=minimal` (Oh My Zsh, assistants disabled)
- Preview & diff:
  - `make plan` (dry‑run checks)
  - `make diff` and `make diff-open`

## Profiles

Profiles live under `config/profiles/<name>/`:
- `profile.env`: `HS_PROFILE`, `SHELL_STACK` (omz|starship), `PROMPT_FLAVOR`
- `Brewfile.extra`: merged with base Brewfile during apply/desired
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
- Assistants: profile‑aware toggles (dry‑run by default; set `ASSISTANTS=1` to install during `make apply`)

## Commands

- `make plan` — dry‑run checks (bundle check, stow preview)
- `make apply` — apply brew bundle, defaults, dotfiles
- `make diff` / `make diff-open` — snapshot + report
- `make prune-snapshots KEEP=N` — preview prune; `make snapshots-clean KEEP=N` to apply
- `make check` / `make test` — lint and tests

## Dotfiles & Secrets

- Shared git config: `dotfiles/base/.gitconfig` (aliases, shared settings)
- Personal overrides: `~/.gitconfig.local` (see `config/gitconfig.local.example`)
- Never commit secrets. 1Password and 1Password CLI are installed via Brewfile; use them for secrets in automation.

## Contributing

- Keep changes small and idempotent. Prefer declarative lists and tests.
- Use Conventional Commits and update `docs/TODO.md` as you go.


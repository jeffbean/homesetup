# Repository Guidelines

This repo provisions and maintains a healthy macOS setup for a personal machine. Keep changes small, repeatable, and safe to re-run.

## Project Structure & Module Organization

- `setup/`: macOS bootstrap logic (e.g., `bootstrap_macos.sh`, `defaults.sh`).
- `Brewfile`: Homebrew and App Store apps (via `mas`).
- `dotfiles/`: files to be linked into `$HOME` (use stow/chezmoi).
- `config/`: tool configs (YAML/JSON/TOML); include `example.*` templates.
- `tests/`: BATS or shell tests for scripts and defaults.
- `docs/`: notes on decisions and recovery steps.

Example:

```
setup/
dotfiles/
config/
tests/
Brewfile
```

## Build, Test, and Development Commands

Run from repo root:

- `make bootstrap` or `bash setup/bootstrap_macos.sh`: install Homebrew, `brew bundle`, apply defaults.
- `brew bundle --file=Brewfile`: install/update formulae and casks.
- `make apply` or `stow -vt "$HOME" dotfiles`: link dotfiles idempotently.
- `make check`: run `shellcheck`, `shfmt`, `yamllint`.
- `make test` or `bats tests`: execute test suite.

## Coding Style & Naming Conventions

- Shell: `bash -euo pipefail`; functions over inline one-liners; no inline `sudo`.
- Indentation: YAML 2 spaces; shell 2 spaces; no tabs.
- Naming: scripts `kebab-case` (e.g., `install-tools`); folders `snake_case` if needed; constants `UPPER_SNAKE`.
- Formatting/Linting: `shfmt`, `shellcheck`, `prettier` (YAML/JSON). Keep macOS defaults declarative in lists.

## Testing Guidelines

- Mirror names: `setup/defaults.sh` -> `tests/defaults.bats`.
- Prefer dry-runs: `brew bundle check`, `stow -nvt "$HOME" dotfiles`, `defaults read` to verify.
- Use temp dirs and a non-admin test user when possible; avoid mutating global state in tests.

## Commit & Pull Request Guidelines

- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`).
- Subject ≤72 chars; body explains why and rollback steps.
- One logical change per PR; include `defaults` before/after output or screenshots for UI changes.

## Security & Configuration Tips

- Never commit secrets; prefer macOS Keychain or 1Password CLI. Use `*.local` overrides ignored by Git.
- Pin versions and verify checksums for remote installers; avoid `curl | sh`.
- Scripts must be idempotent and re-runnable; guard destructive actions behind flags and prompts.

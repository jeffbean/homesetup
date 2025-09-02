# Repository Guidelines

## Project Structure & Module Organization
- `config/`: Inputs (e.g., `Brewfile`, `examples/`).
- `dotfiles/`: Stow packages (e.g., `base`, `zsh`). Linked to `$HOME` via `stow`.
- `cmd/homesetup/`: Go CLI entrypoint.
- `internal/actions/`: Go modules for `plan`, `apply`, and `brew`.
- `bin/`: Optional build output (`bin/homesetup`).
- `.github/workflows/ci.yml`: Build/lint/test CI.

## Build, Test, and Development Commands
- `make build`: Build CLI to `./bin/homesetup`.
- `make plan`: Dry‑run (Homebrew bundle check + stow preview).
- `make brew`: Install packages from `config/Brewfile` (or `HS_BREWFILE`).
- `make apply-dotfiles`: Stow all packages in `dotfiles/`.
- `make apply`: Stow + `tmux source-file ~/.tmux.conf` + OMZ reload.
- `make lint`: `go vet`, format check (`gofmt`), and `go test`.
- `make fmt`: Format Go code (`go fmt ./...`).

Examples:
- `HS_BREWFILE=config/profiles/work/Brewfile make brew`
- `go run ./cmd/homesetup plan`

## Coding Style & Naming Conventions
- Go 1.22; use `gofmt`, `go vet`, and CI.
- Package layout: `cmd/<app>`, `internal/<domain>`.
- Logging: `slog` (text). Log errors you intentionally ignore.
- Shell content lives only under `dotfiles/`; stow manages linking.

## Testing Guidelines
- Framework: standard `go test`.
- Location: `*_test.go` alongside packages (e.g., `internal/actions/actions_test.go`).
- Run: `make lint` or `go test ./...`.
- Keep tests hermetic (use `t.TempDir()`, `t.Setenv()`), no network.

## Commit & Pull Request Guidelines
- Use Conventional Commits (e.g., `feat:`, `fix:`, `chore:`).
- Commits should be focused and descriptive; include rationale when not obvious.
- PRs: clear summary, what changed, how to verify (commands), and any screenshots/logs when UI/UX/dev‑ex changes.

## Security & Configuration Tips
- Do not commit secrets. Prefer `.local` files in `$HOME` and `config/examples/` for templates.
- Use `HS_BREWFILE` to point `make brew` at a custom Brewfile.
- Local overrides like `~/.zshrc.local` are user‑specific and not tracked.

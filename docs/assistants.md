Assistants Installer

Overview
- The `setup/install-assistants.sh` script installs multiple coding assistants with safe defaults.
- It is idempotent and runs in dry-run mode unless `--apply` is provided.

Included Assistants
- Codex CLI
- Claude Desktop (via Homebrew cask or manual URL instructions)

Usage
- Dry-run both: `bash setup/install-assistants.sh`
- Install both: `bash setup/install-assistants.sh --apply`
- Only Codex: `bash setup/install-assistants.sh --only codex --apply`
- Only Claude: `bash setup/install-assistants.sh --only claude --apply`
- Force Claude method: `bash setup/install-assistants.sh --apply --claude-method brew`

Notes
- The script leverages `setup/install-codex.sh` for Codex CLI.
- Claude install defaults to Homebrew cask `claude` when available; otherwise prints manual install steps and link.
- No inline sudo; re-runnable; avoids changing unrelated system state.

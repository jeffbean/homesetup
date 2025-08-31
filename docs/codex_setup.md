Codex CLI Setup

Overview
- Codex CLI is an open-source, terminal-based coding assistant. This repo includes a helper script to install it safely.
- The script defaults to a non-destructive dry-run. Use --apply to execute the printed commands.

Quick Start
- Dry-run: `bash setup/install-codex.sh`
- Install with Homebrew: `bash setup/install-codex.sh --apply --method brew`
- Install with npm: `bash setup/install-codex.sh --apply --method npm`

Package Names
- Confirm the exact package names/taps before applying:
  - Homebrew: ensure a tap/formula exists that provides `codex` (e.g., `openai/codex/codex`).
  - npm: ensure the package provides the `codex` binary (e.g., `@openai/codex-cli`).

Verification
- `codex --version`
- `codex --help`

Uninstall
- Homebrew: `brew uninstall codex`
- npm: `npm uninstall -g @openai/codex-cli`

Notes
- The script avoids inline sudo and is idempotent.
- Prefer Homebrew for system-wide install; npm works if you already manage Node globally.

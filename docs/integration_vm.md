# macOS VM Integration Test (Manual First Pass)

Goal: validate `make plan/apply/test/diff` end-to-end on a clean macOS VM. Start manual; automate later.

## Options
- Apple Silicon + Virtualization.framework (preferred, native, fast)
- UTM (UI wrapper over QEMU; simpler to start)
- Anka/Orka (commercial; skip for personal use)

## Prereqs (host)
- Apple Silicon Mac recommended
- macOS installer app present (e.g., “Install macOS Sequoia.app”)
- Xcode Command Line Tools installed on host

## Create VM (two paths)

1) Virtualization.framework (native)
- Use Apple’s sample or a lightweight CLI (e.g., `vz`-based tools) to create a macOS VM from the installer app.
- Allocate: 4–8 GB RAM, 4 vCPU, 40–80 GB disk.
- Enable Rosetta for x86 Homebrew bottles if desired.

2) UTM (simpler UI)
- Download UTM, create a new macOS VM, point at the installer image.
- Same resource sizing as above.

## Inside the VM (fresh macOS)
1. Open Terminal
2. Install Xcode CLTs: `xcode-select --install` (confirm install)
3. Install Homebrew (from brew.sh)
4. Clone this repo: `git clone <your-fork-url> ~/homesetup && cd ~/homesetup`
5. Run checks first:
   - `make check` (lint)
   - `make test` (skip-aware tests)
6. Dry-run plan:
   - `make plan` (bundle check + stow preview)
7. Apply setup (idempotent):
   - `make apply`
8. Snapshot + diff report:
   - `make diff` then `make diff-open`

## What to Verify
- `brew bundle` succeeds; re-running is a no-op
- macOS defaults applied; rerun `defaults.sh --dry-run` shows no surprises
- Dotfiles stowed correctly
- zsh starts clean; OMZ plugin loads without errors
- `tmux` present and config loads

## Next: Automate
- Script VM bring-up using `vz` (Virtualization.framework) with a prepared IPSW/installer
- Run `make init` then `make update` to verify idempotence
- Export artifacts (logs + `snapshots/diff/*/report.md`)

Keep this minimal and reproducible; prefer native APIs over brittle GUI automation.

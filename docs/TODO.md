# Personal macOS Setup – Running TODO List

This is a living roadmap for refining and maintaining the local setup. Keep items small, idempotent, and testable. Use Conventional Commits when closing items.

## Recently Done
- [x] Diff report in Markdown (snapshots/diff/<ts>/report.md)
- [x] Diff excludes indirect Homebrew deps (via `brew deps --union`)
- [x] Robust Brewfile parsing (POSIX classes)
- [x] Keyboard defaults (repeat, press-and-hold, F-keys, UI mode)
- [x] `hidutil` apply script + LaunchAgent template
- [x] OMZ custom plugin `bean` with `scripts/` + `functions/`
- [x] `gsnb` function (prefers git-spice, fallback to git)
- [x] git-spice integration (tap + brew + installer)
- [x] Tests: diff/plan/hidutil/git-spice + generate_desired + bootstrap smoke
- [x] Profiles: `tools/profile.sh` + one-command `make profile PROFILE=<name>`
- [x] Profile-aware setup: Brewfile composition, defaults.d layering, dotfiles overlays, assistants toggles
- [x] Terminal stacks: OMZ ↔ Starship via profile (`SHELL_STACK`, `PROMPT_FLAVOR`)
- [x] Starship support + example config
- [x] Prune snapshots tool + test; `make diff-open`
- [x] Generalize repo: remove personal gitconfig, add `gitconfig.local` example

---

## System Defaults
- [x] Finder: show status bar, path bar, all filename extensions
- [x] Finder: new windows target `$HOME`
- [x] Dock: size/magnify, autohide, remove recents
- [x] Trackpad/Mouse: tap-to-click, three‑finger drag, natural scrolling
- [x] Screenshots: set default dir to `~/Pictures/Screenshots`
- [ ] Safari/Privacy: disable auto-open safe downloads, tracking prevention, show full URL
- [ ] Sleep/Password: require password after sleep/wake
- [x] Tests: read‑only/presence checks in `tests/defaults/`

## Homebrew: Apps, Fonts, CLIs
- [x] Developer CLIs: `fzf`, `ripgrep`, `fd`, `eza`, `bat`, `tree`, `gnu-sed`, `gnu-tar`
- [ ] Terminal + Fonts: `iterm2` (or `alacritty`), `font-jetbrains-mono-nerd-font`
- [ ] Utilities: `AltTab`, `Raycast`/`Alfred` (pick one)
- [x] 1Password + CLI (for secrets and automation)
- [ ] MAS entries for required Apple apps (ids pinned in Brewfile)
- [ ] Example configs under `config/` for selected tools (iTerm2/Alacritty)
  - [x] Starship example config
- [ ] Tests: `brew bundle check` dry-run gate in `tests/homebrew.bats`

## Shell & Dotfiles
- [ ] Expand OMZ `bean` plugin modules:
  - [ ] `scripts/git.zsh`: git aliases/wrappers (lean on `git-spice` where useful)
  - [x] `scripts/direnv.zsh`: hook only if present
  - [x] `scripts/fzf.zsh`: keybindings if installed
- [x] Optional: starship prompt support (`config/starship.example.toml`)
- [ ] Tests: `zsh` plugin loads without errors (smoke via `zsh -ic true` if available)

### Dotfiles VCS (bare git under $HOME)
- [ ] Evaluate bare repo path (e.g., `~/.homesetup.git`) with work-tree=`$HOME`
- [ ] Keep `stow` workflow for modularity; define ignores to avoid repo noise
- [ ] Wrapper script (`tools/home_git.sh`) to init/status/config (dry-run by default)
- [ ] Safety: backup conflicting files; migration plan from current stow layout
- [ ] Tests: wrapper runs dry-run; no mutation without `--apply`

## Languages/Toolchains
- [ ] Add `mise` (rtx) or `asdf` to Brewfile (pick one)
- [ ] `config/mise.example.toml` with pinned versions (node, python, etc.)
- [ ] Tests: presence + `mise --version` skip‑aware

## SSH / GPG (templates only; no secrets)
- [x] `config/ssh/config.example`
- [x] `config/gpg-agent.conf.example` and `pinentry-mac` in Brewfile
- [ ] Docs: short note on generating keys + Keychain integration
- [ ] Tests: file existence only

## Security & Updates (documented, not enforced)
- [ ] Firewall enabled (doc only)
- [ ] Software updates command + cadence (doc only)
- [ ] VPN/ZT: `tailscale` cask + `config/tailscale.example.sh`

## Diff / Snapshots / Tooling
- [ ] Treat formula pulled in by casks as allowed deps in extras
- [ ] Optional flag to include dependency closure details in report (for debugging)
- [x] `tools/prune_snapshots.sh` to keep last N snapshots
- [x] Make target: `diff-open`
- [ ] Make target: `snapshots-clean N`
- [x] Tests: prune dry‑run

## Roadmap (Bigger Items)
- [ ] Migrate shell tooling to Go (CLI for plan/diff/apply)
  - [ ] Define module structure (cmd/..., pkg/...)
  - [ ] Reimplement `generate_desired`, `diff_state`, `snapshot_current`
  - [ ] Keep shell as thin wrappers during transition
- [ ] macOS VM integration tests
  - [ ] Script/automation to bring up a macOS VM (e.g., Anka, UTM, or Apple Silicon virtualize if feasible)
  - [ ] Run `make init` and verify idempotence (`make update`)
  - [ ] Collect artifacts (logs, diff report, timing)

## Docs
- [ ] `docs/recovery.md`: lost laptop → reinstall + restore flow
- [ ] `docs/decisions.md`: notes on choices (hidutil vs Karabiner, OMZ vs Starship, mise vs asdf)
- [ ] `docs/first-boot.md`: privacy permissions (Terminal Full Disk Access), enabling services

---

## Conventions
- Idempotent shell with `bash -euo pipefail`; no inline sudo
- Keep macOS defaults declarative and testable (read checks)
- Prefer taps/versions pinned where feasible
- Use `.example` files for templates; keep secrets out of git

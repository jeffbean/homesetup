# Personal macOS Setup — TODO

Keep items small, idempotent, and testable. Prefer inputs under `config/` and thin entrypoints. This list is trimmed to only upcoming work.

## System Defaults
- [x] Finder: show status bar, path bar, all filename extensions
- [x] Finder: new windows target `$HOME`
- [x] Dock: size/magnify, autohide, remove recents
- [x] Trackpad/Mouse: tap-to-click, three‑finger drag, natural scrolling
- [x] Screenshots: set default dir to `~/Pictures/Screenshots`
- [ ] Safari/Privacy: disable auto-open safe downloads, tracking prevention, show full URL (de-scoped for now)
- [ ] Sleep/Password: require password after sleep/wake (de-scoped for now)
- [x] Tests: read‑only/presence checks in `tests/defaults/`

## Homebrew: Apps, Fonts, CLIs
- [x] Developer CLIs: `fzf`, `ripgrep`, `fd`, `eza`, `bat`, `tree`, `gnu-sed`, `gnu-tar`
- [x] Fonts: `font-jetbrains-mono-nerd-font`
- [ ] Terminal emulator: none (using built-in Terminal); focus on `tmux` workflow
- [ ] Utilities: `AltTab`, `Raycast`/`Alfred` (pick one)
- [x] 1Password + CLI (for secrets and automation)
- [ ] MAS entries for required Apple apps (ids pinned in config/Brewfile)
- [ ] Example configs under `config/` for selected tools (iTerm2/Alacritty)
- [ ] Tests: `brew bundle check` dry-run gate (already present; expand cases)

## Shell & Dotfiles
- [ ] Expand OMZ `bean` plugin modules:
  - [ ] `scripts/git.zsh`: git aliases/wrappers (lean on `git-spice` where useful)
  - [x] `scripts/direnv.zsh`: hook only if present
  - [x] `scripts/fzf.zsh`: keybindings if installed
- [x] Optional: starship prompt support (`config/examples/starship.toml`)
- [ ] Tests: `zsh` plugin loads without errors (smoke via `zsh -ic true` if available)

### Dotfiles Management
- [x] Prefer `stow` for modularity; define ignores to avoid repo noise
- [ ] Safety: backup conflicting files; migration plan from current stow layout

## Languages/Toolchains
- [ ] Evaluate `mise` (rtx) baseline (example config + optional profile enable)
- [ ] Tests: presence + `mise --version` (skip‑aware)

## SSH / GPG (templates only; no secrets)
- [ ] Docs: short note on generating keys + Keychain integration
- [ ] Tests: file existence only (already present)

## Security & Updates (documented, not enforced)
- [ ] Firewall enabled (doc only)
- [ ] Software updates command + cadence (doc only)
- [ ] VPN/ZT: `tailscale` cask + `config/examples/tailscale.sh`

## Diff / Snapshots / Tooling
- [ ] Treat formula pulled in by casks as allowed deps in extras
- [ ] Optional flag to include dependency closure details in report (for debugging)
- [x] `tools/prune_snapshots.sh` to keep last N snapshots
- [x] Make target: `diff-open`
- [ ] Make target: `snapshots-clean N` (script exists; keep minimal entrypoints)

## Roadmap (Bigger Items)
- [ ] Design Go CLI (command surface + data model)
  - [ ] Plan/diff/apply parity with shell
  - [ ] Consume inputs from `config/` (Brewfile)
  - [ ] Replace shell orchestration gradually
- [ ] macOS VM integration tests
  - [ ] Script/automation to bring up a macOS VM (e.g., Anka, UTM, or Apple Silicon virtualize if feasible)
  - [ ] Run `make init` and verify idempotence (`make update`)
  - [ ] Collect artifacts (logs, diff report, timing)

## Docs
- [ ] recovery.md: reinstall + restore flow
- [ ] decisions.md: hidutil vs Karabiner, OMZ vs Starship, mise vs asdf
- [ ] first-boot.md: privacy permissions (Terminal Full Disk Access), enabling services

---

## Conventions
- Idempotent shell with `bash -euo pipefail`; no inline sudo
- Keep macOS defaults declarative and testable (read checks)
- Prefer taps/versions pinned where feasible
- Use `.example` files for templates; keep secrets out of git

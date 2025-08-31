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

---

## System Defaults
- [ ] Finder: show status bar, path bar, all filename extensions
- [ ] Finder: new windows target `$HOME`
- [ ] Dock: size/magnify, autohide, remove recents
- [ ] Trackpad/Mouse: tap-to-click, three‑finger drag, natural scrolling
- [ ] Screenshots: set default dir to `~/Pictures/Screenshots`
- [ ] Safari/Privacy: disable auto-open safe downloads, tracking prevention, show full URL
- [ ] Sleep/Password: require password after sleep/wake
- [ ] Tests: read‑only checks for each default (types/values) in `tests/defaults/`

## Homebrew: Apps, Fonts, CLIs
- [ ] Developer CLIs: `fzf`, `ripgrep`, `fd`, `eza`, `bat`, `tree`, `gnu-sed`, `gnu-tar`
- [ ] Terminal + Fonts: `iterm2` (or `alacritty`), `font-jetbrains-mono-nerd-font`
- [ ] Utilities: `AltTab`, `Raycast`/`Alfred` (pick one)
- [ ] MAS entries for required Apple apps (ids pinned in Brewfile)
- [ ] Example configs under `config/` for selected tools (iTerm2/Alacritty/starship)
- [ ] Tests: `brew bundle check` dry-run gate in `tests/homebrew.bats`

## Shell & Dotfiles
- [ ] Expand OMZ `bean` plugin modules:
  - [ ] `scripts/git.zsh`: git aliases/wrappers (lean on `git-spice` where useful)
  - [ ] `scripts/direnv.zsh`: hook only if present
  - [ ] `scripts/fzf.zsh`: keybindings if installed
- [ ] Optional: starship prompt support (`config/starship.example.toml`)
- [ ] Tests: `zsh` plugin loads without errors (smoke via `zsh -ic true` if available)

## Languages/Toolchains
- [ ] Add `mise` (rtx) or `asdf` to Brewfile (pick one)
- [ ] `config/mise.example.toml` with pinned versions (node, python, etc.)
- [ ] Tests: presence + `mise --version` skip‑aware

## SSH / GPG (templates only; no secrets)
- [ ] `config/ssh/config.example`
- [ ] `config/gpg-agent.conf.example` and `pinentry-mac` in Brewfile
- [ ] Docs: short note on generating keys + Keychain integration
- [ ] Tests: file existence only

## Security & Updates (documented, not enforced)
- [ ] Firewall enabled (doc only)
- [ ] Software updates command + cadence (doc only)
- [ ] VPN/ZT: `tailscale` cask + `config/tailscale.example.sh`

## Diff / Snapshots / Tooling
- [ ] Treat formula pulled in by casks as allowed deps in extras
- [ ] Optional flag to include dependency closure details in report (for debugging)
- [ ] `tools/prune_snapshots.sh` to keep last N snapshots
- [ ] Make targets: `diff-open`, `snapshots-clean N`
- [ ] Tests: prune dry‑run + report generation flags

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


Zsh Configuration

Overview
- This repo configures Zsh with Oh My Zsh and enables autojump.

Autoloaded Plugins
- `autojump`: enables `j`, `jo`, and related commands if the formula is installed.

Installation
- Homebrew installs `autojump` via the Brewfile.
- The `.zshrc` includes the `autojump` plugin and falls back to sourcing the Homebrew profile script if needed:
  - `/opt/homebrew/etc/profile.d/autojump.sh` (Apple Silicon)
  - `/usr/local/etc/profile.d/autojump.sh` (Intel)

Usage
- After a few `cd` operations, use `j <dir>` to jump to frequently used paths.


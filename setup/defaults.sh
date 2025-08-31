#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h | --help)
      cat << 'USAGE'
defaults.sh (generated)

Apply macOS system defaults captured from the current machine.
Use --dry-run to print the commands without applying changes.
USAGE
      exit 0
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "+ $*"
  else
    "$@"
  fi
}

echo "Applying macOS defaults (DRY_RUN=$DRY_RUN)…"

# Keyboard: faster key repeat and no press-and-hold
run defaults write -g KeyRepeat -int 2
run defaults write -g InitialKeyRepeat -int 15
run defaults write -g ApplePressAndHoldEnabled -bool false

# Keyboard: full keyboard access (Tab moves focus to controls)
run defaults write -g AppleKeyboardUIMode -int 3

# Keyboard: use F1, F2, etc. as standard function keys
run defaults write -g com.apple.keyboard.fnState -bool true

echo "Done. Some changes may require logout/restart of apps."

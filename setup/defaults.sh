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

# Finder: show status bar, path bar, and all file extensions
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder ShowPathbar -bool true
run defaults write -g AppleShowAllExtensions -bool true

# Finder: new windows open HOME
run defaults write com.apple.finder NewWindowTarget -string PfHm
run defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Dock: size, magnification, autohide, no recents
run defaults write com.apple.dock tilesize -int 36
run defaults write com.apple.dock magnification -bool true
run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock show-recents -bool false

# Trackpad/Mouse: tap to click, three-finger drag, natural scroll
run defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
run defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
run defaults write -g com.apple.swipescrolldirection -bool true

# Screenshots: set default directory (create if needed)
run mkdir -p "$HOME/Pictures/Screenshots"
run defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Safari / Privacy: show full URL; disable auto-open of "safe" downloads; enable fraud warnings
run defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
run defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
run defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Security: require password immediately after sleep or screen saver begins
run defaults write com.apple.screensaver askForPassword -int 1
run defaults write com.apple.screensaver askForPasswordDelay -int 0

# Profile-specific defaults (optional)
if [[ -r "$HOME/.config/homesetup/profile.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/homesetup/profile.env"
fi
: "${HS_PROFILE:=base}"
if [[ -n "${HS_PROFILE:-}" && -r "$(dirname "$0")/defaults.d/${HS_PROFILE}.sh" ]]; then
  # shellcheck disable=SC1090
  source "$(dirname "$0")/defaults.d/${HS_PROFILE}.sh"
fi

echo "Done. Some changes may require logout/restart of apps."

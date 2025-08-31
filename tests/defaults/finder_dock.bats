#!/usr/bin/env bats

@test "defaults.sh includes Finder/Dock/Trackpad/Screenshots settings" {
  [ -f setup/defaults.sh ]
  run grep -E "ShowStatusBar|ShowPathbar|AppleShowAllExtensions|NewWindowTarget|NewWindowTargetPath|tilesize|magnification|autohide|show-recents|Clicking|TrackpadThreeFingerDrag|swipescrolldirection|screencapture" setup/defaults.sh
  [ "$status" -eq 0 ]
}


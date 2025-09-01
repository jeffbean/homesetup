#!/usr/bin/env bats

@test "defaults.sh includes Safari privacy and sleep/password settings" {
  [ -f setup/defaults.sh ]
  run grep -E "ShowFullURLInSmartSearchField|AutoOpenSafeDownloads|WarnAboutFraudulentWebsites|askForPassword\b|askForPasswordDelay\b" setup/defaults.sh
  [ "$status" -eq 0 ]
}


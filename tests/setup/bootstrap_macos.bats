#!/usr/bin/env bats

@test "bootstrap runs with skips (no bundle, no defaults)" {
  if [ ! -f setup/bootstrap_macos.sh ]; then
    skip "bootstrap_macos.sh not found"
  fi
  run bash setup/bootstrap_macos.sh --yes --no-bundle --no-defaults
  [ "$status" -eq 0 ]
}


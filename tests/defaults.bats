#!/usr/bin/env bats

@test "defaults script dry-run executes successfully" {
  if [ ! -f setup/defaults.sh ]; then
    skip "setup/defaults.sh not found"
  fi
  run bash setup/defaults.sh --dry-run
  [ "$status" -eq 0 ]
}


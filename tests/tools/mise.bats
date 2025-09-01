#!/usr/bin/env bats

@test "mise is installed or test skips" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise not installed on this machine."
  fi
  run mise --version
  [ "$status" -eq 0 ]
}


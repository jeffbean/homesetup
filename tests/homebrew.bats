#!/usr/bin/env bats

@test "brew is installed or test skips" {
  if ! command -v brew >/dev/null 2>&1; then
    skip "Homebrew not installed on this machine."
  fi
  run brew --version
  [ "$status" -eq 0 ]
}


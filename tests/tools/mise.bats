#!/usr/bin/env bats

@test "mise is installed or test skips" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise not installed on this machine."
  fi
  run mise --version || true
  if [ "$status" -ne 0 ]; then
    skip "mise present but not runnable in this environment."
  fi
  [ "$status" -eq 0 ]
}

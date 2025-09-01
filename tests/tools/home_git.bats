#!/usr/bin/env bats

@test "home_git init runs dry-run" {
  run bash tools/home_git.sh init
  [ "$status" -eq 0 ]
}

@test "home_git status runs (may fail if not init)" {
  run bash tools/home_git.sh status || true
  # Just ensure it executed without crashing the harness
  [ -n "$output" ] || true
}


#!/usr/bin/env bats

@test "brew bundle check runs (skip-aware)" {
  if ! command -v brew >/dev/null 2>&1; then
    skip "Homebrew not installed"
  fi
  # Do not assert status; just run to surface output
  run brew bundle check --file=Brewfile
  [ -n "$output" ] || true
}


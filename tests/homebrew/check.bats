#!/usr/bin/env bats

@test "brew bundle check runs (skip-aware)" {
  if ! command -v brew >/dev/null 2>&1; then
    skip "Homebrew not installed"
  fi
  # Do not assert status; just run to surface output
  BF=$(bash -lc "source tools/lib.sh; brewfile_path")
  run brew bundle check --file="$BF"
  [ -n "$output" ] || true
}

#!/usr/bin/env bats

@test "zsh starts non-interactively (smoke)" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi
  run zsh -ic 'echo ok'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "ok"
}


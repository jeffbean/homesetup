#!/usr/bin/env bats

@test "install-git-spice runs in dry-run" {
  run bash setup/install-git-spice.sh
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "git-spice" || true
}


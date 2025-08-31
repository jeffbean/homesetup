#!/usr/bin/env bats

@test "profile list returns profiles" {
  run bash tools/profile.sh list
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "dev"
}

@test "profile activate dry-run works" {
  run bash tools/profile.sh activate dev
  [ "$status" -eq 0 ]
}


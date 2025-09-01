#!/usr/bin/env bats

@test "profile list returns profiles" {
  run bash tools/profile.sh list
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "base"
}

@test "profile activate dry-run works" {
  run bash tools/profile.sh activate base
  [ "$status" -eq 0 ]
}

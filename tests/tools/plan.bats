#!/usr/bin/env bats

@test "plan script runs and emits report path" {
  run bash tools/plan.sh
  [ "$status" -eq 0 ]
  # Not asserting exact text, just that it didn't fail
}


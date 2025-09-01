#!/usr/bin/env bats

@test "plan script runs and emits report path (fast)" {
  HS_FAST=1 run bash tools/plan.sh
  [ "$status" -eq 0 ]
  # Not asserting exact text, just that it didn't fail
}

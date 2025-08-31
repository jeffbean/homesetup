#!/usr/bin/env bats

@test "diff tool generates a markdown report" {
  run bash tools/diff_state.sh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Diff report written to:" # path echoed
}


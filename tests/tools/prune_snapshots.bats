#!/usr/bin/env bats

@test "prune_snapshots runs in dry-run with default keep" {
  run bash tools/prune_snapshots.sh
  [ "$status" -eq 0 ]
}


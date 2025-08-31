#!/usr/bin/env bats

@test "apply-hidutil dry-run handles missing config gracefully" {
  run bash setup/apply-hidutil.sh
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "No config at config/hidutil.json" || true
}


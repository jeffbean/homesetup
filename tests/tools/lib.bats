#!/usr/bin/env bats

setup() {
  LIB_PATH="$BATS_TEST_DIRNAME/../../tools/lib.sh"
  [ -f "$LIB_PATH" ]
}

@test "lib: log/warn/error print prefixes" {
  run bash -lc "source '$LIB_PATH'; log test"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  run bash -lc "source '$LIB_PATH'; warn test"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  run bash -lc "source '$LIB_PATH'; error test 2>&1"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "\[x\]"
}

@test "lib: die exits nonzero" {
  run bash -lc "source '$LIB_PATH'; die fatal"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "^\[x\] fatal$"
}

@test "lib: run respects DRY_RUN=true (no exec)" {
  run bash -lc "source '$LIB_PATH'; DRY_RUN=true; run 'echo hello'"
  [ "$status" -eq 0 ]
  # Should print the command but not execute it
  [ "$output" = "+ echo hello" ]
}

@test "lib: run executes when DRY_RUN=false" {
  run bash -lc "source '$LIB_PATH'; DRY_RUN=false; run echo hello"
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}

@test "lib: confirm respects AUTO_YES=true" {
  run bash -lc "AUTO_YES=true; source '$LIB_PATH'; confirm 'ok?'"
  [ "$status" -eq 0 ]
}

@test "lib: confirm prompts and default is No (simulate 'n')" {
  run bash -lc "AUTO_YES=false; source '$LIB_PATH'; printf 'n\n' | confirm 'ok?'"
  [ "$status" -ne 0 ]
}

@test "lib: require_macos succeeds on Darwin or skips" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "not macOS"
  fi
  run bash -lc "source '$LIB_PATH'; require_macos"
  [ "$status" -eq 0 ]
}

@test "lib: load_profile_env is a no-op" {
  run bash -lc "source '$LIB_PATH'; load_profile_env; echo ok"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q ok
}

@test "lib: resolve_path returns absolute path" {
  run bash -lc "source '$LIB_PATH'; d=\"\$(mktemp -d)\"; f=\"\$d/file\"; echo hi > \"\$f\"; rp=\"\$(resolve_path \"\$f\")\"; case \"\$rp\" in /*) echo OK ;; *) echo NO ;; esac"
  [ "$status" -eq 0 ]
  [ "$output" = "OK" ]
}

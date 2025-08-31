#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
}

@test "generate_desired creates expected files" {
  run bash tools/generate_desired.sh
  [ "$status" -eq 0 ]

  # Symlink to latest desired
  [ -L snapshots/desired/latest ]
  des_dir=$(readlink snapshots/desired/latest)
  [ -n "$des_dir" ]

  # Files are created
  [ -f "$des_dir/desired_brew_formulae.txt" ]
  [ -f "$des_dir/desired_brew_casks.txt" ]
  [ -f "$des_dir/desired_mas_apps.tsv" ]
  [ -f "$des_dir/defaults_desired.tsv" ]

  # Sanity: Brewfile parsing includes at least one known formula from repo Brewfile
  run grep -E "^(git|zsh)$" "$des_dir/desired_brew_formulae.txt"
  [ "$status" -eq 0 ]
}


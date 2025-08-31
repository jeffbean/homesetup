#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      cat <<'USAGE'
defaults.sh (generated)

Apply macOS system defaults captured from the current machine.
Use --dry-run to print the commands without applying changes.
USAGE
      exit 0
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

echo "Applying macOS defaults (DRY_RUN=$DRY_RUN)…"

echo "Done. Some changes may require logout/restart of apps."

#!/usr/bin/env bash
# Common helpers for homesetup scripts. Source, do not execute.
# Intended to be safe, idempotent, and re-runnable.

# Logging helpers
log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
error() { printf "[x] %s\n" "$*" >&2; }
die() { error "$@"; exit 1; }

# Confirm helper (respects AUTO_YES=true)
confirm() {
  local msg=${1:-"Proceed?"}
  if [[ "${AUTO_YES:-false}" == "true" ]]; then return 0; fi
  read -r -p "$msg [y/N] " reply || true
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

# Require macOS (Darwin)
require_macos() { [[ "$(uname -s)" == "Darwin" ]] || die "This script targets macOS (Darwin)."; }

# DRY-RUN aware runner.
# Supports both: run "cmd with args" and run cmd arg1 arg2
run() {
  local is_dry="${DRY_RUN:-false}"
  if [[ "$is_dry" == true || "$is_dry" == "true" ]]; then
    if [[ $# -eq 1 ]]; then
      echo "+ $1"
    else
      printf "+"
      printf " %q" "$@"
      echo
    fi
    return 0
  fi
  if [[ $# -eq 1 ]]; then
    eval "$1"
  else
    "$@"
  fi
}

# Load active profile env if present (sets HS_PROFILE if missing)
load_profile_env() {
  if [[ -r "$HOME/.config/homesetup/profile.env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.config/homesetup/profile.env"
  fi
  : "${HS_PROFILE:=base}"
}

# Return the path to the Brewfile used as setup input.
# Resolution order:
#   1) $HS_BREWFILE if set
#   2) $REPO_ROOT/config/Brewfile
#   3) $REPO_ROOT/Brewfile (legacy fallback)
brewfile_path() {
  # Determine REPO_ROOT from this library's location
  local libdir
  libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local root
  root="$(cd "$libdir/.." && pwd -P)"
  if [[ -n "${HS_BREWFILE:-}" ]]; then
    echo "$HS_BREWFILE"
    return 0
  fi
  local cfg="$root/config/Brewfile"
  if [[ -f "$cfg" ]]; then echo "$cfg"; return 0; fi
  if [[ -f "$root/Brewfile" ]]; then echo "$root/Brewfile"; return 0; fi
  echo "$cfg" # preferred canonical path even if missing
}

# Resolve a path to absolute form (best-effort, portable)
resolve_path() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p" 2>/dev/null || echo "$p"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$p" << 'PY'
import os,sys
p=sys.argv[1]
try:
    print(os.path.realpath(p))
except Exception:
    print(p)
PY
  else
    echo "$p"
  fi
}

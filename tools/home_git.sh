#!/usr/bin/env bash
set -euo pipefail

# Manage a bare Git repo for $HOME (work-tree), without mutating by default.
# This complements stow: keep modular dotfiles in repo, but allow tracking
# ad-hoc files in $HOME via a dedicated bare repo.

DRY_RUN=true
CMD="help"
DOT_GIT_DIR="${DOT_GIT_DIR:-$HOME/.homesetup.git}"
WORKTREE="$HOME"

usage() {
  cat << 'USAGE'
home_git.sh [init|status|config] [--apply] [--dir PATH]

Commands:
  init          Initialize a bare repo at --dir (default: ~/.homesetup.git)
  status        Show status (`git status -s`) for the bare repo/work-tree
  config        Print recommended configs (core.worktree, hide untracked)

Flags:
  --apply       Execute (default: dry-run)
  --dir PATH    Override DOT_GIT_DIR path (default: ~/.homesetup.git)

Examples:
  bash tools/home_git.sh init --apply
  DOT_GIT_DIR=~/.dots.git bash tools/home_git.sh status

Note:
  This does not replace stow. It augments it for cases where tracking files
  directly in $HOME is simpler. Prefer stow for modular dotfiles.
USAGE
}

log() { printf "[+] %s\n" "$*"; }
run() { if [[ "$DRY_RUN" == true ]]; then echo "+ $*"; else eval "$*"; fi; }

parse_args() {
  case "${1:-}" in
    init|status|config) CMD="$1"; shift || true ;;
    -h|--help|"") usage; exit 0 ;;
    *) usage; echo "Unknown command: $1" >&2; exit 2 ;;
  esac
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) DRY_RUN=false; shift ;;
      --dir) DOT_GIT_DIR="${2:-$DOT_GIT_DIR}"; shift 2 ;;
      *) echo "Ignoring arg: $1"; shift ;;
    esac
  done
}

git_cmd() { GIT_DIR="$DOT_GIT_DIR" GIT_WORK_TREE="$WORKTREE" git "$@"; }

do_init() {
  if [[ -d "$DOT_GIT_DIR" ]]; then
    log "Bare repo already exists at $DOT_GIT_DIR"; return 0
  fi
  run "git init --bare \"$DOT_GIT_DIR\""
  # Recommended configs
  run "git --git-dir=\"$DOT_GIT_DIR\" config core.worktree \"$WORKTREE\""
  run "git --git-dir=\"$DOT_GIT_DIR\" config status.showUntrackedFiles no"
  log "Initialized bare repo at: $DOT_GIT_DIR (dry-run=$DRY_RUN)"
}

do_status() {
  if [[ ! -d "$DOT_GIT_DIR" ]]; then
    echo "Bare repo not found at $DOT_GIT_DIR"; return 1
  fi
  git_cmd status -s || true
}

do_config() {
  cat <<CFG
Recommended configuration (already applied by init):
  git --git-dir="$DOT_GIT_DIR" config core.worktree "$WORKTREE"
  git --git-dir="$DOT_GIT_DIR" config status.showUntrackedFiles no
Shell helpers:
  alias home='git --git-dir=$DOT_GIT_DIR --work-tree=$WORKTREE'
  home status
CFG
}

parse_args "$@"
case "$CMD" in
  init) do_init ;;
  status) do_status ;;
  config) do_config ;;
esac


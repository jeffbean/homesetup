# mise integration (optional, profile-aware)
if command -v mise >/dev/null 2>&1; then
  # Load mise for WIP profile by default; base can enable per-project via direnv
  if [[ "${HS_PROFILE:-base}" == "wip" ]]; then
    eval "$(mise activate zsh)"
  fi
fi


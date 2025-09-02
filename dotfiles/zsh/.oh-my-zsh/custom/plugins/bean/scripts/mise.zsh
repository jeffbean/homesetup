# mise integration (optional)
if command -v mise >/dev/null 2>&1; then
  # Enable explicitly by setting ENABLE_MISE=1 in your shell
  if [[ "${ENABLE_MISE:-0}" == "1" ]]; then
    eval "$(mise activate zsh)"
  fi
fi


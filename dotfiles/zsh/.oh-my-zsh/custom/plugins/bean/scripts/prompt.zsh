# Initialize starship if selected and available
if [[ "${PROMPT_FLAVOR:-}" == "starship" ]] && command -v starship >/dev/null 2>&1; then
  # Use repo-provided config if present
  if [[ -f "$HOME/.config/starship.toml" ]]; then
    :
  elif [[ -f "$HOME/.config/homesetup/starship.toml" ]]; then
    ln -sf "$HOME/.config/homesetup/starship.toml" "$HOME/.config/starship.toml" 2>/dev/null || true
  fi
  eval "$(starship init zsh)"
fi


# direnv integration (optional)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
  # Quieter direnv logs
  export DIRENV_LOG_FORMAT=""
fi


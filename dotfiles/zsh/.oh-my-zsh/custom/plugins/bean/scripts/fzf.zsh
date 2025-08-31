# fzf integration (optional)
if command -v fzf >/dev/null 2>&1; then
  # Prefer Homebrew-installed key-bindings if available
  if [[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
    source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  elif [[ -r /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
    source /usr/local/opt/fzf/shell/key-bindings.zsh
  fi
  # Sensible defaults
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,node_modules,target,.DS_Store}"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi


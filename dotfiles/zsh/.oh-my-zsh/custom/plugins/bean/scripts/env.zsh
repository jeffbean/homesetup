# Environment settings (example) — adjust as needed

# Prefer Homebrew paths early
if [[ -d /opt/homebrew/bin ]]; then
  path=(/opt/homebrew/bin $path)
fi

# Local bin
if [[ -d "$HOME/.local/bin" ]]; then
  path=("$HOME/.local/bin" $path)
fi

export EDITOR=${EDITOR:-nvim}


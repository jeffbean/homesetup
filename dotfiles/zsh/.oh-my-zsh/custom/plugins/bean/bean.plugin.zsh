# Bean custom plugin for organizing zsh config
#
# Layout:
#   scripts/*.zsh   -> sourced on startup (aliases, env, helpers)
#   functions/*     -> autoloadable functions (one file per function)
#   completions/_*  -> completion definitions (optional)

plugin_root="${0:A:h}"

# Source script snippets
scripts_dir="$plugin_root/scripts"
if [[ -d "$scripts_dir" ]]; then
  for f in "$scripts_dir"/*.zsh; do
    [[ -r "$f" ]] && source "$f"
  done
fi

# Autoload functions (one function per file)
func_dir="$plugin_root/functions"
if [[ -d "$func_dir" ]]; then
  fpath=($func_dir $fpath)
  # Autoload every file name as a function
  for f in "$func_dir"/*(.N:t); do
    autoload -Uz "$f"
  done
fi

# Completions (optional): add directory to fpath so _files are found
comp_dir="$plugin_root/completions"
if [[ -d "$comp_dir" ]]; then
  fpath=($comp_dir $fpath)
fi


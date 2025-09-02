gsnb() {
  if [ $# -eq 0 ]; then
    display_error "Usage: gspnew <branch title sentence>"
    return 1
  fi

  local title="$*"

  # Convert title → safe branch name
  local branch_name
  branch_name=$(echo "$title"     | tr '[:upper:]' '[:lower:]'     | sed -E 's/[^a-z]+/-/g; s/^-+|-+$//g')

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    display_error "Not in a git repository."
    return 1
  }

  echo "📦 Creating branch '[32m$branch_name[0m' from '[36m$current_branch[0m' with git-spice..."
  if ! gs branch create "$branch_name" -m "$title"; then
    display_error "Failed to create branch with git-spice."
    return 1
  fi

  # Set upstream to the branch we created from (local tracking)
  if ! git branch --set-upstream-to="$current_branch" "$branch_name" >/dev/null 2>&1; then
    display_error "Failed to set local upstream to '$current_branch'."
    return 1
  fi

  echo "✅ [32mCreated branch '$branch_name' (title: "$title")[0m"
  echo "🔗 [36mLocal upstream set to '$current_branch'[0m"
}

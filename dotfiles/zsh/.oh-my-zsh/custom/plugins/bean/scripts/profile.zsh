# Profiles removed; keep as a no-op placeholder if legacy file exists
_hs_profile_file="$HOME/.config/homesetup/profile.env"
if [[ -r "$_hs_profile_file" ]]; then
  source "$_hs_profile_file"
fi


#!/usr/bin/env bash
set -euo pipefail

# Compare current snapshot vs desired state and produce a diff report.

log() { printf "[+] %s\n" "$*"; }
error() {
  printf "[x] %s\n" "$*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || error "This tool targets macOS (Darwin)."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

CUR_DIR="${1:-$REPO_ROOT/snapshots/latest}"
DES_DIR="${2:-$REPO_ROOT/snapshots/desired/latest}"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$REPO_ROOT/snapshots/diff/$STAMP"
mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/report.md"

section() {
  echo "" >> "$REPORT"
  echo "## $1" >> "$REPORT"
}

echo "macOS setup diff report" > "$REPORT"
echo "Current: $CUR_DIR" >> "$REPORT"
echo "Desired: $DES_DIR" >> "$REPORT"

# ---------- Homebrew formulae ----------
section "Homebrew formulae"
if [[ -f "$CUR_DIR/brew_formulae.txt" ]]; then
  cut -d' ' -f1 "$CUR_DIR/brew_formulae.txt" | sort -u > "$OUT_DIR/_cur_brew.txt"
else : > "$OUT_DIR/_cur_brew.txt"; fi
if [[ -f "$DES_DIR/desired_brew_formulae.txt" ]]; then
  sort -u "$DES_DIR/desired_brew_formulae.txt" > "$OUT_DIR/_des_brew.txt"
else : > "$OUT_DIR/_des_brew.txt"; fi
comm -13 "$OUT_DIR/_cur_brew.txt" "$OUT_DIR/_des_brew.txt" > "$OUT_DIR/_brew_to_install.txt" || true
comm -23 "$OUT_DIR/_cur_brew.txt" "$OUT_DIR/_des_brew.txt" > "$OUT_DIR/_brew_extras.txt" || true
{
  echo "To install:"
  sed 's/^/  - /' "$OUT_DIR/_brew_to_install.txt"
  echo ""
  echo "Not in desired (extras):"
  sed 's/^/  - /' "$OUT_DIR/_brew_extras.txt"
} >> "$REPORT"

# ---------- Homebrew casks ----------
section "Homebrew casks"
if [[ -f "$CUR_DIR/brew_casks.txt" ]]; then
  cut -d' ' -f1 "$CUR_DIR/brew_casks.txt" | sort -u > "$OUT_DIR/_cur_casks.txt"
else : > "$OUT_DIR/_cur_casks.txt"; fi
if [[ -f "$DES_DIR/desired_brew_casks.txt" ]]; then
  sort -u "$DES_DIR/desired_brew_casks.txt" > "$OUT_DIR/_des_casks.txt"
else : > "$OUT_DIR/_des_casks.txt"; fi
comm -13 "$OUT_DIR/_cur_casks.txt" "$OUT_DIR/_des_casks.txt" > "$OUT_DIR/_casks_to_install.txt" || true
comm -23 "$OUT_DIR/_cur_casks.txt" "$OUT_DIR/_des_casks.txt" > "$OUT_DIR/_casks_extras.txt" || true
{
  echo "To install:"
  sed 's/^/  - /' "$OUT_DIR/_casks_to_install.txt"
  echo ""
  echo "Not in desired (extras):"
  sed 's/^/  - /' "$OUT_DIR/_casks_extras.txt"
} >> "$REPORT"

# ---------- MAS apps ----------
section "Mac App Store apps"
if [[ -f "$CUR_DIR/mas_apps.txt" ]]; then
  awk '{print $1}' "$CUR_DIR/mas_apps.txt" | sort -u > "$OUT_DIR/_cur_mas_ids.txt"
else : > "$OUT_DIR/_cur_mas_ids.txt"; fi
if [[ -f "$DES_DIR/desired_mas_apps.tsv" ]]; then
  awk -F"\t" '{print $1}' "$DES_DIR/desired_mas_apps.tsv" | sort -u > "$OUT_DIR/_des_mas_ids.txt"
else : > "$OUT_DIR/_des_mas_ids.txt"; fi
comm -13 "$OUT_DIR/_cur_mas_ids.txt" "$OUT_DIR/_des_mas_ids.txt" > "$OUT_DIR/_mas_to_install.txt" || true
comm -23 "$OUT_DIR/_cur_mas_ids.txt" "$OUT_DIR/_des_mas_ids.txt" > "$OUT_DIR/_mas_extras.txt" || true
{
  echo "To install (by id):"
  sed 's/^/  - /' "$OUT_DIR/_mas_to_install.txt"
  echo ""
  echo "Not in desired (extras, by id):"
  sed 's/^/  - /' "$OUT_DIR/_mas_extras.txt"
} >> "$REPORT"

# ---------- Defaults ----------
section "macOS defaults"
CUR_DEF="$CUR_DIR/defaults_values.txt"
DES_DEF="$DES_DIR/defaults_desired.tsv"
if [[ -f "$DES_DEF" ]]; then
  : > "$OUT_DIR/_defaults_issues.tsv"
  while IFS=$'\t' read -r domain key type desired_value; do
    [[ -n "$domain" && -n "$key" ]] || continue
    current_line=$(grep -E "^${domain}[[:space:]]+${key}[[:space:]]+=" "$CUR_DEF" 2> /dev/null || true)
    current_value=${current_line#*= }
    current_value=${current_value:-"<not set>"}
    # normalize bools for comparison
    norm_des="$desired_value"
    norm_cur="$current_value"
    if [[ "$type" == "-bool" ]]; then
      norm_cur=$(echo "$norm_cur" | sed 's/^1$/true/; s/^0$/false/; s/YES/true/; s/NO/false/' | tr '[:upper:]' '[:lower:]')
      norm_des=$(echo "$norm_des" | tr '[:upper:]' '[:lower:]')
    fi
    if [[ "$norm_cur" != "$norm_des" ]]; then
      printf "%s\t%s\t%s\t%s\n" "$domain" "$key" "$current_value" "$desired_value" >> "$OUT_DIR/_defaults_issues.tsv"
    fi
  done < "$DES_DEF"
  {
    echo "Mismatches or missing values:"
    awk -F"\t" '{printf "  - %s %s: current=%s -> desired=%s\n", $1, $2, $3, $4}' "$OUT_DIR/_defaults_issues.tsv" || true
  } >> "$REPORT"
else
  echo "No desired defaults found." >> "$REPORT"
fi

# ---------- Dotfiles ----------
section "Dotfiles linking"
CUR_DOTS="$CUR_DIR/dotfiles_status.tsv"
DES_DOTS="$DES_DIR/dotfiles_expected.tsv"
if [[ -f "$DES_DOTS" ]]; then
  # Build an index of expected targets
  awk -F"\t" 'NR>1 {print $3"\t"$1"\t"$2}' "$DES_DOTS" | sort -u > "$OUT_DIR/_des_targets.tsv"
  # Build map of current target -> state
  awk -F"\t" 'NR>1 {print $4"\t"$3"\t"$1"\t"$2"\t"$5}' "$CUR_DOTS" 2> /dev/null | sort -u > "$OUT_DIR/_cur_targets.tsv" || true
  : > "$OUT_DIR/_dotfiles_issues.tsv"
  join -t $'\t' -a1 -e "<missing>" -o 1.1,2.2,2.3,2.2,2.3,2.4 -1 1 -2 1 \
    <(cut -f1 "$OUT_DIR/_des_targets.tsv") \
    <(awk -F"\t" '{print $1"\t"$2"\t"$3"\t"$4}' "$OUT_DIR/_cur_targets.tsv") |
    while IFS=$'\t' read -r target state pkg rel; do
      if [[ "$state" != "linked_ok" ]]; then
        printf "%s\t%s\t%s\t%s\n" "$target" "${state:-missing}" "$pkg" "$rel" >> "$OUT_DIR/_dotfiles_issues.tsv"
      fi
    done
  {
    echo "Issues (missing or not linked_ok):"
    awk -F"\t" '{printf "  - %s (%s/%s): state=%s\n", $1, $3, $4, $2}' "$OUT_DIR/_dotfiles_issues.tsv" || true
  } >> "$REPORT"
else
  echo "No desired dotfiles found." >> "$REPORT"
fi

ln -sfn "$OUT_DIR" "$REPO_ROOT/snapshots/diff/latest"
log "Diff report written to: $REPORT"
echo "---"
cat "$REPORT"

#!/usr/bin/env bash
set -euo pipefail

branch="$(git branch --show-current)"
if [[ "$branch" != "bot/updates-init" ]]; then
  echo "Skip: current branch is $branch"
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "WARN: gh not installed; cannot auto-sync PR"
  exit 0
fi

tmp_body="$(mktemp)"
changed_files="$(git diff --name-only main...bot/updates-init 2>/dev/null || true)"
[[ -z "$changed_files" ]] && changed_files="$(git diff --name-only HEAD~1..HEAD 2>/dev/null || true)"

{
  cat .github/PULL_REQUEST_TEMPLATE.md
  echo
  echo "## Auto Summary"
  echo "### Changed files"
  if [[ -n "$changed_files" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && echo "- $f"
    done <<< "$changed_files"
  else
    echo "- (no file diff detected)"
  fi
  echo
  echo "### Risk hints"
  if grep -qE '^(scripts/|\.github/|README\.md|ROADMAP|docs/)' <<< "$changed_files"; then
    echo "- Script/runtime changes present: verify cron/env/exit-codes"
  else
    echo "- Mostly docs/meta changes"
  fi
} > "$tmp_body"

if gh pr view --head bot/updates-init --json number >/dev/null 2>&1; then
  num="$(gh pr view --head bot/updates-init --json number -q .number)"
  gh pr edit "$num" --title "bot: workspace updates" --body-file "$tmp_body" >/dev/null || true
  echo "Updated PR #$num"
else
  gh pr create --base main --head bot/updates-init --title "bot: workspace updates" --body-file "$tmp_body" >/dev/null
  echo "Created PR"
fi

rm -f "$tmp_body"

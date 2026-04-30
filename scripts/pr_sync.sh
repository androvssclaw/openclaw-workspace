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

if gh pr view --head bot/updates-init --json number >/dev/null 2>&1; then
  num="$(gh pr view --head bot/updates-init --json number -q .number)"
  gh pr edit "$num" --title "bot: workspace updates" --body-file .github/PULL_REQUEST_TEMPLATE.md >/dev/null || true
  echo "Updated PR #$num"
else
  gh pr create --base main --head bot/updates-init --title "bot: workspace updates" --body-file .github/PULL_REQUEST_TEMPLATE.md >/dev/null
  echo "Created PR"
fi
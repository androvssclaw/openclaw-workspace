#!/usr/bin/env bash
set -euo pipefail

msg="${1:-chore: auto update}"
branch="$(git branch --show-current)"
[[ "$branch" == "bot/updates-init" ]] || { echo "Not on bot/updates-init"; exit 1; }

git add -A
git commit -m "$msg" || { echo "Nothing to commit"; exit 0; }
git push origin bot/updates-init
./scripts/pr_sync.sh || true
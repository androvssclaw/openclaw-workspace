#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/deploy.sh --confirm DEPLOY
  ./scripts/deploy.sh --dry-run

What it does:
  1) pre-check: health thresholds + smoke check
  2) git fetch --prune
  3) fast-forward current branch from upstream
  4) post-check: openclaw status + health thresholds

Safety:
  - Requires explicit confirmation token: --confirm DEPLOY
  - Refuses to run with uncommitted local changes
EOF
}

CONFIRM=""
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --confirm)
      CONFIRM="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$DRY_RUN" -ne 1 && "$CONFIRM" != "DEPLOY" ]]; then
  echo "Refused: missing confirmation token. Use --confirm DEPLOY"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Refused: working tree is not clean. Commit/stash changes first."
  exit 1
fi

branch="$(git branch --show-current)"
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"

if [[ -z "$upstream" ]]; then
  echo "Refused: no upstream configured for branch '$branch'"
  exit 1
fi

echo "== deploy =="
echo "branch: $branch"
echo "upstream: $upstream"

echo "> pre-check: health thresholds"
./scripts/health_check_thresholds.sh || true
echo "> pre-check: smoke"
./scripts/smoke_check.sh || true

echo "> git fetch --prune"
git fetch --prune

echo "> git merge --ff-only $upstream"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: skipping merge"
else
  git merge --ff-only "$upstream"
fi

echo "> openclaw status (quick)"
openclaw status | sed -n '1,30p'

echo "> post-check: health thresholds"
./scripts/health_check_thresholds.sh || true

echo "Deploy check completed."
echo "Rollback hint: git reset --hard ORIG_HEAD  (use only if deployment introduced regressions)"

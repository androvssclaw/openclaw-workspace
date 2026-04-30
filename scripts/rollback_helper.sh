#!/usr/bin/env bash
set -euo pipefail

usage(){
  cat <<'EOF'
Usage:
  ./scripts/rollback_helper.sh --to ORIG_HEAD
  ./scripts/rollback_helper.sh --to <commit>
  ./scripts/rollback_helper.sh --dry-run
EOF
}

target="ORIG_HEAD"
dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --to) target="${2:-ORIG_HEAD}"; shift 2;;
    --dry-run) dry=1; shift;;
    -h|--help) usage; exit 0;;
    *) usage; exit 1;;
  esac
done

echo "Rollback target: $target"
if [[ $dry -eq 1 ]]; then
  echo "DRY RUN: git reset --hard $target"
  exit 0
fi

git reset --hard "$target"
openclaw status | sed -n '1,25p'
echo "Rollback complete."
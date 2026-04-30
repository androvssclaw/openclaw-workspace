#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEM_DIR="${ROOT}/memory"
OUT="${ROOT}/state/memory-review-$(date -u +%G-%V).md"
mkdir -p "${ROOT}/state"

latest_files="$(ls -1t ${MEM_DIR}/*.md 2>/dev/null | head -n 7 || true)"
{
  echo "# Memory Review"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "## Sources"
  echo "$latest_files"
  echo
  echo "## Proposed stable notes"
  grep -hE '^(## Decisions|- )' $latest_files 2>/dev/null | head -n 40 || true
} > "$OUT"

echo "Saved: $OUT"
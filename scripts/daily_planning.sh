#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state"
OUT_FILE="${OUT_DIR}/daily_planning.txt"
mkdir -p "$OUT_DIR"

cd "$ROOT"

{
  echo "# Daily Planning"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo

  echo "## Top focus (выбери 1-3)"
  awk '/^## Open Tasks/{flag=1;next}/^## Closed Tasks/{flag=0}flag && /^- \[ \]/{print "- " substr($0,7)}' TASKS.md 2>/dev/null | head -n 10 || true
  echo

  echo "## Reminder ideas"
  echo "- Проверить критичный таск через 2-3 часа"
  echo "- Закрыть хотя бы 1 задачу до конца дня"
  echo

  echo "## Quick ops"
  ./scripts/health.sh || true
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"
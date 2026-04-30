#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/state/memory_compact"
mkdir -p "$OUT_DIR"
TS="$(date -u +%Y-%m-%d)"
OUT="${OUT_DIR}/memory-compact-${TS}.md"
LATEST="${OUT_DIR}/latest.md"

ROADMAP="${ROOT}/ROADMAP.md"
TASKS="${ROOT}/TASKS.md"
README="${ROOT}/README.md"

extract_open_tasks() {
  awk '
    /^## Open Tasks/ {flag=1; next}
    /^## Closed Tasks/ {flag=0}
    flag {print}
  ' "$TASKS" | sed '/^$/d'
}

extract_roadmap_top() {
  awk '
    /^## Ближайшие/ {flag=1; next}
    /^---/ && flag {exit}
    flag {print}
  ' "$ROADMAP" | sed '/^$/d'
}

{
  echo "# Memory Compact"
  echo
  echo "- Date: ${TS}"
  echo "- Purpose: сжатая фиксация долгосрочных решений и текущих фокусов"
  echo
  echo "## Stable decisions"
  echo "- Git workflow: работа только в ветке bot/updates-init, main через PR"
  echo "- Merge policy: авто-merge только для docs-only PR"
  echo "- Backup policy: регулярные backups + retention + external sync"
  echo
  echo "## Current priorities (from ROADMAP)"
  extract_roadmap_top
  echo
  echo "## Open tasks snapshot"
  extract_open_tasks
  echo
  echo "## Changes since previous cycle"
  echo "- Added backup restore test script"
  echo "- Added incident report script"
  echo "- Updated Git workflow policy"
  echo
  echo "## Next actions"
  echo "1. Прогон restore-test по расписанию (monthly)"
  echo "2. Доработка incident report thresholds"
  echo "3. Формализация weekly memory compact loop"
} > "$OUT"

cp "$OUT" "$LATEST"
echo "Wrote: $OUT"
echo "Updated: $LATEST"
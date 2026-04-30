#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== WEEKLY CLEANUP ==="

./scripts/memory_compact.sh || true
./scripts/weekly_scorecard.sh || true

echo

echo "Open tasks snapshot:"
./scripts/tasks.sh | sed -n '1,60p' || true

echo

echo "Recent docs touched:"
ls -lt README.md ROADMAP.md MEMORY.md 2>/dev/null || true

echo

echo "Cleanup done."
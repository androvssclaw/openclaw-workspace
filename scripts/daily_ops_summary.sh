#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="./state"
OUT_FILE="${OUT_DIR}/daily_ops_summary.txt"
mkdir -p "$OUT_DIR"

{
  echo "# Daily Ops Summary"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  ./scripts/health.sh
  echo
  echo "--- OpenClaw journal tail (50) ---"
  journalctl --user -u openclaw-gateway.service -n 50 --no-pager || true
} > "$OUT_FILE"

echo "Saved: $OUT_FILE"

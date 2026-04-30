#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT}/state"
LOG_FILE="${LOG_DIR}/backup_restore_test_history.log"
mkdir -p "$LOG_DIR"

TS="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
if "${ROOT}/scripts/backup_restore_test.sh" --restore-sample --sample-limit 30 >> "$LOG_FILE" 2>&1; then
  echo "[$TS] restore-test: PASS" >> "$LOG_FILE"
else
  echo "[$TS] restore-test: FAIL" >> "$LOG_FILE"
  exit 1
fi

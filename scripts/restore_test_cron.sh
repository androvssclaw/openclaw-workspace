#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT}/state"
LOG_FILE="${LOG_DIR}/backup_restore_test_history.log"
mkdir -p "$LOG_DIR"

TS="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
latest_archive="$(ls -1t "${HOME}/backups/openclaw/daily"/openclaw-important-*.tar.gz 2>/dev/null | head -n1 || true)"
if [[ -z "$latest_archive" ]]; then
  echo "[$TS] restore-test: SKIP (no backup archive yet)" >> "$LOG_FILE"
  exit 0
fi

if "${ROOT}/scripts/backup_restore_test.sh" --archive "$latest_archive" --restore-sample --sample-limit 30 >> "$LOG_FILE" 2>&1; then
  echo "[$TS] restore-test: PASS" >> "$LOG_FILE"
else
  echo "[$TS] restore-test: FAIL" >> "$LOG_FILE"
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JOB='20 3 1 * * cd "${HOME}/.openclaw/workspace" && ./scripts/restore_test_cron.sh'

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

crontab -l 2>/dev/null | grep -v 'scripts/restore_test_cron.sh' > "$TMP" || true
echo "$JOB" >> "$TMP"
crontab "$TMP"

echo "Installed monthly restore-test cron:"
echo "$JOB"
crontab -l | grep 'scripts/restore_test_cron.sh' || true

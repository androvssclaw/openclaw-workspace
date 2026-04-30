#!/usr/bin/env bash
set -euo pipefail
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
crontab -l 2>/dev/null | grep -v 'scripts/reminder_weekly_audit.sh' | grep -v 'scripts/weekly_digest.sh' > "$TMP" || true

echo '37 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/reminder_weekly_audit.sh >> ./state/reminder_audit_cron.log 2>&1' >> "$TMP"
echo '38 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/weekly_digest.sh >> ./state/weekly_digest_cron.log 2>&1' >> "$TMP"
crontab "$TMP"

echo "Installed reliability/report cron jobs:"
crontab -l | grep -E 'reminder_weekly_audit|weekly_digest' || true
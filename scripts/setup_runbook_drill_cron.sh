#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

crontab -l 2>/dev/null | grep -v 'scripts/runbook_drill.sh' | grep -v 'scripts/task_followup_cron.sh' | grep -v 'scripts/weekly_progress_review.sh' | grep -v 'scripts/slo_weekly_check.sh' > "$TMP" || true

# Monthly runbook drill
echo '40 6 1 * * cd "${HOME}/.openclaw/workspace" && ./scripts/runbook_drill.sh >> ./state/runbook_drill_cron.log 2>&1' >> "$TMP"
# Daily task follow-up (self-throttled to 24h in script)
echo '30 9 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/task_followup_cron.sh >> ./state/task_followup_cron.log 2>&1' >> "$TMP"
# Weekly progress review + SLO check (Monday)
echo '35 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/weekly_progress_review.sh >> ./state/weekly_progress_cron.log 2>&1' >> "$TMP"
echo '36 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/slo_weekly_check.sh >> ./state/slo_weekly_cron.log 2>&1' >> "$TMP"

crontab "$TMP"

echo "Installed cron jobs:"
crontab -l | grep -E 'runbook_drill|task_followup|weekly_progress_review|slo_weekly_check' || true
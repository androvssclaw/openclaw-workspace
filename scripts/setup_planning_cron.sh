#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

crontab -l 2>/dev/null |
  grep -v 'scripts/daily_ops_summary.sh' |
  grep -v 'scripts/daily_planning.sh' |
  grep -v 'scripts/weekly_ops_review.sh' > "$TMP" || true

# Daily operational and planning loop
# 06:10 UTC: create daily operational summary (includes incident snapshot)
echo '10 6 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/daily_ops_summary.sh >> ./state/daily_ops_summary_cron.log 2>&1' >> "$TMP"
# 06:20 UTC: prepare daily planning notes
echo '20 6 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/daily_planning.sh >> ./state/daily_planning_cron.log 2>&1' >> "$TMP"
# Monday 06:30 UTC: weekly review loop
echo '30 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/weekly_ops_review.sh >> ./state/weekly_ops_review_cron.log 2>&1' >> "$TMP"

crontab "$TMP"

echo "Installed planning/ops cron jobs:"
crontab -l | grep -E 'daily_ops_summary|daily_planning|weekly_ops_review' || true
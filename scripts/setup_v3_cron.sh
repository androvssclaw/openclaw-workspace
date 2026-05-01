#!/usr/bin/env bash
set -euo pipefail
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
crontab -l 2>/dev/null | grep -v 'scripts/memory_review.sh' | grep -v 'scripts/decision_log_weekly.sh' | grep -v 'scripts/kpi_weekly.sh' > "$TMP" || true

echo '39 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/memory_review.sh >> ./state/memory_review_cron.log 2>&1' >> "$TMP"
echo '40 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/decision_log_weekly.sh >> ./state/decision_log_cron.log 2>&1' >> "$TMP"
echo '41 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/kpi_weekly.sh >> ./state/kpi_weekly_cron.log 2>&1' >> "$TMP"
crontab "$TMP"

echo "Installed V3 cron jobs:"; crontab -l | grep -E 'memory_review|decision_log_weekly|kpi_weekly' || true
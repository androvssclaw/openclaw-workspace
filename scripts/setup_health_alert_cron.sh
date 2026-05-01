#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

crontab -l 2>/dev/null | grep -v 'scripts/health_alert_cron.sh' > "$TMP" || true

# Every 15 minutes: threshold-based health check + alert on status change
echo '*/15 * * * * cd "${HOME}/.openclaw/workspace" && ./scripts/health_alert_cron.sh >> ./state/health_alert_cron.log 2>&1' >> "$TMP"

crontab "$TMP"

echo "Installed health alert cron:"
crontab -l | grep 'scripts/health_alert_cron.sh' || true
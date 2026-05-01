#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-install}" # install|check|dry-run
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

read -r -d '' DESIRED <<'EOF' || true
*/15 * * * * cd "${HOME}/.openclaw/workspace" && ./scripts/health_alert_cron.sh >> ./state/health_alert_cron.log 2>&1
45 6 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/health_digest_daily.sh >> ./state/health_digest_daily.log 2>&1
10 6 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/daily_ops_summary.sh >> ./state/daily_ops_summary_cron.log 2>&1
20 6 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/daily_planning.sh >> ./state/daily_planning_cron.log 2>&1
30 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/weekly_ops_review.sh >> ./state/weekly_ops_review_cron.log 2>&1
35 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/weekly_progress_review.sh >> ./state/weekly_progress_review_cron.log 2>&1
36 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/slo_weekly_check.sh >> ./state/slo_weekly_check_cron.log 2>&1
37 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/reminder_weekly_audit.sh >> ./state/reminder_audit_cron.log 2>&1
38 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/weekly_digest.sh >> ./state/weekly_digest_cron.log 2>&1
39 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/memory_review.sh >> ./state/memory_review_cron.log 2>&1
40 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/decision_log_weekly.sh >> ./state/decision_log_cron.log 2>&1
41 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/kpi_weekly.sh >> ./state/kpi_weekly_cron.log 2>&1
42 6 * * 1 cd "${HOME}/.openclaw/workspace" && ./scripts/quality_trend_weekly.sh >> ./state/quality_trend_weekly_cron.log 2>&1
30 9 * * * cd "${HOME}/.openclaw/workspace" && ./scripts/task_followup_cron.sh >> ./state/task_followup_cron.log 2>&1
40 6 1 * * cd "${HOME}/.openclaw/workspace" && ./scripts/runbook_drill.sh >> ./state/runbook_drill_cron.log 2>&1
20 3 1 * * cd "${HOME}/.openclaw/workspace" && ./scripts/restore_test_cron.sh >> ./state/restore_test_cron.log 2>&1
EOF

managed_pattern='scripts/(health_alert_cron|health_digest_daily|daily_ops_summary|daily_planning|weekly_ops_review|weekly_progress_review|slo_weekly_check|reminder_weekly_audit|weekly_digest|memory_review|decision_log_weekly|kpi_weekly|quality_trend_weekly|task_followup_cron|runbook_drill|restore_test_cron)\.sh'

current="$(crontab -l 2>/dev/null || true)"

if [[ "$MODE" == "check" ]]; then
  missing=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if ! grep -Fqx "$line" <<< "$current"; then
      echo "MISSING: $line"
      missing=$((missing+1))
    fi
  done <<< "$DESIRED"

  if [[ $missing -eq 0 ]]; then
    echo "OK: V5 cron set is complete"
    exit 0
  fi
  echo "FAIL: missing entries=$missing"
  exit 1
fi

if [[ "$MODE" == "dry-run" ]]; then
  printf '%s\n' "$current" | grep -Ev "$managed_pattern" > "$TMP" || true
  printf '%s\n' "$DESIRED" >> "$TMP"
  awk 'NF{print} !NF{if(!blank){print}; blank=1; next} {blank=0}' "$TMP" > "${TMP}.clean"
  mv "${TMP}.clean" "$TMP"

  CUR="$(mktemp)"
  trap 'rm -f "$TMP" "$CUR"' EXIT
  printf '%s\n' "$current" > "$CUR"
  if diff -u "$CUR" "$TMP"; then
    echo "No cron changes needed."
  fi
  exit 0
fi

# install mode: keep unrelated entries, replace managed ones with desired set.
printf '%s\n' "$current" | grep -Ev "$managed_pattern" > "$TMP" || true
printf '%s\n' "$DESIRED" >> "$TMP"

# remove duplicate empty lines
awk 'NF{print} !NF{if(!blank){print}; blank=1; next} {blank=0}' "$TMP" > "${TMP}.clean"
mv "${TMP}.clean" "$TMP"

crontab "$TMP"
echo "Installed/updated V5 cron set."
crontab -l | grep -E "$managed_pattern" || true

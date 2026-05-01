# RUNBOOK QUICK ACTIONS

Короткие сценарии формата «если X — делай Y».

- Если **health = CRIT**:
  1) `./scripts/health_check_thresholds.sh`
  2) `./scripts/logs.sh 200`
  3) `./scripts/incident_report.sh 300`
  4) при подтверждении риска — rollback через `./scripts/rollback_helper.sh --to ORIG_HEAD`

- Если **много повторных CRIT-алертов**:
  1) проверить `CRIT_COOLDOWN_SECONDS` для `health_alert_cron.sh`
  2) сверить пороги в `scripts/health_check_thresholds.sh`
  3) смотреть daily digest (`scripts/health_digest_daily.sh`) по шуму

- Если **таски «зависают»**:
  1) `./scripts/task.sh next`
  2) `./scripts/task.sh edit <id> <p1|p2|p3> <YYYY-MM-DD> <work|home|errands>`
  3) `./scripts/focus.sh 5`

- Если **PR не создаётся/не обновляется**:
  1) `gh auth status`
  2) `./scripts/test_harness.sh`
  3) `./scripts/pr_sync.sh`

- Если **нужен безопасный weekly/monthly прогон**:
  1) `./scripts/production_hardening_dry_run.sh`
  2) исправить FAIL, повторить прогон до PASS=all

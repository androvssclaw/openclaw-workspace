# OpenClaw Roadmap (Next V6.3)

_Версия: 2026-05-01_

## 1) Quality trend recursion safety
- [x] Убрать вызов `test_harness` из fallback `quality_trend_weekly.sh`.
- [x] Использовать прямую lightweight-проверку (`health_check_thresholds`, `production_hardening_dry_run`, `ops_brief`).

## Done when
- `quality_trend_weekly --no-alert` не может рекурсивно вызвать сам себя через test harness.

# OpenClaw Roadmap (Next V4)

_Версия: 2026-05-01_

## 1) Production hardening
- [x] Dry-run цепочка weekly/monthly: `scripts/production_hardening_dry_run.sh`
- [x] Фиксы краевых кейсов cron/env/empty states (health alert + digest + dry-run guardrails)

## 2) Task UX 3.0
- [x] `task.sh ctx <id> <work|home|errands>`
- [x] `task.sh edit <id> ...` (prio/due/ctx)
- [x] `task.sh next` улучшен: просрочка + age (older task bias)

## 3) Alert tuning
- [x] Cooldown повторов CRIT (`CRIT_COOLDOWN_SECONDS`, default 3600)
- [x] Отдельный daily health digest (`scripts/health_digest_daily.sh`)

## 4) PR/Release flow
- [x] Автопроверка `test_harness` перед `git_auto_push_and_pr`
- [x] PR summary с изменениями и рисками в `pr_sync.sh`

## 5) Docs/Runbooks polish
- [x] Добавлен quick runbook `docs/RUNBOOK_QUICK_ACTIONS.md`
- [x] README актуализирован под ежедневные команды

## Status log
- 2026-05-01: V4 baseline implementation completed.

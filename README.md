# OpenClaw Workspace

_Актуально на 2026-04-30 22:20 UTC_

## 1) Назначение
Этот репозиторий — рабочий контур персонального OpenClaw-ассистента: задачи, напоминания, ops-автоматизация, мониторинг и runbooks.

## 2) Текущее состояние
- OpenClaw: `2026.4.27`
- Хост: Ubuntu 24.04 (VPS)
- Gateway: `127.0.0.1:18789` (loopback)
- Сервис: `openclaw-gateway.service` (systemd user, active)
- Канал: Telegram (active)
- Рабочая ветка: `bot/updates-init` (push в `main` запрещён)

## 3) Архитектура (кратко)
- **Интерфейс:** Telegram / Web UI
- **Оркестрация:** OpenClaw Gateway
- **Операционные скрипты:** `scripts/*.sh`
- **Состояние/артефакты:** `state/*`
- **Память:** `MEMORY.md` + `memory/YYYY-MM-DD.md`
- **Документация/регламенты:** `README.md`, `ROADMAP.md`, `GIT_WORKFLOW.md`, `VPN*.md`

## 4) Операционные команды

### 4.1 Задачи и продуктивность
- `./scripts/tasks.sh` — список задач
- `./scripts/task.sh add "..." [group]` — добавить задачу
- `./scripts/task.sh done <id|text>` — закрыть задачу
- `./scripts/task.sh prio <id> <p1|p2|p3>` — выставить приоритет
- `./scripts/task.sh due <id> <YYYY-MM-DD>` — выставить дедлайн
- `./scripts/task.sh next [work|home|errands]` — предложить следующую задачу с учетом контекста
- `./scripts/focus.sh [count]` — top-N фокус задач
- `./scripts/today.sh` — сводка дня (задачи + health + reminders)
- `./scripts/remind.sh <when> <message>` — одноразовое напоминание
- `./scripts/daily_planning.sh` — daily planning snapshot

### 4.2 Ops и наблюдаемость
- `./scripts/health.sh` — system + OpenClaw + VPN quick check
- `./scripts/health_check_thresholds.sh` — threshold check (OK/WARN/CRIT)
- `./scripts/logs.sh [lines]` — системные логи gateway
- `./scripts/incident_report.sh [lines]` — incident snapshot в markdown
- `./scripts/ops_brief.sh` — короткий ops-срез
- `./scripts/daily_ops_summary.sh` — daily ops summary в `state/`
- `./scripts/weekly_ops_review.sh` — weekly ops review
- `./scripts/ops_report.sh` — единый расширенный ops-report в `state/ops_report.txt`
- `./scripts/smoke_check.sh` — smoke-check ключевых команд
- `./scripts/slo_weekly_check.sh` — weekly SLO baseline check
- `./scripts/reminder_audit.sh` — проверка просроченных one-shot reminders
- `./scripts/reminder_weekly_audit.sh` — weekly audit reminders
- `./scripts/test_harness.sh` — мини test harness (PASS/FAIL)
- `./scripts/kpi_weekly.sh` — weekly KPI snapshot

### 4.3 Deploy и обслуживание
- `./scripts/deploy.sh --confirm DEPLOY` — safe deploy (только clean tree)
- `./scripts/deploy.sh --dry-run` — dry-run deploy проверки
- `./scripts/rollback_helper.sh --to ORIG_HEAD` — безопасный helper для отката
- `./scripts/cleanup.sh` — weekly cleanup (memory + scorecard + tasks)
- `./scripts/weekly_scorecard.sh` — weekly scorecard в `state/scorecard-YYYY-WW.md`
- `./scripts/weekly_digest.sh` — weekly digest (tasks + ops + risks + next actions)
- `./scripts/status_short.sh` — компактный status формат
- `./scripts/memory_review.sh` — weekly review memory/*.md
- `./scripts/decision_log_weekly.sh` — weekly decision log
- `./scripts/pr_sync.sh` — create/update PR для `bot/updates-init`
- `./scripts/git_auto_push_and_pr.sh "msg"` — commit+push+PR sync одним запуском
- `./scripts/runbook_drill.sh` — monthly runbook drill snapshot
- `./scripts/task_followup_cron.sh` — daily follow-up по открытым задачам (throttled)
- `./scripts/weekly_progress_review.sh` — weekly progress review с action items

### 4.4 Backup и восстановление
- `./scripts/backup_important.sh`
- `./scripts/backup_prune.sh`
- `./scripts/backup_gdrive_sync.sh`
- `./scripts/backup_restore_test.sh`
- `./scripts/restore_test_cron.sh`

### 4.5 VPN
- `./scripts/vpn_status.sh`
- `./scripts/vpn_health.sh`
- `./scripts/vpn_health_cron.sh`
- `./scripts/vpn_daily_summary.sh`
- Runbooks: `VPN.md`, `VPN_ANTI_BLOCK_RUNBOOK.md`, `VPN_ANTI_BLOCK_RUNBOOK_SHORT.md`

## 5) Cron-процессы
- Каждые 15 минут: `health_alert_cron.sh` (алерт в Telegram при смене статуса)
- Ежедневно 09:30 UTC: `task_followup_cron.sh`
- Ежедневно 06:10 UTC: `daily_ops_summary.sh`
- Ежедневно 06:20 UTC: `daily_planning.sh`
- Понедельник 06:30 UTC: `weekly_ops_review.sh`
- Понедельник 06:35 UTC: `weekly_progress_review.sh`
- Понедельник 06:36 UTC: `slo_weekly_check.sh`
- Понедельник 06:37 UTC: `reminder_weekly_audit.sh`
- Понедельник 06:38 UTC: `weekly_digest.sh`
- Понедельник 06:39 UTC: `memory_review.sh`
- Понедельник 06:40 UTC: `decision_log_weekly.sh`
- Понедельник 06:41 UTC: `kpi_weekly.sh`
- 1-е число месяца 06:40 UTC: `runbook_drill.sh`
- 1-е число месяца 03:20 UTC: `restore_test_cron.sh`
- VPN-monitoring: отдельные cron-задачи (`vpn_health_cron.sh`, `vpn_daily_summary.sh`)

## 6) Память и проактивность
- Долгая память: `MEMORY.md`
- Дневные заметки: `memory/YYYY-MM-DD.md`
- Playbook: `docs/PROACTIVE_PLAYBOOK.md`
- Heartbeat-checklist: `HEARTBEAT.md`
- Формат ответов команд: `docs/COMMAND_OUTPUT_STYLE.md`
- Troubleshooting FAQ: `docs/TROUBLESHOOTING_FAQ.md`

## 7) Git policy
- Ветка работы: `bot/updates-init`
- После коммита: автоматический push в `bot/updates-init`
- В `main` только через PR
- Auto-merge только docs-only (см. `GIT_WORKFLOW.md`)

## 8) Roadmap status
- `Ближайшие` — выполнено
- `Week 1` — выполнено
- `Week 2` — выполнено
- Backlog: выполнены пункты про память/проактивность и расширение команд
- `ROADMAP_NEXT` — выполнен
- `ROADMAP_NEXT_V2` — выполнен (полный проход)
- `ROADMAP_NEXT_V3` — выполнен (полный проход)

## 9) Быстрые примеры (до/после)
- Было: `./scripts/task.sh next`
- Стало: `./scripts/task.sh next work` (учет `ctx:work`, `p1..p3`, `due:YYYY-MM-DD`)

- Было: только `ops_brief`
- Стало: `ops_brief` + `ops_report` + `status_short` + weekly digest

## 10) Быстрые проверки
```bash
openclaw status
./scripts/health_check_thresholds.sh
./scripts/ops_brief.sh
./scripts/today.sh
```

# OpenClaw Workspace

_Актуально на 2026-04-30 21:30 UTC_

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
- `./scripts/task.sh next` — предложить следующую задачу
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

### 4.3 Deploy и обслуживание
- `./scripts/deploy.sh --confirm DEPLOY` — safe deploy (только clean tree)
- `./scripts/deploy.sh --dry-run` — dry-run deploy проверки
- `./scripts/cleanup.sh` — weekly cleanup (memory + scorecard + tasks)
- `./scripts/weekly_scorecard.sh` — weekly scorecard в `state/scorecard-YYYY-WW.md`

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
- Ежедневно 06:10 UTC: `daily_ops_summary.sh`
- Ежедневно 06:20 UTC: `daily_planning.sh`
- Понедельник 06:30 UTC: `weekly_ops_review.sh`
- 1-е число месяца 03:20 UTC: `restore_test_cron.sh`
- VPN-monitoring: отдельные cron-задачи (`vpn_health_cron.sh`, `vpn_daily_summary.sh`)

## 6) Память и проактивность
- Долгая память: `MEMORY.md`
- Дневные заметки: `memory/YYYY-MM-DD.md`
- Playbook: `docs/PROACTIVE_PLAYBOOK.md`
- Heartbeat-checklist: `HEARTBEAT.md`

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

Открытый пункт:
- Улучшение README как живого архитектурного документа (этот апдейт закрывает пункт)

## 9) Быстрые проверки
```bash
openclaw status
./scripts/health_check_thresholds.sh
./scripts/ops_brief.sh
./scripts/today.sh
```

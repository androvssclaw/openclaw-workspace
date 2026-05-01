# OpenClaw Roadmap

_Версия: 2026-04-29_

## Ближайшие

### 1) GitHub operational model
- [x] Выбрана модель отдельного bot-flow через ветку `bot/updates-init`
- [x] Даны права и настроен auto commit/push в рабочую ветку (без push в `main`)
- [x] Зафиксирована risk-based merge policy (auto-merge только docs-only)

### 2) Refine backup policy
- [x] Добавлен restore-test script: `scripts/backup_restore_test.sh`
- [x] Добавить регулярный cron restore-test (например, раз в месяц)

### 3) Улучшить observability
- [x] Добавлен `scripts/incident_report.sh` (symptom/impact/cause/actions)
- [x] Интегрировать incident-report в ежедневный/weekly operational loop

### 4) Рутина и личная продуктивность
- [x] Добавлен `scripts/memory_compact.sh` для сжатия долгосрочной памяти/решений
- [x] Reminders + task workflows + daily/weekly planning loop

---

## Week 1 — Стабильность + базовая польза

### 1) Платформа и стабильность
- [x] Обновить OpenClaw до актуальной версии
- [x] Прогнать `openclaw doctor --repair`
- [x] Зафиксировать стабильный runtime Node (LTS) для systemd
- [x] Проверить, что gateway и bot стабильно переживают рестарт

**Критерий готовности:**
- `openclaw status` без критичных проблем
- systemd сервис стабилен после reboot/logout
- Telegram канал отвечает стабильно

### 2) Польза ассистента в ежедневной работе
- [x] Довести команды задач (`/tasks`, `/task add`, `/task done`)
- [x] Добавить напоминания (`/remind`) через cron
- [x] Сделать короткую ежедневную сводку (опционально по запросу)

**Критерий готовности:**
- задачи добавляются/закрываются без ручного редактирования файлов
- напоминания приходят в нужное время

---

## Week 2 — Автоматизация + наблюдаемость

### 3) Автоматизация сервера
- [x] Добавить команды `/health` и `/logs`
- [x] Подготовить безопасный `/deploy` (с подтверждением)
- [x] Добавить базовые проверки диска/памяти/доступности сервисов

**Критерий готовности:**
- основные операционные действия выполняются одной командой
- есть понятная диагностика при проблемах

### 4) Мониторинг и алерты
- [x] Настроить периодические health-check
- [x] Настроить уведомления о проблемах в Telegram
- [x] Определить пороги тревог (disk, memory, uptime/service)

**Критерий готовности:**
- проблемы приходят проактивно, а не после ручной проверки

---

## Backlog (после Week 2)
- [x] Прокачка “мозга”: память, стиль, проактивность (базовый playbook + MEMORY.md + weekly scorecard)
- [x] Расширение команд под личные сценарии (focus/today/task next/ops brief/cleanup)
- [x] Улучшение README как живого архитектурного документа

---

## V4 — Stabilization + Product Mode (2026-05-01)
- [x] Production hardening: dry-run цепочка weekly/monthly + edge-case фиксы
- [x] Task UX 3.0: `ctx`, `edit`, smarter `next` (overdue + age)
- [x] Alert tuning: CRIT cooldown + daily health digest
- [x] PR/Release flow: test_harness gate + PR summary/risk hints
- [x] Docs/Runbooks polish: quick runbook + README sync

## V5 — Reliability Envelope + Task Guardrails (2026-05-01)
- [x] Единая idempotent установка/проверка cron-набора (`setup_v5_cron.sh`)
- [x] Task lint + safe autofix (`task.sh lint --fix`)
- [x] Release evidence pack + integration в PR summary

## V6 — Quality Gates + Evidence Visibility (2026-05-01)
- [x] `task.sh lint` включен в `test_harness`
- [x] Release evidence summary добавлен в `weekly_digest`
- [x] `setup_v5_cron.sh dry-run` (diff preview)

## V6.1 — Quality Trend Monitoring (2026-05-01)
- [x] Weekly quality trend report (`quality_trend_weekly.sh` + history)
- [x] Quality trend section в weekly digest
- [x] Alert only on regression (degradation-only notifications)

## V6.3 — Quality Trend Safety Hotfix (2026-05-01)
- [x] Убрана потенциальная рекурсия `quality_trend_weekly` ↔ `test_harness`
- [x] Fallback quality checks переведены на прямые lightweight-команды

## V6.4 — Cron Drift Guard (2026-05-01)
- [x] Добавлен `cron_drift_guard.sh` (дрейф/восстановление только по смене состояния)
- [x] Подключен ежедневный запуск через `setup_v5_cron.sh`

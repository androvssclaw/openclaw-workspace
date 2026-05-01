# OpenClaw Roadmap (Next V6.5)

_Версия: 2026-05-01_

## 1) Drift auto-heal mode
- [x] Добавить `--auto-heal` в `cron_drift_guard.sh`.
- [x] При DRIFT пробовать `setup_v5_cron.sh install` до отправки CRIT-алерта.

## 2) Heal cooldown
- [x] Добавить cooldown на heal-попытки (default: 6h, `HEAL_COOLDOWN_SECONDS`).

## 3) Weekly visibility
- [x] Добавить в `weekly_digest.sh` метрики за 7 дней:
  - drift incidents
  - auto-heal success
  - auto-heal failed

## Done when
- Drift сначала лечится автоматически.
- Повторные heal-попытки ограничены cooldown.
- Digest показывает тренд drift/heal без ручного парсинга логов.

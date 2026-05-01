# OpenClaw Roadmap (Next V6)

_Версия: 2026-05-01_

## 1) Mandatory task quality gate
- [x] Добавить `task.sh lint` в `scripts/test_harness.sh`.

## 2) Evidence visibility in weekly operations
- [x] Добавить summary release evidence в `scripts/weekly_digest.sh`.

## 3) Safe cron changes preview
- [x] Добавить режим `dry-run` в `scripts/setup_v5_cron.sh` с diff текущего и целевого crontab.

## Done when
- `test_harness` падает на проблемах task metadata.
- Weekly digest содержит последний evidence snapshot.
- Cron-изменения можно просмотреть до применения.

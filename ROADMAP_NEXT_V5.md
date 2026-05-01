# OpenClaw Roadmap (Next V5)

_Версия: 2026-05-01_

## 1) Cron reliability envelope
- [ ] Добавить `setup_v5_cron.sh` для установки/проверки всех ключевых cron job'ов одним запуском.
- [ ] Добавить верификацию расписаний + idempotent update (не плодить дубли).

## 2) Task quality guardrails
- [ ] Добавить `task.sh lint` (проверка дубликатов, битых `due:`, невалидных `ctx:`).
- [ ] Добавить автопочинку безопасных кейсов (`--fix`) без изменения смысла задач.

## 3) Release evidence pack
- [ ] Добавить `scripts/release_evidence.sh` (test_harness + hardening dry-run + ops краткий срез в один артефакт).
- [ ] Подключить к PR summary ссылку/вставку evidence блока.

## Done when
- Один запуск поднимает/валидирует cron-контур V5 без ручной правки.
- `task.sh lint` стабильно ловит проблемы в TASKS.md до релиза.
- Каждый PR имеет компактный evidence-блок для быстрого merge-решения.

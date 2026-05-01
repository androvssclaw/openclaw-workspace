# OpenClaw Roadmap (Next V6.4)

_Версия: 2026-05-01_

## 1) Cron drift monitoring
- [x] Добавить `scripts/cron_drift_guard.sh`.
- [x] Alert only on state change (DRIFT detected / DRIFT resolved).

## 2) Cron integration
- [x] Включить daily запуск в `setup_v5_cron.sh`.

## Done when
- При расхождении cron-контура приходит один сигнал о проблеме.
- При восстановлении приходит один сигнал о восстановлении.

# Troubleshooting FAQ

## 1) Пришёл CRIT, но сервис жив
Проверь `state/health_alert.log` и `scripts/health_check_thresholds.sh`.
Возможен transient/cron-env issue; алерты теперь с anti-noise streak logic.

## 2) Почему `deploy.sh` отказал?
Скорее всего dirty git tree или нет `--confirm DEPLOY`.

## 3) Почему reminder не сработал?
Проверь `openclaw cron list --json` и формат времени в `scripts/remind.sh`.

## 4) Что делать при проблеме с gateway?
1. `openclaw status`
2. `./scripts/health_check_thresholds.sh`
3. `./scripts/logs.sh 200`
4. `./scripts/incident_report.sh`

## 5) Где смотреть weekly-артефакты?
В `state/`: `weekly-progress-*`, `slo-weekly-*`, `scorecard-*`, `runbook-drill-*`.

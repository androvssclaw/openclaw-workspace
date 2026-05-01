# OpenClaw Roadmap (Next V6.1)

_Версия: 2026-05-01_

## 1) Quality trend report
- [x] Добавить `scripts/quality_trend_weekly.sh` (score по evidence + weekly history).

## 2) Weekly digest integration
- [x] Добавить quality trend section в `scripts/weekly_digest.sh`.

## 3) Alert only on regression
- [x] Алертить только при деградации score относительно прошлого weekly snapshot.

## Done when
- Есть weekly trend артефакт в `state/quality-trend-YYYY-WW.md`.
- Weekly digest показывает score и previous baseline.
- Нет шумных повторов: alert только на регрессию.

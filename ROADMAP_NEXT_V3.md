# OpenClaw Roadmap (Next V3)

_Версия: 2026-04-30_

## 1) Auto-PR flow
- [x] Автосоздание/обновление PR после push в `bot/updates-init`
- [x] PR шаблон с рисками и чеклистом

**Done when:** PR создается/обновляется одной командой, есть единый шаблон.

## 2) Тестовый контур скриптов
- [x] Mini test harness для `scripts/*`
- [x] Проверка exit codes и базовых контрактов вывода

**Done when:** один запуск дает PASS/FAIL по ключевым сценариям.

## 3) Memory quality
- [x] Авто-ревью `memory/*.md` → weekly memory-review артефакт
- [x] Weekly decision log

**Done when:** есть повторяемый memory-review pipeline и weekly артефакт.

## 4) Alert quality 2.0
- [x] Severity routing (WARN тихо, CRIT сразу)
- [x] Suppress-window ночью (кроме CRIT)

**Done when:** меньше шума, CRIT доставляется всегда.

## 5) Operational KPIs
- [x] Добавить KPI блок в weekly digest (uptime trend, noisy alerts, task throughput)

**Done when:** weekly digest содержит 3-5 стабильных KPI.

---

## Status log
- 2026-04-30: Roadmap V3 created.
- 2026-04-30: Полный проход выполнен (PR flow, test harness, memory pipeline, alert routing, KPI digest).

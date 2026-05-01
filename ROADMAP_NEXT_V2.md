# OpenClaw Roadmap (Next V2)

_Версия: 2026-04-30_

## May Week 1 — Task Intelligence
- [x] Добавить теги контекста задач (`work/home/errands`) и учитывать их в `task next`
- [x] Добавить `task.sh due <id> <YYYY-MM-DD>`
- [x] Добавить `task.sh prio <id> <p1|p2|p3>`

**Критерий готовности:**
- приоритизация редактируется командами, `task next` учитывает все метаданные

## May Week 2 — Reminder Reliability
- [x] Добавить проверку просроченных one-shot reminder jobs
- [x] Добавить weekly audit reminders с коротким отчётом
- [x] Свести шум follow-up сообщений к 1 полезному сообщению/сутки

**Критерий готовности:**
- reminders прозрачны и предсказуемы, без лишнего шума

## May Week 3 — Ops Safety
- [x] Добавить preflight для deploy: проверка backup freshness
- [x] Добавить post-deploy incident auto-snapshot
- [x] Добавить ручной rollback helper script

**Критерий готовности:**
- deploy flow покрывает pre/post проверки и быстрый откат

## May Week 4 — Reporting & UX
- [x] Добавить `weekly_digest.sh` (tasks + ops + risks + next actions)
- [x] Добавить компактный `/status_short` формат
- [x] Обновить README с примерами “до/после” по новым командам

**Критерий готовности:**
- есть единый weekly digest и быстрые форматы ответов

---

## First execution queue (can do now)
1. ✅ Реализовано `task.sh due` и `task.sh prio`
2. ✅ Улучшен `task next` с учетом context tags
3. ✅ Добавлен `weekly_digest.sh`

## Status log
- 2026-04-30: Выполнен полный проход по Week 1-4 (task intelligence, reminder reliability, ops safety, reporting/UX).

# Operations Autonomy Plan

_Updated: 2026-04-29_

## Goal
Сделать OpenClaw более автономным в 3 направлениях:
1. Проверяемое восстановление из backup
2. Быстрые инцидент-отчёты
3. Фиксация долгосрочной памяти/решений

## 1) Backup restore-test
- Script: `scripts/backup_restore_test.sh`
- Cron wrapper: `scripts/restore_test_cron.sh`
- Cron setup (idempotent): `scripts/setup_restore_test_cron.sh`
- Default: dry-run validation (checksum + tar readability + manifest)
- Optional: `--restore-sample` для пробного извлечения части архива во временный каталог
- Artifact: `~/backups/openclaw/restore-tests/restore-test-*.txt`
- History log: `state/backup_restore_test_history.log`

Recommended cadence:
- monthly restore-test via cron (1st day, 03:20 UTC)

## 2) Observability v2
- Script: `scripts/incident_report.sh [lines]`
- Severity model: `OK | WARN | CRITICAL`
- Threshold env: `DISK_WARN_PCT` (default 80), `DISK_CRIT_PCT` (default 90)
- Output: `state/incidents/incident-*.md`
- Формат:
  - Symptom
  - Impact
  - Probable cause
  - Recommended actions
  - Log excerpt

Use cases:
- quick triage before escalation
- status updates without dumping raw logs

## 3) Long-term memory compaction
- Script: `scripts/memory_compact.sh`
- Input: ROADMAP.md + TASKS.md + README.md
- Output:
  - `state/memory_compact/memory-compact-YYYY-MM-DD.md`
  - `state/memory_compact/latest.md`

What it does:
- фиксирует стабильные решения
- сжимает текущий фокус из roadmap
- сохраняет snapshot open tasks
- формирует next actions

## Guardrails
- No direct push to `main`
- PR-first workflow
- Auto-merge only for docs-only PRs
- Risky file changes require manual review

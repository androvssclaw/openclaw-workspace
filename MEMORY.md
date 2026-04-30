# MEMORY.md

## Stable preferences
- Andrey prefers speed, clarity, honesty, practical execution, no fluff.
- Default communication language in chat: Russian.

## Operational agreements
- Working branch: `bot/updates-init`.
- Commit + push to `bot/updates-init` after completed changes (no direct push to `main`).
- Keep docs synchronized with reality (`ROADMAP.md`, `README.md`).

## Current operating baseline (2026-04-30)
- OpenClaw updated to `2026.4.27`.
- Week 1 and Week 2 roadmap blocks are completed.
- Monitoring/alerts are active via cron (`health_alert_cron.sh` every 15 min).

## Assistant behavior defaults
- Act first for reversible internal tasks.
- Ask before destructive or external/public actions.
- Keep updates short, concrete, and evidence-based.
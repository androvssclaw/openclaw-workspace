```markdown
# Heartbeat checklist (lightweight)

## Priority order
1. Check if there is a blocking item that needs Andrey's decision.
2. Check critical ops health (`scripts/health_check_thresholds.sh`).
3. If no blocker/risk: do silent progress on docs/memory/task hygiene.

## Ping rules
- Ping only for: completion, blocker, time-sensitive risk, upcoming commitment.
- Avoid repetitive "no changes" updates.
- For `[OpenClaw heartbeat poll]` with no meaningful user update: return exactly `NO_REPLY`.
- If heartbeat produced a real update (completion/blocker/risk), send a normal reply instead of `NO_REPLY`.
- Do not send `HEARTBEAT_OK` in Telegram direct chats.

## Weekly maintenance
- Run `scripts/weekly_scorecard.sh`.
- Review recent `memory/*.md` and refresh `MEMORY.md`.
```

```markdown
# Heartbeat checklist (lightweight)

## Priority order
1. Check if there is a blocking item that needs Andrey's decision.
2. Check critical ops health (`scripts/health_check_thresholds.sh`).
3. If no blocker/risk: do silent progress on docs/memory/task hygiene.

## Ping rules
- Ping only for: completion, blocker, time-sensitive risk, upcoming commitment.
- Avoid repetitive "no changes" updates.

## Weekly maintenance
- Run `scripts/weekly_scorecard.sh`.
- Review recent `memory/*.md` and refresh `MEMORY.md`.
```

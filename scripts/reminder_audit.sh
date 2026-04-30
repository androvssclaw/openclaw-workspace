#!/usr/bin/env bash
set -euo pipefail

json="$(openclaw cron list --json 2>/dev/null || true)"
if [[ -z "$json" ]]; then
  echo "WARN: cannot read cron jobs"
  exit 1
fi

python3 - "$json" <<'PY'
import json,sys,datetime
raw=sys.argv[1]
obj=json.loads(raw)
jobs=obj.get('jobs',[]) if isinstance(obj,dict) else (obj if isinstance(obj,list) else [])
now=datetime.datetime.now(datetime.timezone.utc)
overdue=[]
oneshot=0
for j in jobs:
    s=j.get('schedule',{})
    if s.get('kind')!='at':
        continue
    oneshot+=1
    at=s.get('at')
    if not at:
        continue
    try:
        dt=datetime.datetime.fromisoformat(at.replace('Z','+00:00'))
        if dt < now and j.get('enabled',True):
            overdue.append((j.get('jobId') or j.get('id') or '-', j.get('name','(no-name)'), at))
    except Exception:
        pass

print(f"One-shot jobs: {oneshot}")
if overdue:
    print(f"Overdue enabled jobs: {len(overdue)}")
    for jid,name,at in overdue[:10]:
        print(f"- {jid} | {name} | {at}")
    sys.exit(2)
else:
    print("Overdue enabled jobs: 0")
PY
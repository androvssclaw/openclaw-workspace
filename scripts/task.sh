#!/usr/bin/env bash
set -euo pipefail

TASKS_FILE="${TASKS_FILE:-./TASKS.md}"

ensure_tasks_file() {
  if [[ ! -f "$TASKS_FILE" ]]; then
    cat > "$TASKS_FILE" <<'EOF'
# Tasks

## Open Tasks

### OpenClaw Project
- [ ] #1

## Closed Tasks

### OpenClaw Project
- [x] #0
EOF
    echo "Создал $TASKS_FILE"
  fi
}

usage() {
  cat <<'EOF'
Использование:
  ./scripts/task.sh add "Текст задачи" ["OpenClaw Project"|"Personal"|"VPN"]
  ./scripts/task.sh addp "Текст задачи"
  ./scripts/task.sh addm "Текст задачи"
  ./scripts/task.sh prio <id> <p1|p2|p3>
  ./scripts/task.sh due <id> <YYYY-MM-DD>
  ./scripts/task.sh ctx <id> <work|home|errands>
  ./scripts/task.sh edit <id> [p1|p2|p3] [YYYY-MM-DD] [work|home|errands]
  ./scripts/task.sh done <ID_задачи_или_номер_по_списку_или_часть_текста>
  ./scripts/task.sh next [work|home|errands]
  ./scripts/task.sh lint [--fix]
  ./scripts/task.sh list

Примеры:
  ./scripts/task.sh add "Купить домен" "OpenClaw Project"
  ./scripts/task.sh addp "Проверить логи"
  ./scripts/task.sh addm "Позвонить маме"
  ./scripts/task.sh prio 12 p1
  ./scripts/task.sh due 12 2026-05-07
  ./scripts/task.sh ctx 12 work
  ./scripts/task.sh edit 12 p1 2026-05-07 work
  ./scripts/task.sh done 23
  ./scripts/task.sh done "DNS"
  ./scripts/task.sh next work
  ./scripts/task.sh lint --fix
EOF
}

next_task() {
  local ctx="${1:-}"
  local line
  line="$(python3 - "$TASKS_FILE" "$ctx" <<'PY'
import re,sys,datetime
from pathlib import Path

path=Path(sys.argv[1])
ctx=(sys.argv[2] or '').strip().lower()
if not path.exists():
    print("")
    raise SystemExit(0)

today=datetime.date.today()
open_section=False
candidates=[]

for raw in path.read_text(encoding='utf-8').splitlines():
    s=raw.strip()
    if s=="## Open Tasks":
        open_section=True; continue
    if s=="## Closed Tasks":
        open_section=False; continue
    if not open_section or not raw.startswith("- [ ]"):
        continue

    text=raw[len("- [ ] "):]
    p=3
    m=re.search(r'\bp([1-3])\b', text, re.I)
    if m: p=int(m.group(1))

    due_days=99999
    d=re.search(r'\bdue:(\d{4}-\d{2}-\d{2})\b', text)
    if d:
        try:
            dd=datetime.date.fromisoformat(d.group(1))
            due_days=(dd-today).days
        except Exception:
            pass

    c=""
    cm=re.search(r'\bctx:(work|home|errands)\b', text, re.I)
    if cm:
      c=cm.group(1).lower()

    ctx_penalty=0
    if ctx:
      ctx_penalty = 0 if c==ctx else 1

    overdue_boost = -20 if due_days < 0 else 0
    due_rank = due_days if due_days != 99999 else 36500
    id_match=re.search(r'#(\d+)', text)
    task_id=int(id_match.group(1)) if id_match else 999999
    age_rank=task_id

    candidates.append((ctx_penalty, p + overdue_boost, due_rank, age_rank, text))

if not candidates:
    print("")
else:
    candidates.sort(key=lambda x:(x[0], x[1], x[2], x[3]))
    print(candidates[0][4])
PY
)"

  if [[ -z "$line" ]]; then
    echo "Открытых задач нет 🎉"
    return 0
  fi

  echo "Следующая задача: $line"
}

set_priority() {
  local id="$1"
  local prio="$2"
  if ! [[ "$prio" =~ ^p[1-3]$ ]]; then
    echo "Ошибка: prio должен быть p1|p2|p3"
    exit 1
  fi
  python3 - "$TASKS_FILE" "$id" "$prio" <<'PY'
import re,sys
from pathlib import Path
path=Path(sys.argv[1]); tid=sys.argv[2]; pr=sys.argv[3]
lines=path.read_text(encoding='utf-8').splitlines()
done=False
for i,l in enumerate(lines):
    if re.search(rf'(^- \[ \] #?{re.escape(tid)}\b)|(#'+re.escape(tid)+r'\b)', l):
        if l.startswith('- [ ]') and re.search(rf'#{re.escape(tid)}\b', l):
            l=re.sub(r'\bp[1-3]\b','',l)
            l=re.sub(r'\s+',' ',l).rstrip()
            lines[i]=f"{l} {pr}".rstrip()
            done=True
            break
if not done:
    print(f"Ошибка: open задача #{tid} не найдена")
    raise SystemExit(1)
path.write_text("\n".join(lines).rstrip()+"\n",encoding='utf-8')
print(f"Обновил приоритет: #{tid} -> {pr}")
PY
}

set_due() {
  local id="$1"
  local due="$2"
  if ! [[ "$due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "Ошибка: due должен быть в формате YYYY-MM-DD"
    exit 1
  fi
  python3 - "$TASKS_FILE" "$id" "$due" <<'PY'
import re,sys,datetime
from pathlib import Path
path=Path(sys.argv[1]); tid=sys.argv[2]; due=sys.argv[3]
datetime.date.fromisoformat(due)
lines=path.read_text(encoding='utf-8').splitlines()
done=False
for i,l in enumerate(lines):
    if l.startswith('- [ ]') and re.search(rf'#{re.escape(tid)}\b', l):
        l=re.sub(r'\bdue:\d{4}-\d{2}-\d{2}\b','',l)
        l=re.sub(r'\s+',' ',l).rstrip()
        lines[i]=f"{l} due:{due}".rstrip()
        done=True
        break
if not done:
    print(f"Ошибка: open задача #{tid} не найдена")
    raise SystemExit(1)
path.write_text("\n".join(lines).rstrip()+"\n",encoding='utf-8')
print(f"Обновил дедлайн: #{tid} -> due:{due}")
PY
}

set_ctx() {
  local id="$1"
  local ctx="$2"
  if ! [[ "$ctx" =~ ^(work|home|errands)$ ]]; then
    echo "Ошибка: ctx должен быть work|home|errands"
    exit 1
  fi
  python3 - "$TASKS_FILE" "$id" "$ctx" <<'PY'
import re,sys
from pathlib import Path
path=Path(sys.argv[1]); tid=sys.argv[2]; ctx=sys.argv[3]
lines=path.read_text(encoding='utf-8').splitlines()
done=False
for i,l in enumerate(lines):
    if l.startswith('- [ ]') and re.search(rf'#{re.escape(tid)}\b', l):
        l=re.sub(r'\bctx:(work|home|errands)\b','',l, flags=re.I)
        l=re.sub(r'\s+',' ',l).rstrip()
        lines[i]=f"{l} ctx:{ctx}".rstrip()
        done=True
        break
if not done:
    print(f"Ошибка: open задача #{tid} не найдена")
    raise SystemExit(1)
path.write_text("\n".join(lines).rstrip()+"\n",encoding='utf-8')
print(f"Обновил контекст: #{tid} -> ctx:{ctx}")
PY
}

edit_task() {
  local id="$1"; shift
  local arg
  local pr="" due="" ctx=""
  for arg in "$@"; do
    if [[ "$arg" =~ ^p[1-3]$ ]]; then
      pr="$arg"
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      due="$arg"
    elif [[ "$arg" =~ ^(work|home|errands)$ ]]; then
      ctx="$arg"
    else
      echo "Ошибка: неизвестный параметр edit: $arg"
      exit 1
    fi
  done
  [[ -n "$pr" ]] && set_priority "$id" "$pr"
  [[ -n "$due" ]] && set_due "$id" "$due"
  [[ -n "$ctx" ]] && set_ctx "$id" "$ctx"
  if [[ -z "$pr$due$ctx" ]]; then
    echo "Ошибка: edit требует хотя бы один параметр: p1|p2|p3, YYYY-MM-DD, work|home|errands"
    exit 1
  fi
}

lint_tasks() {
  local fix="${1:-}"
  python3 - "$TASKS_FILE" "$fix" <<'PY'
import re,sys,datetime
from pathlib import Path

path=Path(sys.argv[1])
fix=(sys.argv[2] == '--fix')
lines=path.read_text(encoding='utf-8').splitlines()
seen={}
issues=0
changed=False

def normalize_text(s:str)->str:
    s=re.sub(r'\bp[1-3]\b','',s,flags=re.I)
    s=re.sub(r'\bdue:[^\s]+\b','',s,flags=re.I)
    s=re.sub(r'\bctx:[^\s]+\b','',s,flags=re.I)
    s=re.sub(r'\s+',' ',s).strip().lower()
    return s

for i,l in enumerate(lines):
    if not l.startswith('- [ ]'):
        continue
    body=l[len('- [ ] '):]

    due_tags=re.findall(r'\bdue:([^\s]+)\b', body, flags=re.I)
    ctx_tags=re.findall(r'\bctx:([^\s]+)\b', body, flags=re.I)

    valid_due=[]
    bad_due=[]
    for d in due_tags:
        try:
            datetime.date.fromisoformat(d)
            valid_due.append(d)
        except Exception:
            bad_due.append(d)

    valid_ctx=[c.lower() for c in ctx_tags if c.lower() in ('work','home','errands')]
    bad_ctx=[c for c in ctx_tags if c.lower() not in ('work','home','errands')]

    if len(due_tags) > 1:
        issues += 1
        print(f"ISSUE line {i+1}: duplicate due tags")
    if bad_due:
        issues += 1
        print(f"ISSUE line {i+1}: invalid due tags: {', '.join(bad_due)}")
    if len(ctx_tags) > 1:
        issues += 1
        print(f"ISSUE line {i+1}: duplicate ctx tags")
    if bad_ctx:
        issues += 1
        print(f"ISSUE line {i+1}: invalid ctx tags: {', '.join(bad_ctx)}")

    key=normalize_text(body)
    if key:
        if key in seen:
            issues += 1
            print(f"ISSUE line {i+1}: possible duplicate of line {seen[key]}")
        else:
            seen[key]=i+1

    if fix and (len(due_tags)>1 or bad_due or len(ctx_tags)>1 or bad_ctx):
        base=re.sub(r'\bdue:[^\s]+\b','',body,flags=re.I)
        base=re.sub(r'\bctx:[^\s]+\b','',base,flags=re.I)
        base=re.sub(r'\s+',' ',base).strip()
        if valid_due:
            base=f"{base} due:{valid_due[-1]}".strip()
        if valid_ctx:
            base=f"{base} ctx:{valid_ctx[-1]}".strip()
        lines[i]=f"- [ ] {base}"
        changed=True

if fix and changed:
    path.write_text("\n".join(lines).rstrip()+"\n",encoding='utf-8')
    print("FIX: applied safe normalization for due/ctx tags")

if issues == 0:
    print("OK: no task lint issues")
    raise SystemExit(0)
else:
    print(f"Found issues: {issues}")
    raise SystemExit(1)
PY
}

normalize_group() {
  local g="${1,,}"
  case "$g" in
    openclaw|project|"openclaw project") echo "OpenClaw Project" ;;
    personal|my|mine|личное) echo "Personal" ;;
    *) echo "$1" ;;
  esac
}

resolve_target() {
  local raw="${1:-}"
  local group

  if [[ -z "$raw" ]]; then
    echo "OpenClaw Project"
    return
  fi

  if [[ "$raw" == */* ]]; then
    group="$(normalize_group "${raw%%/*}")"
  else
    group="$(normalize_group "$raw")"
  fi

  echo "$group"
}

reorganize_tasks_file() {
  python3 - "$TASKS_FILE" <<'PY'
import re
import sys
from collections import OrderedDict
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()

preferred = ["Personal", "OpenClaw Project", "VPN"]
open_tasks = OrderedDict()
closed_tasks = OrderedDict()
current_group = "OpenClaw Project"

for ln in lines:
    if ln.startswith("### "):
        current_group = ln[4:].strip()
        continue
    if re.match(r"^- \[[ xX]\]", ln):
        target = closed_tasks if re.match(r"^- \[[xX]\]", ln) else open_tasks
        target.setdefault(current_group, []).append(ln)

def group_order(d):
    existing = list(d.keys())
    ordered = [g for g in preferred if g in d]
    ordered.extend([g for g in existing if g not in ordered])
    return ordered

out = ["# Tasks", "", "## Open Tasks", ""]
for g in group_order(open_tasks):
    out.append(f"### {g}")
    out.extend(open_tasks[g])
    out.append("")

out.append("## Closed Tasks")
out.append("")
for g in group_order(closed_tasks):
    out.append(f"### {g}")
    out.extend(closed_tasks[g])
    out.append("")

path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY

  reorganize_tasks_file
}

add_task() {
  local task_text="$1"
  local target="${2:-}"
  local group

  group="$(resolve_target "$target")"

  python3 - "$TASKS_FILE" "$group" "$task_text" <<'PY'
import sys
import re
from pathlib import Path

path = Path(sys.argv[1])
group = sys.argv[2]
task = sys.argv[3]

text = path.read_text(encoding="utf-8")
lines = text.splitlines()

open_h = "## Open Tasks"
closed_h = "## Closed Tasks"
group_h = f"### {group}"

max_id = 0
for ln in lines:
    m = re.search(r"#(\d+)", ln)
    if m:
        max_id = max(max_id, int(m.group(1)))

task_line = f"- [ ] #{max_id + 1} {task}"

try:
    o_start = next(i for i, ln in enumerate(lines) if ln.strip() == open_h)
except StopIteration:
    if lines and lines[-1].strip() != "":
        lines.append("")
    lines.extend([open_h, "", group_h, task_line, "", closed_h])
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    print(f"Добавил: {task} (раздел: {group}, id: {max_id + 1})")
    sys.exit(0)

try:
    c_start = next(i for i, ln in enumerate(lines) if ln.strip() == closed_h)
except StopIteration:
    c_start = len(lines)

g_start = None
for i in range(o_start + 1, c_start):
    if lines[i].strip() == group_h:
        g_start = i
        break

if g_start is None:
    insert_at = c_start
    while insert_at > o_start and lines[insert_at - 1].strip() == "":
        insert_at -= 1
    lines[insert_at:insert_at] = ["", group_h, task_line]
else:
    insert_at = g_start + 1
    while insert_at < c_start and not lines[insert_at].startswith("### "):
        insert_at += 1
    lines.insert(insert_at, task_line)

path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
print(f"Добавил: {task} (раздел: {group}, id: {max_id + 1})")
PY
}

done_by_index() {
  local idx="$1"
  local tmp
  tmp="$(mktemp)"

  if ! awk -v idx="$idx" '
    BEGIN { c=0; changed=0; matchedById=0 }

    /^- \[[ xX]\]/ {
      c++
      byId = ($0 ~ ("#" idx "([[:space:]]|$)"))
      if (byId || (!matchedById && c == idx)) {
        if (byId) matchedById=1
        if ($0 ~ /^- \[[xX]\]/) {
          print $0
        } else {
          sub(/^- \[ \]/, "- [x]")
          changed=1
          print $0
        }
        next
      }
    }

    { print $0 }

    END {
      if (!matchedById && c < idx) exit 2
      if (!changed) exit 3
    }
  ' "$TASKS_FILE" > "$tmp"; then
    local code=$?
    rm -f "$tmp"
    if [[ $code -eq 2 ]]; then
      echo "Ошибка: задачи с номером $idx нет"
    else
      echo "Задача #$idx уже отмечена как выполненная"
    fi
    exit 1
  fi

  mv "$tmp" "$TASKS_FILE"
  reorganize_tasks_file
  echo "Отметил выполненной задачу #$idx"
}

done_by_text() {
  local query="$1"
  local tmp
  tmp="$(mktemp)"

  if ! awk -v q="$query" '
    BEGIN { changed=0; found=0; ql=tolower(q) }

    /^- \[[ xX]\]/ {
      if (!found && index(tolower($0), ql) > 0) {
        found=1
        if ($0 ~ /^- \[[xX]\]/) {
          print $0
        } else {
          sub(/^- \[ \]/, "- [x]")
          changed=1
          print $0
        }
        next
      }
    }

    { print $0 }

    END {
      if (!found) exit 2
      if (!changed) exit 3
    }
  ' "$TASKS_FILE" > "$tmp"; then
    local code=$?
    rm -f "$tmp"
    if [[ $code -eq 2 ]]; then
      echo "Ошибка: задача с текстом '$query' не найдена"
    else
      echo "Задача '$query' уже отмечена как выполненная"
    fi
    exit 1
  fi

  mv "$tmp" "$TASKS_FILE"
  reorganize_tasks_file
  echo "Отметил выполненной: $query"
}

main() {
  local cmd="${1:-}"
  ensure_tasks_file

  case "$cmd" in
    add)
      local text="${2:-}"
      local path="${3:-}"
      if [[ -z "$text" ]]; then
        usage
        exit 1
      fi
      add_task "$text" "$path"
      ;;
    addp)
      local text="${2:-}"
      if [[ -z "$text" ]]; then
        usage
        exit 1
      fi
      add_task "$text" "OpenClaw Project"
      ;;
    addm)
      local text="${2:-}"
      if [[ -z "$text" ]]; then
        usage
        exit 1
      fi
      add_task "$text" "Personal"
      ;;
    done)
      local target="${2:-}"
      if [[ -z "$target" ]]; then
        usage
        exit 1
      fi
      if [[ "$target" =~ ^[0-9]+$ ]]; then
        done_by_index "$target"
      else
        done_by_text "$target"
      fi
      ;;
    prio)
      local id="${2:-}"
      local pr="${3:-}"
      [[ -z "$id" || -z "$pr" ]] && { usage; exit 1; }
      set_priority "$id" "$pr"
      ;;
    due)
      local id="${2:-}"
      local dd="${3:-}"
      [[ -z "$id" || -z "$dd" ]] && { usage; exit 1; }
      set_due "$id" "$dd"
      ;;
    ctx)
      local id="${2:-}"
      local cx="${3:-}"
      [[ -z "$id" || -z "$cx" ]] && { usage; exit 1; }
      set_ctx "$id" "$cx"
      ;;
    edit)
      local id="${2:-}"
      shift 2 || true
      [[ -z "$id" ]] && { usage; exit 1; }
      edit_task "$id" "$@"
      ;;
    next)
      next_task "${2:-}"
      ;;
    lint)
      lint_tasks "${2:-}"
      ;;
    list|"")
      ./scripts/tasks.sh
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"

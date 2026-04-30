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
  ./scripts/task.sh done <ID_задачи_или_номер_по_списку_или_часть_текста>
  ./scripts/task.sh next
  ./scripts/task.sh list

Примеры:
  ./scripts/task.sh add "Купить домен" "OpenClaw Project"
  ./scripts/task.sh addp "Проверить логи"
  ./scripts/task.sh addm "Позвонить маме"
  ./scripts/task.sh done 23
  ./scripts/task.sh done "DNS"
  ./scripts/task.sh next
EOF
}

next_task() {
  local line
  line="$(python3 - "$TASKS_FILE" <<'PY'
import re,sys,datetime
from pathlib import Path

path=Path(sys.argv[1])
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

    candidates.append((p, due_days, text))

if not candidates:
    print("")
else:
    candidates.sort(key=lambda x:(x[0], x[1]))
    print(candidates[0][2])
PY
)"

  if [[ -z "$line" ]]; then
    echo "Открытых задач нет 🎉"
    return 0
  fi

  echo "Следующая задача: $line"
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
    next)
      next_task
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

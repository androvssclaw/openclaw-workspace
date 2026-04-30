# Git Workflow Policy

_Актуально на 2026-04-29_

## Репозиторий
- origin: `https://github.com/androvssclaw/openclaw-workspace.git`

## Базовые правила
- Рабочая ветка агента: `bot/updates-init`
- Прямой push в `main` запрещён
- Все изменения в `main` — только через Pull Request
- Коммиты должны быть маленькими и осмысленными
- После успешного commit в `bot/updates-init` агент **сразу делает push без дополнительного вопроса**

## Процесс для агента
1. Проверить текущую ветку
2. Если ветка не `bot/updates-init` — переключиться
3. Внести минимально необходимое изменение
4. Выполнить:
   - `git add -A`
   - `git commit -m "<clear message>"`
   - `git push origin bot/updates-init`
5. После push автоматически создать PR в `main`:
   - `gh pr create --base main --head bot/updates-init --title "<short title>" --body "<what was changed and why>"`
   - если PR уже существует — новый PR не создавать

## Risk-based merge policy

Авто-merge разрешён только если **все изменённые файлы** относятся к документации:
- `*.md`
- `docs/**`

Авто-merge **запрещён**, если изменения затрагивают:
- `scripts/**`
- `.github/**`
- `.env*`
- secrets/keys
- systemd files
- VPN files
- config files
- executable files

Правила действий:
- docs-only PR: push в `bot/updates-init` → create/update PR → merge через `gh pr merge --squash --delete-branch=false`
- любые другие изменения: create/update PR без merge, дать краткую оценку рисков и ждать ручного merge владельца

## Что делать при ошибке push
- Остановиться
- Не делать force-push
- Показать точную ошибку Git
- Дождаться решения владельца репозитория

## Рекомендации по сообщениям коммитов
- `docs: ...` — изменения документации
- `feat: ...` — новая функциональность
- `fix: ...` — исправления
- `chore: ...` — служебные правки

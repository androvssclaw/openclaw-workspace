# Git Workflow Policy

_Актуально на 2026-04-29_

## Репозиторий
- origin: `https://github.com/androvssclaw/openclaw-workspace.git`

## Базовые правила
- Рабочая ветка агента: `bot/updates-init`
- Прямой push в `main` запрещён
- Все изменения в `main` — только через Pull Request
- Коммиты должны быть маленькими и осмысленными

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

# OpenClaw

_Актуально на 2026-04-30 20:20 UTC_

## 🧠 Что у тебя сейчас есть

### ⚙️ Инфраструктура
- VPS (Ubuntu 24.04)
- OpenClaw установлен и работает
- Версия OpenClaw: `2026.4.27`
- Gateway: `127.0.0.1:18789` (loopback-only)
- systemd сервис настроен, включён и активен
- gateway закреплён на системном бинарнике: `/usr/bin/openclaw` (без привязки к nvm)
- Dashboard: http://127.0.0.1:18789/

👉 Это уже постоянный backend, не временный скрипт.

### 🤖 AI / модели
- Рабочий доступ к модели через OpenAI Codex OAuth
- Активная модель: `gpt-5.3-codex`
- Контекст: 200k
- Сессия активна, кэш работает

👉 У тебя живой агент, а не просто CLI.

### 💬 Канал общения
- Telegram подключен и в статусе OK
- Аккаунт Telegram: 1/1 активен
- Есть webchat/control UI для админки

👉 Это уже удалённый интерфейс к серверу.

### 🔐 Безопасность (частично)
- Gateway слушает только `127.0.0.1` (не торчит наружу напрямую)
- Работает политика ограниченного доступа (allowlist в текущей схеме)
- Есть 1 предупреждение в security audit: не настроены trusted proxies (важно только при reverse proxy)

### 🧩 Агент (самое важное)
Структура уже есть:
- `IDENTITY.md` — кто он
- `USER.md` — кто ты
- `SYSTEM.md` — поведение
- `SOUL.md` — стиль и характер
- `TASKS.md` — задачи
- `TOOLS.md` — локальные команды/шпаргалка
- `workspace/` — рабочая память и скрипты

👉 Это уже настраиваемый ассистент, не просто бот.

### 🛠 Автоматизация (текущий уровень)
- Есть папка `scripts/`
- `status.sh` — системный статус
- `tasks.sh` — чтение списка задач из `TASKS.md` (с автосозданием файла)
- `task.sh` — управление задачами (`add`, `done`, `list`)
- `remind.sh` — одноразовые напоминания через OpenClaw cron (`<when> <message>`)
- `vpn_status.sh` — read-only compatibility check для AmneziaWG
- `vpn_health.sh` — runtime health-check (DNS/iface/port/traffic)
- `health.sh` — единая проверка system + OpenClaw service + gateway port + VPN quick health
- `logs.sh` — быстрый вывод статуса и журнала `openclaw-gateway.service`
- `deploy.sh` — безопасный deploy/update-check workflow (требует `--confirm DEPLOY`)
- `health_check_thresholds.sh` — проверки по порогам (disk/memory/load/service) с exit code OK/WARN/CRIT
- `health_alert_cron.sh` — алерт в Telegram при смене статуса здоровья (OK/WARN/CRIT), устойчив к cron/user-bus окружению
- `setup_health_alert_cron.sh` — установка cron health-check каждые 15 минут
- `daily_ops_summary.sh` — сводка состояния в `state/daily_ops_summary.txt`
- `daily_planning.sh` — ежедневная planning-сводка
- `weekly_ops_review.sh` — еженедельный ops-review (health/incidents/tasks/memory)
- `weekly_scorecard.sh` — weekly scorecard по задачам/health/proactivity
- `focus.sh` — выбрать 1-3 приоритета из открытых задач
- `today.sh` — сводка на сегодня (top tasks + health + reminders)
- `ops_brief.sh` — быстрый ops-срез (health + алерты + последний incident)
- `cleanup.sh` — weekly cleanup (memory compact + scorecard + task snapshot)
- `task.sh next` — предложить следующую задачу автоматически
- `incident_report.sh` — компактный инцидент-отчёт (symptom/impact/cause/actions)
- `backup_restore_test.sh` — проверка восстанавливаемости backup (dry-run/restore-sample)
- `memory_compact.sh` — сжатая фиксация долгосрочной памяти/решений
- `GIT_WORKFLOW.md` — правила GitHub-процесса (ветка бота, PR-only в `main`, risk-based merge)

👉 Это рабочий переход к DevOps-ассистенту.

### 🧠 Backlog "мозг" (база уже внедрена)
- `MEMORY.md` — долговременная curated memory
- `memory/YYYY-MM-DD.md` — дневные заметки
- `docs/PROACTIVE_PLAYBOOK.md` — правила памяти/стиля/проактивности
- `HEARTBEAT.md` — heartbeat checklist с правилами пингов

## 📊 Уровень системы сейчас
Оценка:
- 0 → ничего
- 3 → просто бот
- 5 → API + сервер
- **7 → текущий уровень**
- 10 → автономный ассистент

## ⚠️ Текущие слабые места
1. **Безопасный deploy в прод-потоке**
   - Использовать `scripts/deploy.sh` только с явным подтверждением
2. **Тонкая настройка порогов алертов**
   - Подкрутить `DISK_WARN/CRIT`, `MEM_WARN/CRIT`, `LOAD_WARN/CRIT` под реальную нагрузку

## 🚀 Что это уже позволяет
Прямо сейчас можно:
- писать в Telegram и получать ответы AI
- вести и закрывать задачи
- ставить напоминания
- удалённо смотреть состояние сервера
- получать health-алерты в Telegram при деградации
- использовать safe deploy workflow с подтверждением

👉 Это уже личный Dev-помощник на сервере.

## 🧭 Куда идти дальше (логично)

### 1) Сделать ассистента полезнее в быту
- ежедневное планирование
- приоритизация задач
- напоминания/фоллоу-апы

### 2) Усилить автоматизацию
- деплой-команды
- healthcheck/мониторинг
- логирование и алерты

### 3) Прокачать “мозг”
- нормальная память (что важно держать в долгую)
- стабильный стиль ответов
- более проактивные действия (без спама)

## 🔐 VPN (AmneziaWG 2.0): текущее понимание

_Актуально на 2026-04-28 09:26 UTC_

Ключевое, что важно зафиксировать:
- архитектура сейчас: `iPhone → vpn.veltemio.com → Cloudflare DNS (DNS only) → 178.104.226.202 → AmneziaWG`
- клиент больше не привязан к «голому» IP: endpoint на домене
- на хосте активен интерфейс `amn0` (а не `wg0`) — это Amnezia/Docker-схема
- трафик по `amn0` подтверждён (RX/TX растут)

Быстрый вывод: схема рабочая и устойчивая к смене внешнего IP через обновление DNS `A` записи.

Автомониторинг сейчас (low-cost, без LLM):
- системный cron раз в 2 часа: `scripts/vpn_health_cron.sh`
- системный cron daily summary в 18:00 UTC: `scripts/vpn_daily_summary.sh`
- логи/сводки в `state/` (`vpn_health.log`, `vpn_health_daily_summary.txt`)

Подробный VPN runbook и проверки см. в `VPN.md`.

В `VPN.md` зафиксирован аварийный операционный чеклист, включая:
- переключение на 2 резервных клиентских профиля
- TTL policy (`1 min` для failover / `Auto` после стабилизации)
- плановый reboot VPS с пост-проверкой VPN

Статус на сейчас:
- резервные профили `backup-01` и `backup-02` созданы и проверены
- плановый reboot VPS выполнен, post-check VPN успешный

Также в `VPN.md` добавлен шаблон для task 23:
- имена резервных профилей
- где хранить профили безопасно
- как тестировать каждый профиль

Исторические anti-block инструкции:
- `VPN_ANTI_BLOCK_RUNBOOK.md`
- `VPN_ANTI_BLOCK_RUNBOOK_SHORT.md`

## Уже есть (пример)

User: `Запусти status`

Bot: `Готово, status запущен. Коротко: • Аптайм: 4ч 08м • Load average: 0.00 / 0.06 / 0.02 • Диск /: 5.2G из 38G (15%) • RAM: 968Mi из 3.7Gi (доступно ~2.8Gi) • Swap: нет (0B)`

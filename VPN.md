# VPN.md

_Актуально на 2026-04-28 09:26 UTC_

## Текущая архитектура

`iPhone → vpn.veltemio.com → Cloudflare DNS (DNS only) → 178.104.226.202 → AmneziaWG`

Ключевой эффект: клиент привязан к домену, а не к фиксированному IP.

## Что подтверждено

- DNS + endpoint через домен настроены (п.1–2).
- На хосте нет `wg0` и это нормально для текущей схемы.
- Активен интерфейс `amn0`.
- Трафик по `amn0` идёт (RX/TX растут).

## Production policy (фиксируем как стандарт)

- Endpoint у клиентов: только `vpn.veltemio.com:<port>`.
- В клиентских профилях не использовать IP напрямую.
- В Cloudflare для `vpn.veltemio.com` только `DNS only`.
- Для быстрых переключений держать TTL `1 min` (или `Auto`, если быстрый failover не нужен каждый день).

## Решение по TTL (task #29)

- Текущая политика: **оставляем TTL = `1 min`** для `vpn.veltemio.com`.
- Причина: быстрый и предсказуемый failover без правок клиентских профилей.
- Когда пересматривать: после стабильного периода без инцидентов (например, 2–4 недели) можно вернуть `Auto` для снижения частоты DNS-запросов.

## Статус выполненных задач (28/30)

- `#28` выполнена: созданы и проверены 2 резервных клиентских профиля (`backup-01`, `backup-02`).
- `#30` выполнена: сделан плановый reboot VPS, post-check через `vpn_health.sh` успешный.

Примечание: backup-профили подключаются к тому же серверу и endpoint, но это разные peer/ключи. Это нужно для быстрого переключения, если ломается конкретный клиентский профиль.
- Перед изменениями в проде: менять только один параметр за итерацию.

## Почему `wg0` не найден

Потому что VPN работает через Amnezia/Docker, где хостовый интерфейс — `amn0`.
Проверка через `sudo wg show wg0` в этой схеме невалидна.

## Правильные проверки

### Хост-уровень
```bash
sudo ip -s link show amn0
watch -n 1 'sudo ip -s link show amn0'
```

### Контейнер-уровень (peer/handshake)
```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
docker exec -it <container_name> awg show || docker exec -it <container_name> wg show
```

## Финальная валидация (п.4–6)

### 4) Проверка DNS/кэша
- Убедиться, что `vpn.veltemio.com` резолвится в актуальный IP.
- После смены `A` записи учитывать TTL и возможный клиентский кэш.

Команды:
```bash
dig +short vpn.veltemio.com @1.1.1.1
dig +short vpn.veltemio.com @8.8.8.8
```

### 5) Тест переподключения iPhone
1. Выключить VPN на iPhone.
2. Подождать 5–10 сек.
3. Включить VPN.
4. На сервере проверить рост RX/TX на `amn0`.

### 6) Failover-симуляция
1. В Cloudflare временно поменять `A` записи `vpn.veltemio.com` на тестовый/резервный IP.
2. Дождаться TTL.
3. На iPhone сделать VPN off/on.
4. Проверить, что новый endpoint реально используется.
5. Вернуть рабочий IP обратно (если тест).

## Важно

- Для WireGuard endpoint в Cloudflare использовать только `DNS only`.
- Не хардкодить IP в клиентских профилях.
- Изменения делать по одному фактору за итерацию.

## Мониторинг (базовый)

Скрипт: `scripts/vpn_health.sh`

Что проверяет:
- DNS резолв домена через `1.1.1.1` и `8.8.8.8`
- соответствие ожидаемому IP (если указан)
- что интерфейс `amn0` существует и `UP`
- что UDP порт VPN слушается (по умолчанию `31921`)
- дельту RX/TX за короткий интервал (как индикатор живого трафика)

Примеры:

```bash
./scripts/vpn_health.sh
./scripts/vpn_health.sh --domain vpn.veltemio.com --expected-ip 178.104.226.202 --port 31921 --iface amn0
```

### Low-cost мониторинг (без LLM)

Сейчас включён системный `crontab` (без `agentTurn`, без расхода LLM токенов):

- `0 */2 * * *` → `scripts/vpn_health_cron.sh`
  - запускает `vpn_health.sh`
  - пишет лог в `state/vpn_health.log`
  - пишет события в `state/vpn_health_events.log`
  - при fail сохраняет детали в `state/vpn_health_last_fail.txt`

- `0 18 * * *` → `scripts/vpn_daily_summary.sh`
  - считает сводку за последние 24 часа
  - пишет в `state/vpn_health_daily_summary.txt`
  - архивирует в `state/vpn_health_daily_summary_history.log`

OpenClaw cron-задачи `vpn-health-alert-2h` и `vpn-health-daily-summary` отключены.

## Аварийный операционный чеклист (если VPN ломается)

Порядок действий (меняем по одному фактору):

1) **Быстрая диагностика**
- `./scripts/vpn_health.sh --domain vpn.veltemio.com --expected-ip 178.104.226.202 --port 31921 --iface amn0`
- `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'`

2) **Проверка DNS/TTL политики**
- Проверить, что `vpn.veltemio.com` резолвится в рабочий IP
- TTL policy: держим `1 min` для быстрого failover, после стабилизации можно вернуть `Auto`

3) **Клиентская часть**
- Использовать только endpoint `vpn.veltemio.com:<port>`
- Переключиться на один из **2 резервных клиентских профилей** (заранее подготовленных)

4) **Failover (если есть резервный IP/VPS)**
- Переключить `A` запись на резерв
- дождаться TTL
- сделать VPN OFF/ON на клиенте

5) **Если не восстановилось**
- проверить `amn0` и RX/TX
- проверить публикацию UDP порта в Docker
- зафиксировать вывод `state/vpn_health_last_fail.txt`

6) **После восстановления**
- вернуть целевой IP/TTL-политику
- проверить подключение основного и резервных профилей
- задокументировать причину инцидента

7) **Плановый reboot VPS (техдолг)**
- если есть `System restart required`, выполнить перезагрузку в спокойное окно
- после reboot повторно прогнать `vpn_health.sh`

## Резервные клиентские профили (task 23)

### Имена (стандарт)
- `veltemio-iphone-backup-01`
- `veltemio-iphone-backup-02`

### Где хранить
- Основное: password manager (Secure Note + вложения `.conf`/QR)
- Резерв: локальная зашифрованная папка (не в git), например `~/Secure/VPN/veltemio/`
- В workspace хранить только шаблоны/документацию, без приватных ключей

### Шаблон карточки профиля

```
profile_name: veltemio-iphone-backup-0X
device: iPhone
created_at_utc: YYYY-MM-DD HH:MM
endpoint: vpn.veltemio.com:31921
dns_mode: default | custom
public_key_client: <redacted>
private_key_client: <store only in secure vault>
allowed_ips: 0.0.0.0/0, ::/0
notes: резервный профиль, не использовать как основной
```

### Как тестировать (каждый профиль)
1. Отключить основной профиль VPN на iPhone.
2. Импортировать `backup-01` (или `backup-02`) и включить.
3. Проверить, что VPN поднимается и интернет работает.
4. На сервере проверить трафик:
   - `sudo ip -s link show amn0` (повторить через 10 сек, RX/TX должны расти)
5. Зафиксировать результат теста (дата, профиль, успех/ошибка).

### Периодичность ретеста
- Быстрый ретест резервов: 1 раз в месяц
- После изменения порта/ключей/сервера: ретест в тот же день

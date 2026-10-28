# SKeen REST API Documentation

Документация по REST API для системы **SKeen** — легкого HTTP-сервера управления конфигурацией и утилитой SKeen, написанного на Lua с использованием библиотеки `luasocket`.

## Оглавление

1. [Установка и зависимости](#1-установка-и-зависимости)

2. [Обзор и Архитектура](#2-обзор-и-архитектура)

3. [Управление демоном и CLI](#3-управление-демоном-и-cli)

4. [Конфигурация API](#4-конфигурация-api)

5. [Аутентификация и Безопасность](#5-аутентификация-и-безопасность)

6. [Эндпоинты REST API](#6-эндпоинты-rest-api)

   * [GET /](#1-get-)

   * [GET /api/ping](#2-get-apiping)

   * [GET /api/status](#3-get-apistatus)

   * [GET /api/files-list](#4-get-apifiles-list)

   * [GET /api/file](#5-get-apifile)

   * [POST /api/file](#6-post-apifile)

   * [POST /api/exec](#7-post-apiexec)

7. [Коды ответов HTTP](#7-коды-ответов-http)

## 1. Установка и зависимости

Начиная со SKeen версии 5.9.0, `skeen-api` устанавливается автоматически как обязательная зависимость вместе со SKeen.

### Дисковое пространство

Общий объем установки составляет **менее 500 КБ**:
- **SKeen API (Бэкенд + Фронтенд)**: < 150 КБ
- **Пакет Lua (`opkg package: lua`)**: ~20 КБ
- **Пакет LuaSocket (`opkg package: luasocket`)**: ~250 КБ

### Восстановление пропущенных зависимостей

Если при обновлении проверка установки зависимостей была прервана, вы можете в любой момент запустить команду для повторной проверки и установки:

```bash
skeen deps
```

## 2. Обзор и Архитектура

`skeen-api` представляет собой комбинированный модуль: CLI-утилиту управления сервисом (демоном) и встроенный однопоточный веб-сервер.

### Ключевые особенности:

* **Стек**: Lua (проверяется совместимость с `/opt/bin/lua`), `luasocket`.

* **Архитектура**: Синхронная обработка HTTP/1.1 запросов с таймаутом на клиентское соединение (`30 сек`).

* **Формат данных**: JSON (кастомный кастом-парсер с поддержкой удаления комментариев `//`, `/* */`, `#` и сохранением порядка ключей через поле `__order`).

* **Интеграция**: Выполнение системных команд `skeen` через `io.popen` и безопасное управление файловой системой (атомарная запись через временные `.tmp` файлы).

## 3. Управление демоном и CLI

Скрипт `skeen-api` включает в себя CLI-интерфейс для управления фоновым процессами с помощью `start-stop-daemon`.

### Команды CLI:

```
skeen-api {start|stop|restart|run|status|update|version}

```

* `start` — запуск API-сервера в фоновом режиме (PID сохраняется в `/tmp/run/skeen-api.pid`).

* `stop` — остановка фонового процесса.

* `restart` — перезапуск сервиса.

* `run` — прямой запуск сервера в текущем терминале (foreground).

* `status` — просмотр текущего состояния: PID, Uptime (в днях/часах/минутах) и потребление памяти (VmRSS/VmHWM из `/proc`).

* `update` — проверка обновления и скачивание актуальной версии скрипта из GitHub.

* `version` (или `-v`) — вывод текущей версии скрипта (например, `v1.0.0`).

## 5. Конфигурация API

Настройки сервера динамически запрашиваются у основной CLI-системы через выполнение команды `skeen get_api_config`.

### Дефолтные настройки:

```
{
  "port": 3000,
  "secret": "",
  "cors_origin": ["*"],
  "dashboard": 1
}

```

* **port** (*number*): Порт на котором завязывается сокет `0.0.0.0` (по умолчанию `3000`).

* **secret** (*string*): Секретный ключ авторизации (Header `X-API-Key`). Если пустой — авторизация отключена.

* **cors_origin** (*array*): Настройка CORS (Cross-Origin Resource Sharing). Определяет список сайтов/доменов, которым разрешено делать запросы к API из браузера.
  - `["*"]` — разрешает доступ с любых доменов.
  - `["http://192.168.1.1:3000", "https://skeen.indevs.in"]` — ограничивает доступ только указанными источниками.

* **dashboard** (*number*): `1` — разрешает отдачу HTML-страницы Dashboard по маршруту `/`, `0` — возвращает `404 Not Found`.

## 6. Аутентификация и Безопасность

### API Key (X-API-Key)

Если в конфигурации задан ключ `secret` (не пустая строка), все эндпоинты, начинающиеся с пути `/api/`, требуют передачу заголовка:

```
X-API-Key: ваш_секретный_ключ

```

В случае отсутствия или неверного ключа сервер вернет ответ `401 Unauthorized`.

### CORS & Security Headers

Каждый ответ сервера снабжается заголовками безопасности:

* `X-Content-Type-Options: nosniff`

* `X-Frame-Options: SAMEORIGIN`

* `Access-Control-Allow-Methods: GET, POST, OPTIONS`

* `Access-Control-Allow-Headers: X-API-Key, Content-Type`

## 5. Эндпоинты REST API

### 1. GET /

Запрос главной страницы (веб-интерфейса).

* **Метод**: `GET`

* **Авторизация**: Не требуется.

* **Зависимость**: Должен быть включен параметр `dashboard: 1`.

#### Пример запроса:

```
curl -X GET http://192.168.1.1:3000/

```

* **Ответ**: HTML-код интерфейса (`text/html; charset=utf-8`).

### 2. GET /api/ping

Проверка доступности и работоспособности сервера.

* **Метод**: `GET`

* **Авторизация**: Требуется (если включен `secret`).

#### Пример запроса:

```
curl -X GET http://192.168.1.1:3000/api/ping \
     -H "X-API-Key: your_secret_key"

```

#### Успешный ответ (`200 OK`):

```
{
  "status": "ok",
  "message": "pong"
}

```

### 3. GET /api/status

Получение системного статуса SKeen и версии API.

* **Метод**: `GET`

* **Авторизация**: Требуется.

#### Пример запроса:

```
curl -X GET http://192.168.1.1:3000/api/status \
     -H "X-API-Key: your_secret_key"

```

#### Успешный ответ (`200 OK`):

```
{
  "success": true,
  "running": true,
  "mode": "sing-box",
  "version": "1.2.0",
  "sb_version": "1.8.0",
  "api_version": "1.0.0"
}

```

### 4. GET /api/files-list

Получение списка разрешенных для чтения и редактирования файлов конфигурации.

* **Метод**: `GET`

* **Авторизация**: Требуется.

Динамически вычисляет пути из `/opt/etc/skeen/skeen.json`:

* `skeen`: Основной файл настроек `skeen.json`.

* `pure_cidr`: Список CIDR (по умолчанию `pure_cidr.list` или из поля `firewall.intercept.fakeip.include`).

* `singbox` / `sb_file_*`: Конфиг Sing-box (`config.json` или найденные `.json` файлы в директории).

#### Пример запроса:

```
curl -X GET http://192.168.1.1:3000/api/files-list \
     -H "X-API-Key: your_secret_key"

```

#### Успешный ответ (`200 OK`):

```
[
  {
    "id": "pure_cidr",
    "name": "pure_cidr.list"
  },
  {
    "id": "skeen",
    "name": "skeen.json"
  },
  {
    "id": "singbox",
    "name": "config.json"
  }
]

```

### 5. GET /api/file

Чтение содержимого файла конфигурации по его идентификатору (`id`).

* **Метод**: `GET`

* **Параметры URL**: `name` (string) — `id` файла (например, `skeen`, `pure_cidr`, `singbox`, `sb_file_0`). По умолчанию: `skeen`.

* **Авторизация**: Требуется.

#### Пример запроса:

```
curl -X GET "http://192.168.1.1:3000/api/file?name=skeen" \
     -H "X-API-Key: your_secret_key"

```

#### Успешный ответ для JSON-файла (`200 OK`):

*Комментарии автоматически удаляются перед отдачей в формате объекта JSON.*

```
{
  "success": true,
  "content": {
    "mode": "rule",
    "singbox": {
      "auto_start": true
    }
  }
}

```

#### Успешный ответ для текстового файла (`200 OK`):

```
{
  "success": true,
  "content": "192.168.1.0/24\n10.0.0.0/8\n"
}

```

### 6. POST /api/file

Сохранение/обновление содержимого файла конфигурации.

* **Метод**: `POST`

* **Header**: `Content-Type: application/json`

* **Авторизация**: Требуется.

#### Тело запроса (JSON):

* `name` (*string*): Идентификатор целевого файла.

* `content` (*object|string*): Новое содержимое. Для `json`-файлов передается JSON-объект, для `text`-файлов — строка.

#### Пример запроса (обновление текстового файла `pure_cidr`):

```
curl -X POST http://192.168.1.1:3000/api/file \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "pure_cidr",
       "content": "192.168.1.0/24\n172.16.0.0/12\n"
     }'

```

#### Пример запроса (обновление JSON-файла `skeen`):

```
curl -X POST http://192.168.1.1:3000/api/file \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "skeen",
       "content": {
         "mode": "rule"
       }
     }'

```

#### Успешный ответ (`200 OK`):

```
{
  "success": true,
  "message": "File updated"
}

```

### 7. POST /api/exec

Выполнение разрешенных CLI-команд `skeen <param>`.

* **Метод**: `POST`

* **Header**: `Content-Type: application/json`

* **Авторизация**: Требуется.

#### Разрешенные команды (`param`):

`start`, `stop`, `restart`, `reload`, `kill`, `status`, `version`, `help`, `iface`, `connstat`, `test`, `deps`, `check`, `format`, `backup`, `backups`, `clean`, `sync`, `headers`, `areload`, `restore <file>`, `sync <url>`, `tun list`, `tun create <ip> <dev>`, `tun delete <dev>`.

*(Примечание: `areload` выполняются асинхронно с задержкой в 2 секунды, чтобы успел вернуться ответ HTTP).*

#### Тело запроса (JSON):

```
{
  "param": "restart"
}

```

#### Пример запроса:

```
curl -X POST http://192.168.1.1:3000/api/exec \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{"param": "status"}'

```

#### Успешный ответ (`200 OK`):

```
{
  "success": true,
  "stdout": "SKeen status: running\nService is active."
}

```

## 7. Коды ответов HTTP

| Код | Статус | Описание |
| ----- | ----- | ----- |
| `200` | **OK** | Запрос выполнен успешно. |
| `204` | **No Content** | Успешный ответ на `OPTIONS` CORS preflight запрос. |
| `400` | **Bad Request** | Неверный HTTP-запрос, некорректный JSON или незарегистрированная команда в `/api/exec`. |
| `401` | **Unauthorized** | Отсутствует или передан неверный заголовок `X-API-Key`. |
| `404` | **Not Found** | Запрошенный маршрут не существует или отключен Dashboard. |
| `500` | **Internal Server Error** | Ошибка записи файла на диске. |

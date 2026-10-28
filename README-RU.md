<p align="center">
  <img src="/assets/logo_ru.png" alt="SKeen" width="512" style="max-width: 100%; height: auto; display: block; margin: 0 auto; padding: 20px 0;" />
</p>

<h1 align="center">SKeen</h1>

> Лёгкий прозрачный прокси для роутеров Keenetic/Netcraze на базе sing-box.

[![Build](https://github.com/jinndi/SKeen/actions/workflows/release.yml/badge.svg)](https://github.com/jinndi/SKeen/actions/workflows/release.yml) [![SKeen](https://img.shields.io/github/v/release/jinndi/SKeen)](https://github.com/jinndi/SKeen/releases/latest) [![License](https://img.shields.io/github/license/jinndi/SKeen)](https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/main/LICENSE) [![sing-box-latest](https://img.shields.io/github/v/release/SagerNet/sing-box?label=sing-box-latest&display_name=tag)](https://github.com/SagerNet/sing-box/releases/latest) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/jinndi/SKeen)

🇷🇺 **Русский** | [🇺🇸 English](./README.md) | [🧩 FAQ](docs/FAQ-RU.md)

SKeen настраивает прозрачное проксирование на роутерах Keenetic и Netcraze с использованием sing-box. Проект управляет правилами firewall, сервисом и синхронизацией конфигурации.

## Особенности

- Режимы TProxy, Redirect, Hybrid, Tun и DNS
- Поддержка IPv4 и IPv6
- Рабочий модуль sing-box DNS
- Рабочий sing-box FakeIP
- Проксирование по FakeIP на уровне iptables
- Настроенный веб-интерфейс через встроенный API
- Оптимизация сетевых настроек
- Команды, работающие через WEB CLI роутера
- Переключение между официальным и сторонним sing-box
- Синхронизация конфигурации sing-box по HTTP(S)-ссылке
- Примеры использования Sub-Store для синхронизации
- Готовые шаблоны конфигураций Sing-box
- Опциональное проксирование самого роутера
- Не требует токена доступа для RCI запросов

## Требования

  - Установленный и настроенный Entware.
  - Установленный компонент «Модули ядра подсистемы Netfilter».
  - Установленный `curl` (`opkg install curl`).
  - Рекомендуется: минимум 256 МБ ОЗУ и процессор ARM для раскрытия полного потенциала.

## Установка

Убедитесь, что установлен Entware. В противном случае найдите инструкцию для вашей модели в [Центре поддержки](https://support.netcraze.ru/): «Руководство пользователя» → «Управление» → «OPKG» → «Установка репозитория Entware на USB-накопитель» или «Установка OPKG Entware на встроенную память роутера».

> [!TIP]
> Ничего **совсем** не устанавливается?
>
> Попробуйте [оффлайн-установщик Entware с предустановленным SKeen](https://github.com/jinndi/SKeen/tree/static/entware).

**Выполните команду в SSH из среды Entware:**

```sh
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen_ru --resolve release-assets.githubusercontent.com:443:185.199.108.133 | sh
```

<details>
  <summary>Не устанавливается? (нажмите, чтобы развернуть)</summary>
<br>

1. [Попробуйте оффлайн-установщик Entware с предустановленным SKeen](https://github.com/jinndi/SKeen/tree/static/entware).
2. См. также [руководство по устранению неполадок](docs/TROUBLESHOOTING-RU.md).

</details>

> [!NOTE]
> Вам будет предложено установить `sing-box` из официального репозитория (стабильную или бета-версию). Также установку можно пропустить, чтобы позже указать свой бинарный файл в `skeen.json`.

**Настройте конфигурацию:**

1. SKeen — в файле [`/opt/etc/skeen/skeen.json`](./docs/CONFIGURATION-RU.md).
2. sing-box — в файле [`/opt/etc/skeen/config.json`](./examples/configs/stable/config-commented.jsonc).
3. Sing-box веб-панель доступна по адресу `http://192.168.1.1:9999`. По умолчанию используется IP-адрес роутера (обычно `192.168.1.1`).
4. Skeen API с панелью по умолчанию на `3000` порту без авторизации, запуск и настройку [смотрите тут](./docs/SKEEN-API-RU.md), или ниже в разделе **Веб-панели**.

**Важно:**

Директория `/opt/etc/skeen` сохраняется при удалении программы и не перезаписывается при повторной установке, если уже существует. При необходимости удалите ее вручную.

Для дальнейшего управления SKeen используйте команду `skeen`.

**Структура файлов и папок после успешной установки:**

```
/opt/
├── bin/
│   ├── skeen                   # Основной скрипт управления SKeen
│   ├── skeen-api               # SKeen API крипт (начина с версии 5.9.0)
│   └── skeen-box               # Банарник sing-box (если выбрали установку)
│
├── etc/
│   ├── init.d/
│   │   └── S99SKeen            # Скрипт автозапуска при старте системы
│   ├── ndm/netfilter.d/
│   │   └── skeen_firewall.sh   # Правила файрвола (создается при запуске)
│   └── skeen/
│       ├── skeen.json          # Конфигурация SKeen
│       ├── config.json         # Конфигурация sing-box
│       └── ruleset/            # Папка с .srs файлами для начального старта
│
└── tmp/                        # Временные файлы загрузки

/tmp/  (RAM-диск) - синхранизируется в память:
├── .skeen/
│   ├── skeen.sh                # Копия скрипта - после старта/перезапуска
│   ├── skeen.json              # Кэш конфига - при изменениях в источнике
│   └── version                 # Кэш версии sing-box - при смене бинарного файла
└── run/
    ├── skeen.pid               # PID-файл sing-box процесса
    └── skeen-api.pid           # PID-файл skeen-api процесса
```

### Веб-панели

**Для управления SKeen** в локальной сети и удаленно начиная с версии 5.9.0  можно использовать веб-панель https://skeen.indevs.in либо встроенную, подробнее читайте настройку в [SKEEN-API-RU.md](./docs/SKEEN-API-RU.md).

> [!NOTE]
> Для доступа к локальному API (например, по `http://192.168.1.1:3000`) для всех браузеров, кроме Chrome, необходимо использовать HTTP-версию сайта - http://skeen.indevs.in (из-за ограничений браузеров на обращение с HTTPS-страниц к локальному HTTP).

По умолчанию доступ разрешен с любого домена. Если нужно его ограничить, укажите разрешенные источники в файле skeen.json (`services.api`), и обязательно пропишите там же сложный ключ в поле `secret`, если вы планируете подключаться удаленно через KeenDNS.

В базовом шаблоне `config.json` для доступа к панелям из локальной сети роутера преднастроены следующие домены:

| URL панели | Используемое API | Адрес для подключения в панели | Краткое описание панели |
| :--- | :--- | :--- | :--- |
| **[sing-box-dashboard.sagernet.org](https://sing-box-dashboard.sagernet.org)** *(в Chrome)*<br>[HTTP версия](http://sing-box-dashboard.sagernet.org) *(остальные)* | Нативный API `sing-box` (`9999`) | `http://192.168.1.1:9999` | Встроенная веб-панель `sing-box` (файлы дашборда хранятся локально на роутере). |
| **[sdash.u1.pw](https://sdash.u1.pw)** *(в Chrome)*<br>[HTTP версия](http://sdash.u1.pw) *(остальные)* | Нативный API `sing-box` (`9999`) | `http://192.168.1.1:9999` | Очень легкий веб-интерфейс для управления `sing-box`. |
| **[board.zash.run.place](https://board.zash.run.place)** *(в Chrome)*<br>[HTTP версия](http://board.zash.run.place) *(остальные)* | Clash API (`9090`) | `http://192.168.1.1:9090` | Удаленный фронтенд **Zashboard** для управления прокси-соединениями. |
| **[d.metacubex.one](https://d.metacubex.one)** / **[metacubexd.pages.dev](https://metacubexd.pages.dev)** *(только для Chrome)* | Clash API (`9090`) | `http://192.168.1.1:9090` | Альтернативный веб-интерфейс **MetacubexD** (Yacd-meta) для Clash API. |


Вместо локального подключения можно указывать адрес домена KeenDNS (но не забудьте также указать секретный ключ доступа `secret`).

## Команды

Пример использования через SSH: запуск демона `skeen start`

При использовании Web CLI роутера добавляйте `exec` перед командой. Например: `exec skeen reload`

> Вывод ответа в Web CLI ограничен 8 строками и определенным временем, но это не влияет на корректное выполнение команд.

Команда `skeen` без параметров запускает меню управления в SSH. Используйте `skeen help` для справки.

| Команда | Описание | Web CLI | API |
| :--- | --- | :---: | :---: |
| `start` | Запустить сервис | ✓ | ✓ |
| `stop` | Остановить сервис | ✓ | ✓ |
| `restart` | Полный перезапуск | ✓ | ✓ |
| `reload` | Перезагрузка только sing-box | ✓ | ✓ |
| `kill` | Принудительно остановить | ✓ | ✓ |
| `status` | Показать статус | ✓ | ✓ |
| `version` | Показать версию | ✓ | ✓ |
| `help` | Помощь по любой команде | - | ✓ |
| `iface` | Показать таблицу сетевых интерфейсов | - | ✓ |
| `connstat` | Диагностика соединений | - | ✓ |
| `update` | Проверить и установить обновления | - | - |
| `test` | Проверить правила фаервола | ✓ | ✓ |
| `deps` | Проверить зависимости | ✓ | ✓ |
| `check` | Проверить конфигурацию | ✓ | ✓ |
| `format` | Форматировать конфигурацию sing-box | ✓ | ✓ |
| `api` | Команды API управления sing-box | - | - |
| `backup` | Создать архив `/opt/etc/skeen` | ✓ | ✓ |
| `backups` | Список созданных архивов в `/opt` | ✓ | ✓ |
| `restore`¹ | Восстановить `/opt/etc/skeen` из архива `/opt` | ✓ | ✓ |
| `reset` | Сбросить `/opt/etc/skeen` до состояния по умолчанию | - | - |
| `clean`² | Очистить кэш файл sing-box | ✓ | ✓ |
| `sync`³ | Синхронизировать конфигурацию sing-box | ✓ | ✓ |
| `headers` | Сгенерировать фейковые заголовки клиента для подписок | - | ✓ |

1 - в качестве второго параметра можно передать имя архива с расширением `.tar` для немедленного запуска восстановления

2 - очищает файл кэша. Это необходимо при использовании функции `experimental.cache_file` в sing-box, например, для сброса кэша загруженных правил (rule_set) и истории DNS-запросов.

3 - принимает URL JSON-конфигурации sing-box в качестве второго параметра (HTTP или HTTPS), необязательно указывать, если прописан адрес в `singbox.config.url`.

**Менеджер OpkgTun (KeeneticOS v5+, через SSH и API)**

| Команда | Описание |
| :--- | :--- |
| `skeen tun create <ipv4> <name>` | Создать интерфейс с IP-адресом и именем |
| `skeen tun delete <name>` | Удалить интерфейс по имени |
| `skeen tun list` | Показать все интерфейсы OpkgTun |

## Настройки

Полный справочник конфигурации доступен в [docs/CONFIGURATION-RU.md](docs/CONFIGURATION-RU.md).

## Полезные ссылки

**Синхронизация и GUI**
- [Sub-Store Docker](https://github.com/jinndi/Sub-Store-Docker) — Docker-сборка для VPS/локального развертывания.
- [Sub-Store Desktop](https://github.com/jinndi/sub-store-gui) — десктопная версия для управления подписками.
- [Sub-Store Android](https://github.com/sionnx/SubCase) — Android-версия для мобильного управления.
- [GUI.for.SingBox sync plugin](https://github.com/jinndi/sync-profile-to-skeen) — плагин для импорта профилей в SKeen.

**Правила и наборы**
- [Karing ruleset](https://github.com/KaringX/karing-ruleset/tree/sing) — наборы правил для sing-box.
- [Custom sing-box rulesets](https://github.com/jinndi/singbox_ruleset) — кастомные наборы правил.

**Прочее**
- [core-tutorial.argsment.com](https://core-tutorial.argsment.com/singbox) — справочник по sing-box.
- [Разбор современного sing-box 1.14](https://www.qichiyu.com/1111.html) — для тех, кто понимает китайский язык.
- [Полный разбор Sub-Store](https://www.qichiyu.com/1119.html) — для тех, кто понимает китайский язык.
- [jinndi/skeen-box](https://github.com/jinndi/skeen-box) — sing-box билды c патчем REALITY и UPX сжатием.
- [sing-box-lx core (XHTTP)](https://github.com/Leadaxe/sing-box-lx) — альтернативное ядро c XHTTP.

<p align="center">
<img alt="SKeen" src="/logo.webp" width="214">
</p>
<h1 align="center">
  SKeen
</h1>
<h3 align="center">
TProxy и Redirect для Keenetic/Netcraze на базе sing-box
</h3>

<p align="center">
<a href="https://github.com/jinndi/SKeen"><img alt="SKeen" src="https://img.shields.io/github/v/release/jinndi/SKeen"></a>
<a href="https://github.com/SagerNet/sing-box"><img alt="sing-box" src="https://repology.org/badge/version-for-repo/homebrew/sing-box.svg?header=sing-box-latest-version"></a>
<img alt="Code size in bytes" src="https://img.shields.io/github/languages/code-size/jinndi/SKeen">
<img alt="Visitor" src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fjinndi%2FXSKeen&label=visitor&icon=eye&color=%230d6efd&message=&style=flat&tz=UTC">
<a href="https://deepwiki.com/jinndi/SKeen"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
</p>

🇷🇺 **Русский** | [🇺🇸 English](README.md)

<details>
  <summary>🤔Почему sing-box ?</summary>
<br>

**sing-box** — это универсальный прокси-движок с открытым исходным кодом, написанный на Go. Он ориентирован на максимальную производительность, низкое потребление ресурсов и поддержку самых современных протоколов

**Сравнение прокси-движков в контексте роутеров и встраиваемых систем (Embedded)**

|Параметр                |sing-box         |Xray              |mihomo          |
|------------------------|-----------------|------------------|----------------|
|Ресурсоемкость (RAM/CPU)|✅ Минимальная   |⚠️ Средняя        |❌ Высокая       |
|Поддержка протоколов    |✅ Передовой     |⚠️ Мало           |✅ Много       |
|Мультиплексирование     |✅ Отлично        |⚠️ Проблемно      |✅ Хорошо        |
|DNS-логика              |🥇 Native (+Fake-IP)|🥉 Sniffing (+FakeDNS)|🥈 Fake-IP (+Real)|
|Маршрутизация           |✅ Гибко         |⚠️ Базово         |✅ (но тяжелее) |
|Управление правилами    |✅ Rule-sets (bin)|⚠️ Geo-files (dat)|✅ Rule-providers|
|Независимый проект      |✅ Да            |❌ (форк V2Ray)   |❌ (форк Clash) |
|Порог вхождения         |🔴 Высокий       |🟡 Средний        |🟢 Низкий       |

Примечания:

> sing-box выигрывает за счет модульности и написанного с нуля кода: его DNS-стек позволяет создавать конфигурации любой сложности при минимальных затратах RAM. В то же время mihomo (Clash) ориентирован на автоматизацию, что требует значительных ресурсов, а Xray ограничен устаревшим сетевым стеком и тяжелыми .dat файлами.

> Высокий порог вхождения sing-box обусловлен строгим синтаксисом JSON и отсутствием «магических» настроек по умолчанию, что компенсируется полным контролем над трафиком.
</details>

<details>
  <summary>🖥️ Веб интерфейс ?</summary>
<br>

Проект не включает отдельный веб-интерфейс для настройки. Для управления уже используется встроенный интерфейс **Zashboard**, что делает дополнительные UI избыточными.

💡 Для упрощения настройки доступен [плагин синхронизации](https://github.com/jinndi/sync-profile-to-skeen), позволяющий импортировать профили через [GUI.for.SingBox](https://github.com/jinndi/sync-profile-to-skeen)
</details>

### 🚀 Особенности

  - Режимы TProxy/Redirect/Hybrid ✓
  - Поддержка IPv4 и IPv6 ✓
  - Работающий модуль Sing-box DNS ✓
  - Работающий Sing-box fakeip ✓
  - Настроенный Zashboard через Clash API ✓
  - Оптимизация сетевых настроек ✓
  - Команды работающие через WEB CLI роутера ✓

### 📋 Требования

  - Установленный и настроенный Entware **не во внутренней памяти** устройства
  - Установленный компонент «Модули ядра подсистемы Netfilter»
  - Установленный `curl` (`opkg install curl`)
  - Рекомендуется: минимум 256 МБ ОЗУ и процессор ARM для раскрытия полного потенциала

### 💾 Установка

**Выполните из среды Entware из SSH:**

```bash
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen | sh
```

**Настройте SKeen**. Его файл конфигурации находится по адресу `/opt/etc/skeen/skeen.json`.

**Настройте JSON-файл(ы) конфигурации sing-box**, расположенные в директории `/opt/etc/skeen/config/`. В этой директории уже подготовлены примеры файлов. Либо используйте собственный одиночный файл конфигурации, включив режим `sing_config.enable`.

**Zashboard панель** по умолчанию настроена через Clash API и доступна по IP-адресу роутера (обычно 192.168.1.1) по адресу `http://192.168.1.1:9999`.

Директория `/opt/etc/skeen` не удаляется при деинсталляции программы (ее нужно удалить вручную при необходимости) и не перезаписывается при переустановке, если она уже существует.

Для дальнейшего управления используйте команду `skeen`.

<details>
  <summary>Структура файлов и папок после успешной установки:</summary>
<br>

```
/opt/
├── bin/
│   ├── skeen              # Скрипт управления SKeen
│   └── skeen-box          # Бинарный файл sing-box
├── etc/
│   ├── init.d/
│   │   └── S99SKeen       # Скрипт автозапуска
│   ├── ndm/
│   │   └── netfilter.d/
│   │       └── skeen_firewall.sh  # Создается при запуске
│   └── skeen/
│       ├── skeen.json     # Конфигурация SKeen
│       └── config/        # Директория конфигов sing-box
│           ├── log.json
│           ├── dns.json
│           ├── inbounds.json
│           ├── outbounds.json
│           ├── route.json
│           └── experimental.json
└── tmp/
    └── (временные файлы загрузки)
```
</details>

### ⚡ Команды

Пример использования через SSH: запуск демона `skeen start`

При использовании Web CLI роутера добавляйте `exec` перед командой. Например: `exec skeen reload`

> Вывод ответа в WEB CLI ограничен 8 строками и определенным временем, но это не влияет на корректное выполнение команд

Команда `skeen` без параметров запускает меню управления в SSH. Используйте `help` для справки.

| Команда | Описание | WEB CLI |
| :--- | --- | :---: |
| `start` | Запустить сервис | ✓ |
| `stop` | Остановить сервис | ✓ |
| `restart` | Перезапустить сервис | ✓ |
| `reload` | Перезапустить без смены правил фаервола | ✓ |
| `kill` | Принудительно остановить | ✓ |
| `status` | Показать статус | ✓ |
| `version` | Показать версию(и) | ✓ |
| `update` | Проверить и установить обновления | - |
| `test` | Проверить правила фаервола | ✓ |
| `deps` | Проверить зависимости | ✓ |
| `check` | Проверить конфигурацию | ✓ |
| `format` | Форматировать конфигурацию Sing-box | ✓ |
| `backup` | Создать архив `/opt/etc/skeen` | ✓ |
| `backups` | Список созданных архивов в `/opt` | ✓ |
| `restore`¹ | Восстановить `/opt/etc/skeen` из архива `/opt` | ✓ |
| `reset` | Сбросить `/opt/etc/skeen` до состояния по умолчанию | - |
| `sync`² | Синхронизировать конфигурацию sing-box | ✓ |

1 - в качестве второго параметра можно передать имя архива с расширением `.tar` для немедленного запуска восстановления

2 - принимает URL JSON-конфигурации Sing-box (либо другой в режиме работы `firewall.only`) в качестве второго параметра (HTTP или HTTPS), необязательно указывать, если прописан адрес в `sing_config.sync_url`


| Менеджер OpkgTun (KeeneticOS v5+, только через SSH) |
| :--- |
| `skeen tun create <ipv4> <name>` — Создать интерфейс с IP-адресом и именем |
| `skeen tun delete <name>` — Удалить интерфейс по имени |
| `skeen tun list` — Показать все интерфейсы OpkgTun |

Если пропал доступ к SSH Entware, выполните в Web CLI:

```
exec /opt/etc/init.d/S51dropbear start
```

### ⚙️ Настройки

> [!NOTE]
> После внесения изменений в файл требуется перезапуск через `skeen restart` или через меню

Файл `/opt/etc/skeen/skeen.json` содержит следующие настройки:

```jsonc
{
  "auto_start": {
    "enable": 1,       // Автозапуск SKeen при загрузке роутера (0 = выключено)
    "delay": 0         // Задержка автозапуска в секундах (по умолчанию: 0)
  },
  "policy": {
    "enable": 1,       // Включить маршрутизацию на основе политики (0 = выключено)
    "name": "SKeen"    // Имя политики роутера (по умолчанию: "SKeen")
  },
  "network": {
    "ipv6": 1,         // Включить поддержку IPv6 (0 = выключено)
    "tuning": 0,       // Включить оптимизацию сети через sysctl (1 = вкл).
                       // Если выключено, настройки sysctl сбросятся после перезагрузки.
    "check": [
      "1.1.1.1",
      "77.88.8.8",
      "223.5.5.5"
    ]                  // Домены или IPv4 для проверки доступности сети (макс. 3)
  },
  "sing_config": {
    "enable": 0,       // Если 1, будет использоваться один файл конфига Sing-box
                       // по адресу /opt/etc/skeen/config.json вместо папки /opt/etc/skeen/config/
    "path": "",        // Можно указать свой собственный полный путь
    "sync_url": "",    // URL-адрес (http:// или https://), откуда будет синхронизироваться
                       // конфигурация командой `sync` по умолчанию (необязательно)
  },
  "service_proxy": {
    "enable": 0,       // Если 1, используется локальный прокси (127.0.0.1) для команд update и sync
    "port": "",        // Порт локального прокси (SOCKS5 или mixed)
    "user": "",        // Имя пользователя для подключения (не обязательно)
    "pass": ""         // Пароль пользователя для подключения (обязательно если указан user)
  },
  "firewall": {
    "intercept": {
      "dns": 1,        // Перехватывать DNS-запросы через режимы TProxy/Hybrid (0 = выкл)
      "port": []       // Порты для перехвата (все, если пусто).
                       // Пример: [ 80, 443, "1000:2000", "1500:5555" ]
    },
    "exclude": {
      "port": [
        123, 137,
        138, 139,
        445            // Порты, исключенные из редиректа
                       // (игнорируется, если задан `intercept.port`)
      ],
      "ipv4_cidr": [], // Исключенные подсети IPv4 из редиректа
                       // Пример: [ "192.87.1.0/24", "192.12.1.1" ]
      "ipv6_cidr": []  // Исключенные подсети IPv6 из редиректа
                       // Пример: [ "2001:db8::/32", "2001:db8::1" ]
    }
  }
}
```

### 🔗 Полезные ссылки

  - Плагин синхронизации: [https://github.com/jinndi/sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen)
  - Схема Sing-box: [https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002](https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002)
  - Различные примеры настроек: [https://proxy-tutorials.dustinwin.us.kg](https://proxy-tutorials.dustinwin.us.kg)
  - Генератор outbounds: [https://4n0nymou3.github.io/proxy-to-singbox-converter/](https://4n0nymou3.github.io/proxy-to-singbox-converter/)
  - Наборы правил Karing: [https://github.com/KaringX/karing-ruleset/tree/sing](https://github.com/KaringX/karing-ruleset/tree/sing)

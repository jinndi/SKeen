## Конфигурация sing-box на стороне сервера

В данном руководстве описывается конфигурация sing-box на сервере в Docker контейнере.

(дополняется)

### Почему не использовать панели управления?

- Любые WEB панели управления добавляют лишнюю сложность и уязвимости в инфраструктуру. Для сервера с sing-box для личного использования это избыточно.
- В контейнере sing-box настраивается через монтируемый конфигурационный файл и переменные окружения, это не требует дополнительных зависимостей или внешних сервисов, всё изолировано и безопасно.
- Ручная конфигурация более гибка и не зависит от интерфейса и поддержки со стороны разработчиков, которые могут в том числе затягивать с обновлениями или исправлением ошибок.

### Какие трудности для новичков?

- Необходимо изучить формат JSON конфигурации sing-box и его опции на стороне сервера.
- Требуется ручное обновление контейнера и конфигурационных файлов при изменени версий ядра (не всегда).

### Требования

- Доступ к серверу с установленным Docker
- Базовые навыки работы с командной строкой
- Знание структуры JSON файлов (для конфигурации)

**Необходимо установить Docker (вместе с Docker Compose) с помощью команды:**

```
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)
```

### Конфигурация Docker образа sing-box

1. Для начал создаем и переходим в папку где будет храниться наш файл `compose.yml`, в нашем примере это `/root/sing-box`

```
mkdir /root/sing-box && cd /root/sing-box
```

2. Создаем файл `compose.yml` через `nano` редактор (если не установлен - установите)

```
nano compose.yml
```

3. Копируем содержимое ниже и вставляем через `Ctrl + Shift + V`


```yaml
services:
  sing-box:
    # Официальный образ sing-box из GitHub Packages
    # После двоеточия можно указать определенную версию (тег):
    # см. https://github.com/SagerNet/sing-box/pkgs/container/sing-box
    image: ghcr.io/sagernet/sing-box:latest-testing

    # Понятное имя для контейнера в выводе команды `docker ps`
    container_name: sing-box

    # Автоматический перезапуск при падении ядра или перезагрузке самого сервера
    restart: unless-stopped

    # Контейнер использует сеть хоста напрямую.
    # Это избавляет от ручного проброса портов (ports:)
    network_mode: host

    volumes:
      # Конфигурационный файл (config.json)
      - /root/sing-box/config.json:/etc/sing-box/config.json

      # Папка для SSL-сертификатов (будут храниться полученные через ACME)
      - /root/sing-box/certmagic:/etc/ssl/certmagic/

      # Внешняя папка для уже существующих сертификатов (опционально)
      # - /etc/ssl/cert:/etc/ssl/certmagic/

    # Флаги запуска ядра sing-box:
    # -D задает рабочую директорию
    # -c указывает путь к файлу конфигурации
    # run запускает сервис
    command: -D /etc/sing-box -c config.json run

    cap_add:
      # Разрешает sing-box управлять сетью хоста
      - NET_ADMIN

      # Разрешает привязываться к системным портам (ниже 1024, например 80 или 443),
      # даже если процесс запущен не от root
      - NET_BIND_SERVICE
```

Можно предварительно отредактировать под себя, после вставки - сохраняем файл сочетанием клавиш `Ctrl + S` и выйдим из редактора через `Ctrl + X`.

На этом пока все, далее конфигурируем сам сервер sing-box.

### Конфигурация sing-box

В предыдущей главе мы настроили само окружение для запуска прокси ядра sing-box, далее мы сконфигурируем его для работы.

Для этого нам нужно создать файл `config.json` в нашей папке `/root/sing-box`

Ниже привожу пример как мы можем конфигурировать наш прокси сервер

```jsonc
{

  /// Блок настройки детализации логирования
  /// ВАЖНО!: После настройки задайте что то из: error, fatal или даже отключите логирование совсем.
  "log": {
    "disabled": false,   // Если true - отключает логирование
    "level": "info",     // Уровень логирования. Один из следующих: trace debug info warn error fatal panic.
    "timestamp": true    // Добавляет время к каждой строке лога.
  },

  /// Блок настройки провайдеров для получения и продления сертификатов.
  /// Ознакомьтесь пожалуйста с типами запросов https://letsencrypt.org/docs/challenge-types
  /// Выберите для себя нужные блоки т.к. представлены вариации для примерев использования.
  /// Вкратце, доступны следующие варианты:
  /// - HTTP-01: проверка через порт 80 (требуется доступ к порту 80)
  /// - TLS-ALPN-01: проверка через порт 443 (требуется доступ к порту 443)
  /// - DNS-01: проверка через DNS-записи (требуется API Cloudflare или аналог)
  /// - ZeroSSL: альтернативный провайдер с EAB учетными данными
  /// - Cloudflare Origin CA: бесплатный сертификат для трафика внутри сети Cloudflare
  "certificate_providers": [
    // 1. Сертификат через Let's Encrypt HTTP-01/TLS-ALPN-01
    // Самый простой способ получения сертификата
    // Требуется доступ к портам 80 и 443 для использования HTTP-01/TLS-ALPN-01 вызовов проверки
    {
      "tag": "LetsEncrypt",
      "type": "acme",
      "domain": "<ваш.домен.com>",
      "data_directory": "/etc/ssl/certmagic",
      "email": "<ваша@эл-почта.com>",
      "provider": "letsencrypt",
      "disable_tls_alpn_challenge": false,
      "disable_http_challenge": false
    },

    // 2. Сертификат через Let's Encrypt HTTP-01
    // https://letsencrypt.org/docs/challenge-types/#http-01-challenge
    // Проверка HTTP-01 возможна только на порту 80, а значит он должен быть открыт на сервере,
    // не всегда возможно (например, если порт 80 занят или заблокирован фаерволом)
    {
      "tag": "LetsEncrypt_HTTP",
      "type": "acme",
      "domain": "<ваш.домен.com>",
      "data_directory": "/etc/ssl/certmagic",
      "email": "<ваша@эл-почта.com>",
      "provider": "letsencrypt",
      "disable_tls_alpn_challenge": true,
      "disable_http_challenge": false
    },

    // 3. Сертификат через Let's Encryp TLS-ALPN-01
    // https://letsencrypt.org/docs/challenge-types/#tls-alpn-01
    // Этот метод использует порт 443 для верификации сертификата.
    // Не подходит многим, т.к. порт 443 обычно занят на сервере,
    // но можно использовать за обратным прокси сервером.
    {
      "tag": "LetsEncrypt_TLS",
      "type": "acme",
      "domain": "<ваш.домен.com>",
      "data_directory": "/etc/ssl/certmagic",
      "email": "<ваша@эл-почта.com>",
      "provider": "letsencrypt",
      "disable_tls_alpn_challenge": false,
      "disable_http_challenge": true
    },

    // 4. Сертификат через Let's Encrypt DNS-01
    // https://letsencrypt.org/docs/challenge-types/#dns-01-challenge
    // Этот метод использует DNS-записи для верификации домена.
    // Требуется:
    // 1. Домен, управляемый через Cloudflare (добавить A запись DNS без Proxied статуса)
    // 2. API токен Cloudflare с разрешением Zone:Read.
    {
      "tag": "LetsEncrypt_DNS",
      "type": "acme",
      "domain": "<ваш.домен.com>",
      "data_directory": "/etc/ssl/certmagic",
      "email": "<ваша@эл-почта.com>",
      "provider": "letsencrypt",
      // DNS-01 challenge для Cloudflare для верификации сертификата
      // Получить API токен Cloudflare можно в панели управления Cloudflare Dashboard > My Profile > API Tokens.
      // Ссылка на раздел: https://dash.cloudflare.com/profile/api-tokens
      "dns01_challenge": {
        "provider": "cloudflare",
        "api_token": "<ваш_API_токен_Cloudflare>",         // Необязательный API-токен с разрешением Zone:Read.
        //"zone_token": "<ваш_API_токен_зоны_Cloudflare>"  // При наличии этой опции позволяет ограничить область действия api_token одной зоной.
      }
    },

    // 5. Сертификат через ZeroSSL HTTP-01/TLS-ALPN-01/DNS-01
    // Настраивается по подобию с Let's Encrypt за исключением типа провайдера и на основе EAB учетных данных
    // Требуется:
    // Зарегистрироваться и залогиниться на https://zerossl.com
    // Сгенерировать https://app.zerossl.com/developer учетные данные EAB для клиентов ACME
    {
      "tag": "ZeroSSL",
      "type": "acme",
      "domain": "<ваш.домен.com>",
      "data_directory": "/etc/ssl/certmagic",
      "email": "<ваша@эл-почта.com>",
      "provider": "zerossl",
      "disable_tls_alpn_challenge": false, // Если true, отключает TLS-ALPN-01 challenge
      "disable_http_challenge": false,     // Если true, отключает HTTP-01 challenge
      // Учетные данные EAB
      "external_account": {
        "key_id": "<ваш_EAB_KID>",
        "mac_key": "<ваш_EAB_HMAC_Key>"
      },
      // Так же можно использовать DNS-01 challenge для Cloudflare для верификации сертификата,
      // либо удалить данный блок.
      "dns01_challenge": {
        "provider": "cloudflare",
        "api_token": "<ваш_API_токен_Cloudflare>"
      }
    },

    // 6. Сертификат Cloudflare Origin CA - бесплатный TLS-сертификат, подписанный Cloudflare.
    // ВАЖНО!: в РФ конфигурацию с Cloudflare Origin CA используют редко (IP-адреса самой Cloudflare в России находятся под прессингом.),
    // однако вполне можно использовать совместно с настройкой tls.spoof на легитимный домен в настройках outbouns клиента.
    // Этот сертификат является доверенными только для Cloudflare - если ваш исходный сервер получает трафик извне сети Cloudflare,
    // используйте вместо него общедоступный доверенный сертификат (напримеры выше, от Let's Encrypt и ZeroSSL).
    // Такой сертификат используется строго в одной конкретной схеме - когда ваш прокси-сервер полностью «спрятан» за сетью Cloudflare
    // (включено проксирование, оранжевое облако Proxied в панели DNS).
    // Что БУДЕТ работать: Протоколы, которые упакованы в стандартный веб-трафик - VLESS + WebSocket + TLS или Trojan + WebSocket + TLS,
    // а также gRPC-транспорт. Cloudflare легко пропустит их через свои CDN-сервера.
    // Что НЕ БУДЕТ работать: Протоколы REALITY (так как они требуют прямого TCP-соединения без посредников) и чистый VLESS-Vision
    // (Cloudflare разрушит TLS-структуру, необходимую Vision для маскировки). Также не будут работать стандартные типы подключения,
    // если они не используют CDN-совместимые порты (Cloudflare пропускает трафик только через определенный набор портов,
    // например: 443, 2053, 2083, 2087, 2096, 8443 TCP подробней https://developers.cloudflare.com/fundamentals/reference/network-ports/).
    {
      "tag": "CF_origin_ca",
      "type": "cloudflare-origin-ca",
      "domain": "<ваш_домен.com>",   // В Cloudflare добавляется только основной домен (второго уровня),
                                     // а уже внутри его панели в разделе DNS можно создавать нужные субдомены.
      "data_directory": "/etc/ssl/certmagic",
      // API токен Cloudflare для создания сертификата.
      // Получить или создать токен можно в панели управления Cloudflare Dashboard > My Profile > API Tokens.
      // Ссылка на раздел: https://dash.cloudflare.com/profile/api-tokens
      // Требуется разрешение на доступ к Zone / SSL and Certificates / Edit
      "api_token": "<ваш_API_токен_Cloudflare>",

      // Запрашиваемый срок действия сертификата в днях.
      // Доступные значения: 7, 30, 90, 365, 730, 1095, 5475.
      // Если 0 или ключ не указан, используется 5475 дней (15 лет).
      "requested_validity": 365
    }
  ],

  /// Блок настройки входящих соединений (inbounds)
  /// Определяет протоколы, порты и пользователей для входящего трафика.
  /// Выберите для себя нужные протоколы т.к. представлены вариации для примерев использования.
  /// ВАЖНО!: Не размещайте на 443 порту какой бы то ни было протокол,
  /// нет никаких доказательств того, что обнаруживаются и блокируются серверы на основе HTTP-ответов,
  /// использование стандартного порта HTTP/S на сервере представляет собой гораздо более значимый признак,
  /// а порты которые вы укажите - должны быть открыты извне вашим фаэрволом.
  /// Примеры конфигурации на стороне клиента: смотрите в файле `examples/v1.14/outbounds.json`
  "inbounds": [
    // 1. NaïveProxy HTTP2/QUIC
    {
      "type": "naive",
      "tag": "naive-in",
      "listen": "::",
      "listen_port": 1443,
      "users": [
        {
          "username": "<ваш_имя_пользователя>",
          "password": "<ваш_пароль>"
        }
      ],
      "quic_congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "server_name": "<ваш.домен.com>",
        "certificate_provider": "LetsEncrypt"
      }
    },

    // 2. Trojan-TLS + Multiplex
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "::",
      "listen_port": 2443,
      "users": [
        {
          "name": "<ваш_имя_пользователя>",
          "password": "<ваш_пароль>"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "<ваш.домен.com>",
        "certificate_provider": "ZeroSSL"
      },
      "multiplex": {
        "enabled": true
      }
    },

    // 3. Trojan-TLS-WS + Multiplex (для конфигурации за Cloudflare)
    {
      "type": "trojan",
      "tag": "trojan-cf-in",
      "listen": "::",
      "listen_port": 2096,
      "users": [
        {
          "name": "<ваш_имя_пользователя>",
          "password": "<ваш_пароль>"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "<ваш_домен.com>",
        "certificate_provider": "CF_origin_ca"
      },
      "transport": {
        "type": "ws",
        "path": "/secret-path",  // Ваш секретный путь, по которому Cloudflare поймет, что это ваш прокси
      },
      "multiplex": {
        "enabled": true
      }
    },

    // 4. Hysteria 2
    // Фишки и логика работы:
    // - Гигабитный канал: Сервер зажат в 1000 Mbps. На клиентах можно ставить скорость меньше.
    // - Умные буферы (окна в 0): Sing-box сам на лету адаптирует буфер под качество линии (4G/Wi-Fi).
    // - Оптимизация BBR (standard): Уменьшает потерю пакетов (packet loss) на нестабильных мобильных сетях.
    // - Маскарадинг (masquerade): Любой левый сканер или зонд получит HTTP-статус 451 (Unavailable For Legal Reasons).
    // Пароли и токены можно сгенерировать тут: https://openreplay.com/tools/token-generator/
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": 12443,
      "up_mbps": 1000,    // Лимит отдачи сервера (Upload) в сторону клиента для Brutal BBR
      "down_mbps": 1000,  // Лимит приема сервера (Download) от клиента для Brutal BBR
      "users": [
        {
          "name": "<ваш_имя_пользователя>",
          "password": "<ваш_пароль>"
        }
      ],
      "ignore_client_bandwidth": false,
      "tls": {
        "enabled": true,
        "server_name": "<ваш.домен.com>",
        "alpn": [ "h3" ],
        "certificate_provider": "LetsEncrypt"
      },
      "stream_receive_window": 0,
      "connection_receive_window": 0,
      "masquerade": {
        "type": "string",
        "status_code": 451,
        "content": "451 Unavailable For Legal Reasons\n\nThis endpoint is restricted. Your automated scanner activity has been logged and forwarded to the Committee for Digital Freedom. Have a nice day!"
      },
      // Обускация QUIC, 99% не работает в мобильной сети,
      // можете раскомментировать, настроить и протестировать.
      // "obfs": {
      //   "type": "gecko",
      //   "password": "<ваш_пароль_обфускации_quic>"
      // },
      "bbr_profile": "standard",
      "brutal_debug": false
    }

    // 5. Hysteria 2 с Realm на Cloudflare Workers
    // Фишки и логика работы:
    // - Гигабитный канал: Сервер зажат в 1000 Mbps. На клиентах можно ставить скорость меньше.
    // - Serverless-координатор на Workers: Realm крутится на cf-workers (*.workers.dev).
    // - Пробив любого NAT (Hole Punching): Белый IP и открытые порты не нужны.
    // - Умные буферы (окна в 0): Sing-box сам на лету адаптирует буфер под качество линии (4G/Wi-Fi).
    // - Оптимизация BBR (standard): Уменьшает потерю пакетов (packet loss) на нестабильных мобильных сетях.
    // - Маскарадинг (masquerade): Любой левый сканер или зонд получит HTTP-статус 451 (Unavailable For Legal Reasons).
    // Подробнее о технологии Realm: https://hysteria.network/ru/docs/advanced/Realms/
    {
      "type": "hysteria2",
      "tag": "hy2-realm-in",
      "listen": "::",
      "listen_port": 11443, // Данный UDP порт не нужно открывать в фаерволе.
      "up_mbps": 1000,    // Лимит отдачи сервера (Upload) в сторону клиента для Brutal BBR
      "down_mbps": 1000,  // Лимит приема сервера (Download) от клиента для Brutal BBR
      "users": [
        {
          "name": "<ваш_имя_пользователя>",
          "password": "<ваш_пароль>"
        }
      ],
      "ignore_client_bandwidth": false,
      "tls": {
        "enabled": true,
        "server_name": "<ваш.домен.com>",
        "alpn": [ "h3" ],
        "certificate_provider": "LetsEncrypt"
      },
      "stream_receive_window": 0,
      "connection_receive_window": 0,
      "masquerade": {
        "type": "string",
        "status_code": 451,
        "content": "451 Unavailable For Legal Reasons\n\nThis endpoint is restricted. Your automated scanner activity has been logged and forwarded to the Committee for Digital Freedom. Have a nice day!"
      },
      // Обускация QUIC, на 99% не работает в мобильной сети,
      // но можете раскомментировать, настроить и протестировать.
      // "obfs": {
      //   "type": "gecko",
      //   "password": "<ваш_пароль_обфускации_quic>"
      // },
      "bbr_profile": "standard",
      "brutal_debug": false,
      // Realm конфигурация
      // Создаем через Cloudflare Workers: https://github.com/outlook84/cf-hysteria-realm,
      // либо поднимаем на этом же либо другом сервере свой Realm сервис: смотрите ниже блок services
      "realm": {
        "server_url": "https://<ваш.домен>.workers.dev",
        "token": "<ваш_токен>",
        "realm_id": "<ваш_идентификатор>",
        // Список STUN-серверов для NAT Traversal
        "stun_servers": [
          "turn.cloudflare.com:3478",
          "stun.nextcloud.com:3478",
          "stun1.l.google.com:19302"
        ]
      }
    }

    // ... продолжение следует
  ],

  // При необходимости и возможноcти поднимает свой сервис Hysteria Realm
  "services": [
    {
      "type": "hysteria-realm",
      "tag": "hy2-realm-service",
      "listen": "::",
      "listen_port": 8080,
      "tls": {
        "enabled": true,
        "server_name": "<ваш.домен.com>",
        "certificate_provider": "LetsEncrypt"
      },
      "users": [
        {
          "name": "<ваш_имя>", // Выбранное вами имя realm. Должно быть длиной от 6 до 64 символов,
                               // начинаться с буквы или цифры и содержать только латинские буквы, цифры, - или _.
          "token": "<ваш_токен>", // Общий bearer-токен сервера рандеву.
          "max_realms": 10  // Максимальное количество слотов, которые этот пользователь может занимать одновременно.
        }
      ]
    }
  ]
}

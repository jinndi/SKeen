## Примеры настройки сервер-клиента №4

Конфигурация «Судного дня» на транспорте XHTTP с целью CDN-паразитирования за 60 копеек за гигабайт (другой причины использовать XHTTP я не вижу).

Прошаренные мамкины бизнесмены делают на этом деньги, продавая скрипт настройки за 5к рублей. Пожелаем им удачи и отдельного котла в аду.

### Что нам понадобится?

1. **Стороннее ядро sing-box.** Так как автор sing-box принципиально не добавляет транспорт XHTTP команды Xray в свой проект (и правильно делает), нам потребуется использовать стороннее ядро, а именно [sing-box-lx](https://github.com/Leadaxe/sing-box-lx). Порядок действий:

   * Заходим в релизы и качаем архив (Linux) под свою архитектуру, извлекаем его и помещаем файл `sing-box` в Entware, например по пути `/opt/bin/sing-box`.
   * В конфигурации `skeen.json` включаем опцию `singbox.external.enabled` и указываем в `singbox.external.path` путь, куда поместили наш файл (`/opt/bin/sing-box`). Также можно просто указать имя бинарника (`sing-box`).

2. **Серверная панель [3x-ui](https://github.com/MHSanaei/3x-ui).** Потому что у каждого нубаса она есть, но нам это не главное. Нам главное, что можно контролировать клиентов по трафику - ведь он деньги. Ну и само собой, она на Xray-ядре - для нашей схемки подходит.

3. **Свой VPS.** Ну тут очевидно: можно использовать зарубежный, чтобы не мутить каскад - он тут не нужен.

4. **Аккаунт в одной из немногих CDN.** Вы и сами знаете каких.


### Конфигурация nginx

1. Давайте подготовим nginx с директивой proxy_pass на наш будущий локально слушающий Xray-порт. Для начала установим его, выполнив в консоли на сервере:

```bash
sudo apt update && apt install nginx -y
```

2. Добавляем следующего вида конфигурацию nginx по пути `/etc/nginx/sites-available/default`, предварительно заменив всё, что там имеется:

```conf
server {
  listen 443 ssl http2 default_server;
  server_name _;
  # Указываем пути к сертификату и его ключу.
  # Я использую wildcard-сертификат ZeroSSL, полученный через ACME в sing-box.
  ssl_certificate      /root/certmagic/certificates/acme.zerossl.com-v2-dv90/wildcard_.mysite.com/wildcard_.mysite.com.crt;
  ssl_certificate_key  /root/certmagic/certificates/acme.zerossl.com-v2-dv90/wildcard_.mysite.com/wildcard_.mysite.com.key;

  ssl_protocols TLSv1.2 TLSv1.3;

  # Путь (path) /static/get/video/chunk.ts - для примера.
  # Используйте свой путь.
  location /static/get/video/chunk.ts {

    # Проксируем запросы на Xray, который слушает локально на порту 10112 по HTTPS.
    proxy_pass                       https://127.0.0.1:10112;
    proxy_http_version               1.1;

    # Заголовки, передаваемые на бэкенд Xray.
    proxy_set_header Host              cdn.mysite.com; # Укажите ваш домен/субдомен CDN.
    proxy_set_header Connection        "";
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Полностью отключаем буферизацию и кеширование проксируемых запросов.
    proxy_buffering                  off;
    proxy_request_buffering          off;
    proxy_cache                      off;
    chunked_transfer_encoding        on;
    gzip                             off;

    # Отключаем буферизацию ответа на стороне nginx и запрещаем кеширование.
    add_header X-Accel-Buffering     no always;
    add_header Cache-Control         "no-store, no-transform" always;

    # Увеличиваем таймауты для длительных соединений.
    proxy_read_timeout               1h;
    proxy_send_timeout               1h;
    client_max_body_size             0;
  }

  # Все остальные запросы отдаём как обычный сайт.
  location / {
    root /var/www/html;
    index index.html;
    try_files $uri $uri/ =404;
  }
}

server {
  listen 80 default_server;
  server_name _;

   # Перенаправляем HTTP-запросы на HTTPS.
  location / {
    return 301 https://$host$request_uri;
  }
}
```

Плюсом в /etc/nginx/nginx.conf заменяем блок events на следующий:

```conf
events {
  worker_connections 10240;
  use epoll;
  multi_accept on;
}
```

3. Загружаем ваш **реальный сайт** в папку `/var/www/html/`. Если у вас заглушка - можно пропустить этот шаг, ну либо загрузить её, если вам так спокойней )))

4. Выполняем проверку того, что там вставили в конфиг, и перезагружаем сам nginx:

```bash
nginx -t && systemctl restart nginx
```

### Конфигурация 3x-ui

1. Устанавливаем 3x-ui, используя команду из их репозитория:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

Сертификаты в ней задавайте самостоятельно. Я использую те же, что и в nginx, под другим сабдоменом.

2. Добавляем во входящих новое подключение через расширенный шаблон ниже:

```json
{
  "listen": "127.0.0.1",
  "port": 10112,
  "protocol": "vless",
  "tag": "in-10112-tcp",
  "settings": {
    "clients": [],
    "decryption": "none",
    "encryption": "none"
  },
  "sniffing": {
    "enabled": true,
    "destOverride": [
      "http",
      "tls",
      "quic",
      "fakedns"
    ]
  },
  "streamSettings": {
    "network": "xhttp",
    "xhttpSettings": {
      "path": "/static/get/video/chunk.ts",
      "host": "cdn.mysite.com",
      "mode": "packet-up",
      "xPaddingBytes": "100-1000",
      "xPaddingObfsMode": true,
      "xPaddingKey": "_dc",
      "xPaddingHeader": "X-Cache",
      "xPaddingPlacement": "header",
      "xPaddingMethod": "tokenish",
      "sessionIDPlacement": "header",
      "sessionIDKey": "X-Auth-Token",
      "sessionIDTable": "Base62",
      "sessionIDLength": "8",
      "seqPlacement": "query",
      "seqKey": "id",
      "uplinkDataPlacement": "",
      "uplinkDataKey": "",
      "scMaxEachPostBytes": "",
      "noSSEHeader": true,
      "scMaxBufferedPosts": 30,
      "scStreamUpServerSecs": "20-80",
      "serverMaxHeaderBytes": 0,
      "uplinkHTTPMethod": "GET",
      "headers": {},
      "scMinPostsIntervalMs": "20-80",
      "uplinkChunkSize": 0,
      "noGRPCHeader": true,
      "xmux": {
        "maxConcurrency": "",
        "maxConnections": "2",
        "cMaxReuseTimes": "",
        "hMaxRequestTimes": "1000-1200",
        "hMaxReusableSecs": "100-100",
        "hKeepAlivePeriod": 0
      },
      "enableXmux": true
    },
    "security": "tls",
    "tlsSettings": {
      "serverName": "cdn.mysite.com",
      "minVersion": "1.2",
      "maxVersion": "1.3",
      "cipherSuites": "",
      "rejectUnknownSni": false,
      "disableSystemRoot": false,
      "enableSessionResumption": false,
      "certificates": [
        {
          "certificateFile": "/root/certmagic/certificates/acme.zerossl.com-v2-dv90/wildcard_.mysite.com/wildcard_.mysite.com.crt",
          "keyFile": "/root/certmagic/certificates/acme.zerossl.com-v2-dv90/wildcard_.mysite.com/wildcard_.mysite.com.key",
          "ocspStapling": 0,
          "oneTimeLoading": false,
          "usage": "encipherment",
          "buildChain": false,
          "useFile": true
        }
      ],
      "alpn": [
        "h2"
      ],
      "echServerKeys": "",
      "settings": {
        "fingerprint": "firefox",
        "echConfigList": "",
        "pinnedPeerCertSha256": [],
        "verifyPeerCertByName": ""
      }
    },
    "externalProxy": [
      {
        "forceTls": "tls",
        "dest": "cdn.mysite.com",
        "port": 443,
        "remark": ""
      }
    ],
    "sockopt": {
      "tcpcongestion": "bbr",
      "trustedXForwardedFor": [
        "X-Real-IP"
      ],
      "acceptProxyProtocol": false,
      "tcpFastOpen": false,
      "mark": 0,
      "tproxy": "off",
      "tcpMptcp": false,
      "penetrate": false,
      "domainStrategy": "AsIs",
      "tcpMaxSeg": 0,
      "dialerProxy": "",
      "tcpKeepAliveInterval": 0,
      "tcpKeepAliveIdle": 0,
      "tcpUserTimeout": 0,
      "V6Only": false,
      "tcpWindowClamp": 0,
      "interface": "",
      "addressPortStrategy": "none",
      "customSockopt": []
    }
  }
}
```

В этом шаблоне выше измените в externalProxy[].dest на ваш домен CDN.

3. В настройках, во вкладке «Безопасность», укажите свой SNI (адрес CDN, далее его настроим) и пути к сертификатам. Я использую всё те же wildcard-сертификаты ZeroSSL, полученные через ACME в sing-box.

4. Создаём клиента и выбираем для него наше подключение.

# Конфигурация CDN

1. Необходимо создать ресурс на нашем домене. Я буду использовать субдомен, на котором и висит наш сайт в nginx. В нашем примере это `origin.mysite.com` - указываем его как HTTPS-источник на порту `443`. Обратите внимание: этот домен не должен находиться за другим CDN, например Cloudflare (жёлтое облако).

2. В домены раздачи вписываем новый субдомен. В нашем примере это `cdn.mysite.com`. Предварительно привязываем его через CNAME-запись в панели управления DNS вашего домена к выданному абракадабрскому адресу CDN.

3. Выпускаем Let's Encrypt-сертификат для привязанного домена из предыдущего шага.

4. Кеширование - полностью отключаем.

5. Редирект с HTTP на HTTPS можно включить.

Всё остальное нам не нужно!


# Конфигурация sing-box-lx

Для начала ознакомьтесь со [структурой полей транспорта XHTTP](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.ru.md#0-%D0%B2%D1%81%D0%B5-%D0%BF%D0%BE%D0%BB%D1%8F-%D1%80%D0%B0%D0%B7%D0%BE%D0%BC-%D0%B8%D1%81%D1%87%D0%B5%D1%80%D0%BF%D1%8B%D0%B2%D0%B0%D1%8E%D1%89%D0%B8%D0%B9-%D0%BF%D1%80%D0%B8%D0%BC%D0%B5%D1%80)) в sing-box-lx.

Далее - пример самого прокси-узла для подключения к нашему серверу:

```json
{
  "type": "vless",
  "tag": "😎 VLESS XHTTP CDN",
  "server": "cdn.mysite.com",
  "server_port": 443,
  "uuid": "9b42beab-9d41-44c5-9f45-fd9078ab02c1",
  "tls": {
    "enabled": true,
    "alpn": "h2",
    "server_name": "cdn.mysite.com",
    "utls": { "enabled": true, "fingerprint": "firefox" }
  },
  "transport": {
    "type": "xhttp",
    "mode": "packet-up",
    "host": "cdn.mysite.com",
    "path": "/static/get/video/chunk.ts",
    "no_grpc_header": true,
    "session_placement": "header",
    "session_key": "X-Auth-Token",
    "session_table": "Base62",
    "session_length": "8",
    "seq_placement": "query",
    "seq_key": "id",
    "uplink_http_method": "GET",
    "x_padding_bytes": "100-1000",
    "x_padding_obfs_mode": true,
    "x_padding_placement": "query",
    "x_padding_header": "X-Cache",
    "x_padding_key": "_dc",
    "x_padding_method": "tokenish",
    "sc_min_posts_interval_ms": "20-80",
    "xmux": {
      "max_connections": "2",
      "h_max_request_times": "1000-1200",
      "h_max_reusable_secs": "100-100"
    }
  }
}
```

Ну что ж, всё готово. Это обеспечит связь в день X, но не стоит использовать это решение на постоянной основе, т. к. сами эти многочисленные параметры являются экспериментальными и очень нестабильными, вызывая множество ошибок, в том числе при использовании Xray-ядра в качестве клиента.

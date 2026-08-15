## Примеры настройки сервера №2

Подробнее смотрите в файле [Server-sing-box.md](./Server-sing-box.md), тут только чистые шаблоны с фейковыми данными.

Что должны получить в итоге:

 0. Работа при блоке IP вашего сервера.
 1. Прокси`trojan` WebSocket за Cloudflare на субдомене `plex.mydomain.com`.
 2. `Sub-Store` панель на субдомене `sub.mydomain.com` через туннель Cloudflare.
 3. Серверный `API сервис sing-box` через туннель Cloudflare - для добавления в Zashboard панель в любом клиенте.
 4. Открытые порты на сервере: 443 и ssh порт.
 5. Опционально: Редирект (`Forwarding URL 301`) на сайт с основного `mydomain.com/*`  и суб. `plex.mydomain.com/`  доменов на `https://plex.tv` через правила `rules/page-rules` в Cloudflare.

### Файл compose.yml

Файл `compose.yml` на сервере для поднятия сервисов sing-box и sub-store через Docker Compose.

```yml
services:
  sing-box:
    image: ghcr.io/sagernet/sing-box:latest-testing
    container_name: sing-box
    restart: unless-stopped
    network_mode: host
    volumes:
      - /root/config.json:/etc/sing-box/config.json
      - /root/certmagic:/etc/ssl/certmagic/
    command: -D /etc/sing-box -c config.json run

  sub-store:
    image: xream/sub-store:http-meta
    container_name: sub-store
    restart: unless-stopped
    environment:
      SUB_STORE_BACKEND_API_HOST: 0.0.0.0
      SUB_STORE_BACKEND_API_PORT: 3001
      SUB_STORE_BACKEND_MERGE: true
      SUB_STORE_FRONTEND_BACKEND_PATH: /fKffdsfgMfdglmkf82LDfg0234fmD
      PORT: 9876
      HOST: 127.0.0.1
    network_mode: host
    volumes:
      - sub_store:/opt/app/data

volumes:
  sub_store:
```

### Файл config.json

Файл `config.json` на сервере для конфигурации сервера sing-box.

```json
{
  "log": {
    "disabled": false,
    "level": "fatal",
    "timestamp": true
  },
  "certificate_providers": [
    {
      "tag": "OriginCA",
      "type": "cloudflare-origin-ca",
      "domain": "mydomain.com",
      "data_directory": "/etc/ssl/certmagic",
      "api_token": "gtyf_GtrSBgTuHreWKoKqGduLpMgE0RpT4QCLs2K8sR84498Hr",
      "requested_validity": 730
    }
  ],
  "inbounds": [
    {
      "type": "cloudflared",
      "tag": "cf-tunnel-in",
      "token": "eyGhIyuiEjc2MDg3YTNlODHeNTJkNzM4JWHwVgI1NjU1NWY2YTkiLCJ0IjoiYTQ0MmY3ODUtN2EzMi00MmQ1LTllMGYtNmI1OTHjJWEwZWFlIiwfgtI6IllUWmlaREV7YmprdFltVXpZUzAwWkdWakxXSGhpOVFl8TWpVd1pUWmtNVEE1Tm1BHeJ1",
      "protocol": "http2",
      "edge_ip_version": 4
    },
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "name": "jinndi",
          "password": "ybvFZleivqii6sTx5dDJmA=="
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/apistreamgdfdcy"
      },
      "multiplex": {
        "enabled": true,
        "padding": true
      },
      "tls": {
        "enabled": true,
        "server_name": "plex.mydomain.com",
        "certificate_provider": "OriginCA"
      }
    }
  ],
  "services": [
    {
      "type": "api",
      "tag": "api",
      "listen": "127.0.0.1",
      "listen_port": 15225,
      "secret": "14843e4a59297a287040b857309d7ad9",
      "access_control_allow_private_network": true,
      "dashboard": true
    }
  ]
}
```

### Файла с прокси для клиентов в Sub-Store

Как добавить на выходе в вашу подписку эти прокси для клиентов смотрите в [Sub-Store-sync.md](./Sub-Store-sync.md)


```json
[
  {
    "tag": "😎 TROJAN CF",
    "type": "trojan",
    "password": "ybvFZleivqii6sTx5dDJmA==",
    "server": "plex.mydomain.com",
    "server_port": 443,
    "transport": {
      "type": "ws",
      "path": "/apistreamgdfdcy"
    },
    "multiplex": {
      "enabled": true,
      "protocol": "smux",
      "max_streams": 32,
      "padding": true
    },
    "tls": {
      "enabled": true,
      "server_name": "plex.mydomain.com",
      "spoof": "plex.tv",
      "utls": {
        "enabled": true,
        "fingerprint": "chrome"
      }
    }
  }
]
```

## Примеры настройки сервера №1

Подробнее смотрите в файле [Server-sing-box.md](./Server-sing-box.md), тут только чистые шаблоны с фейковыми данными.

Что должны получить в итоге:

 1. Три прокси протокола: `trojan` за Clouflare, `Naive` и `Hysteria2` на субдоменах с ECH и сертификатом ZeroSSL.
 2. `Sub-Store` панель на субдомене `sub.mydomain.com` через trojan fallback с сертификатом ZeroSSL.
 3. Серверный `API сервис sing-box` через туннель Clouflare - для добавления в Zashboard панель в любом клиенте.
 4. Открытые порты на сервере: 443, 2096, 4443, 8443 и ssh порт.
 5. Основной домен с сайтом через Workers & Pages.

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
    },
    {
      "tag": "ZeroSSL",
      "type": "acme",
      "domain": [ "mydomain.com", "*.mydomain.com" ],
      "data_directory": "/etc/ssl/certmagic",
      "email": "mymail@gmail.com",
      "provider": "zerossl",
      "external_account": {
        "key_id": "tui2hrd6br12lObrr8GfHr",
        "mac_key": "ht1fnGwvynGQWTb1ev2xGiRuhfgyBtfPymX1yW7w7x3va8T8FRXMBEjkGxRa-7N8HifvyHrNkAYJNWiMXMhj8Q"
      },
      "dns01_challenge": {
        "provider": "cloudflare",
        "api_token": "gtyf_deHTY9tGjtNOQyiDGbieGHRszf4ploGnE3huVkdg32d0ejy1"
      }
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
      "listen_port": 2096,
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
        "server_name": "trws.mydomain.com",
        "certificate_provider": "OriginCA"
      }
    },
    {
      "type": "naive",
      "tag": "naive-in",
      "listen": "::",
      "listen_port": 4443,
      "users": [
        {
          "username": "jinndi",
          "password": "ybvFZleivqii6sTx5dDJmA=="
        }
      ],
      "quic_congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "server_name": "n.mydomain.com",
        "certificate_provider": "ZeroSSL",
        "ech": {
          "enabled": true,
          "key": [
            "-----BEGIN ECH KEYS-----",
            "ACCwd/ByvkkmBiO/rS8SCkB4qCYRHYpvmrj2up53ImldlwBE/g0AQAAAIAAgVZ7M",
            "R4Lt44VaC9+h6tWu4UDFWZt3T/N2+UQg7ThBNjsADAABAAEAAQACAAEAAwAJeWFu",
            "ZGV4LnJ1AAA=",
            "-----END ECH KEYS-----"
          ]
        }
      }
    },
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": 8443,
      "users": [
        {
          "name": "jinndi",
          "password": "ybvFZleivqii6sTx5dDJmA=="
        }
      ],
      "masquerade": "http://127.0.0.1:3001",
      "ignore_client_bandwidth": true,
      "tls": {
        "enabled": true,
        "server_name": "h.mydomain.com",
        "certificate_provider": "ZeroSSL",
        "alpn": "h3",
        "ech": {
          "enabled": true,
          "key": [
            "-----BEGIN ECH KEYS-----",
            "ACCwd/ByvkkmBiO/rS8SCkB4qCYRHYpvmrj2up53ImldlwBE/g0AQAAAIAAgVZ7M",
            "R4Lt44VaC9+h6tWu4UDFWZt3T/N2+UQg7ThBNjsADAABAAEAAQACAAEAAwAJeWFu",
            "ZGV4LnJ1AAA=",
            "-----END ECH KEYS-----"
          ]
        }
      }
    },
    {
      "type": "trojan",
      "tag": "sub-store-fallback-in",
      "listen": "::",
      "listen_port": 443,
      "tls": {
        "enabled": true,
        "server_name": "sub.mydomain.com",
        "certificate_provider": "ZeroSSL"
      },
      "fallback": {
        "server": "127.0.0.1",
        "server_port": 3001
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
    "server": "trws.mydomain.com",
    "server_port": 2096,
    "transport": {
      "type": "ws",
      "path": "/apistreamgdfdcy"
    },
    "multiplex": {
      "enabled": true,
      "max_connections": 6,
      "max_streams": 48,
      "protocol": "h2mux",
      "padding": true
    },
    "tls": {
      "enabled": true,
      "server_name": "trws.mydomain.com",
      "certificate_public_key_sha256": "h5gyI4HTt2hyiwaqwuVu/B3lT8BeVdSD1anKwNhuSrT=",
      "spoof": "yandex.ru",
      "utls": {
        "enabled": true,
        "fingerprint": "chrome"
      }
    }
  },
  {
    "tag": "😎 NAIVE UoT ECH",
    "type": "naive",
    "server": "n.mydomain.com",
    "server_port": 4443,
    "username": "jinndi",
    "password": "ybvFZleivqii6sTx5dDJmA==",
    "udp_over_tcp": {
      "enabled": true,
      "version": 2
    },
    "tls": {
      "enabled": true,
      "server_name": "n.mydomain.com",
      "ech": {
        "enabled": true,
        "config": [
          "-----BEGIN ECH CONFIGS-----",
          "AET+DQBAAAAgACDVJeKtBLpyrY4QN/tFXSG9mjtP8jyf8WVGByBUHfysdwAMAAEA",
          "AQABAAIAAQADAAl5YW5kZXgucnUAAA==",
          "-----END ECH CONFIGS-----"
        ]
      }
    }
  },
  {
    "tag": "😎 NAIVE QUIC ECH",
    "type": "naive",
    "server": "n.mydomain.com",
    "server_port": 4443,
    "username": "jinndi",
    "password": "ybvFZleivqii6sTx5dDJmA==",
    "udp_over_tcp": false,
    "quic": true,
    "quic_congestion_control": "bbr",
    "tls": {
      "enabled": true,
      "server_name": "n.mydomain.com",
      "ech": {
        "enabled": true,
        "config": [
          "-----BEGIN ECH CONFIGS-----",
          "AET+DQBAAAAgACDVJeKtBLpyrY4QN/tFXSG9mjtP8jyf8WVGByBUHfysdwAMAAEA",
          "AQABAAIAAQADAAl5YW5kZXgucnUAAA==",
          "-----END ECH CONFIGS-----"
        ]
      }
    }
  },
  {
    "type": "hysteria2",
    "tag": "😎 HY2 ECH",
    "server": "n.mydomain.com",
    "server_port": 8443,
    "password": "ybvFZleivqii6sTx5dDJmA==",
    "tls": {
      "enabled": true,
      "server_name": "h.mydomain.com",
      "alpn": "h3",
      "ech": {
        "enabled": true,
        "config": [
          "-----BEGIN ECH CONFIGS-----",
          "AET+DQBAAAAgACBVnsxHgu3jhVoL36Hq1a7hQMVZm3dP83b5RCDtOEE2OwAMAAEA",
          "AQABAAIAAQADAAl5YW5kZXgucnUAAA==",
          "-----END ECH CONFIGS-----"
        ]
      }
    }
  }
]
```

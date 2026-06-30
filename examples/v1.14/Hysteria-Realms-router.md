## Конфигурация роутера в качестве сервера Hysteria2 c Realms

Здесь мы ознакомимся как поднять свой Hysteria сервер на роутере используя технологию Realms.

Подробнее про Realms можно прочитать в [официальной документации](https://hysteria.network/ru/docs/advanced/Realms/).

Главное преимущество - не нужен белый айпи адрес и открытие портов.

### Подготовка Realms

Есть несколько способов разместить Realms сервис:
- На роутере Keenetic/Netcraze
- На VPS-сервере
- На Cloudflare Workers

Наш Realms сервис будет размщен на роутере и доступен по адресу: `https://realms.keenetic.netcraze.pro` для клиентов извне.

Для этого в разделе "Доменное имя" панели роутера в разделе "Доступ к веб-приложениям домашней сети" задайте:

- Имя, в нашем примере будет: `realms`
- Доступ из интернета: Свободный доступ
- Устройство: Это устройство Keenetic(Netcraze)
- Протокол: `HTTPS`
- Порт, в нашем примере будет: `8443`

Для последних двух вариантов размещения - смотрите примеры в [файле настройки сервера](https://github.com/jinndi/SKeen/blob/main/examples/v1.14/Server-sing-box.md).

### Подготовка самоподписанного сертификата

Мы могли бы использовать сертификаты, которые создаёт сама служба KeenDNS/CrazeDNS, однако они не подойдут по причине того, что ключи в них зашифрованы и не применимы для настройки TLS. Вместо этого мы создадим самоподписанный сертификат.

Процесс его создания подробно описан в [примере настройки сервера](https://github.com/jinndi/SKeen/blob/main/examples/v1.14/Server-sing-box.md#%D1%81%D0%B0%D0%BC%D0%BE%D0%BF%D0%BE%D0%B4%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%BD%D1%8B%D0%B9-%D1%81%D0%B5%D1%80%D1%82%D0%B8%D1%84%D0%B8%D0%BA%D0%B0%D1%82).

Ниже продублирована краткая инструкция, все команды выполняются **через SSH в окружении Entware на роутере**:

1. Создание папки для самих сертификатов, пусть это будет `/opt/etc/skeen/ssl/`

```bash
mkdir -p /opt/etc/skeen/ssl/
```

2. Создаём чистый сертификат со сроком действия 5 лет, в поле /CN= **указываем домен `realms.keenetic.netcraze.pro`**:

```bash
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /opt/etc/skeen/ssl/self.key \
  -out /opt/etc/skeen/ssl/self.crt \
  -subj "/CN=realms.keenetic.netcraze.pro" \
  -days 1825
```
3. Поскольку мы уже сгенерировали самоподписанный сертификат, снимем SHA-256 хэш его открытого ключа в формате Base64, передав утилите `openssl` файл сертификата `self.crt` (не путайте его с приватным ключом `self.key`):

```bash
openssl x509 -in /opt/etc/skeen/ssl/self.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

Полученную строку **необходимо сохранить** - она понадобится для настройки подключения клиентов.

### Настройка sing-box в Keenetic/Netcraze:

```jsonc
{
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-realm-in",
      "listen": "::",
      "listen_port": 17443, // Данный UDP порт и любой другой, который укажите - не нужно открывать в фаерволе.
      "up_mbps": 100,       // Лимит отдачи сервера (Upload) в сторону клиента для Brutal BBR
      "down_mbps": 100,     // Лимит приема сервера (Download) от клиента для Brutal BBR
      "users": [
        {
          "name": "<ваш_имя_пользователя>",
          "password": "<ваш_пароль>"
        }
      ],
      "ignore_client_bandwidth": false,
      "tls": {
        "enabled": true,
        "server_name": "realms.keenetic.netcraze.pro", // изменить на домен самоподписанного сертификата
        "alpn": [ "h3" ],
        // изменить на пути к вашим самопоподписанным сертификатам
        "certificate_path": "/opt/etc/skeen/ssl/self.crt", // сам сертификат
        "key_path": "/opt/etc/skeen/ssl/self.key" // ключ сертификата
      },
      "stream_receive_window": 0,
      "connection_receive_window": 0,
      "masquerade": {
        "type": "string",
        "status_code": 451,
        "content": "451 Unavailable For Legal Reasons\n\nThis endpoint is restricted. Your automated scanner activity has been logged and forwarded to the Committee for Digital Freedom. Have a nice day!"
      },

      // Обфускация QUIC, на 99% не работает в мобильной сети,
      // но можете раскомментировать, настроить и протестировать.
      // "obfs": {
      //   "type": "gecko",
      //   "password": "<ваш_пароль_обфускации_quic>"
      // },

      // Данные подключения к Realm с поднятом на вашем роутере/vps-сервере или Cloudflare Workers
      "realm": {
        "server_url": "https://realms.keenetic.netcraze.pro",
        "token": "<ваш_токен>",
        "realm_id": "<ваш_идентификатор>",
        // Список STUN-серверов для NAT Traversal
        "stun_servers": [
          "stun.sipnet.ru:3478",
          "stun.miwifi.com:3478",
          "stun.nextcloud.com:3478"
        ]
      }
    }
  ],

  /// Hysteria Realms сервис на роутере
  "services": [
    {
      "type": "hysteria-realm",
      "tag": "hy2-realm-service",
      "listen": "0.0.0.0",
      "listen_port": 8443,
      "tls": {
        "enabled": true,
        "server_name": "realms.keenetic.netcraze.pro", // изменить на домен самоподписанного сертификата
        // изменить на пути к вашим самопоподписанным сертификатам
        "certificate_path": "/opt/etc/skeen/ssl/self.crt", // сам сертификат
        "key_path": "/opt/etc/skeen/ssl/self.key" // ключ сертификата
      },
      "users": [
        {
          "name": "<ваш_имя>",    // Выбранное вами имя realm (realm_id). Должно быть длиной от 6 до 64 символов,
                                  // начинаться с буквы или цифры и содержать только латинские буквы, цифры, - или _.
          "token": "<ваш_токен>", // Общий bearer-токен сервера рандеву.
          "max_realms": 10        // Максимальное количество слотов, которые этот пользователь может занимать одновременно.
        }
      ]
    }
  ]
}
```

### Настройка узла в outbonds на стороне клинета (другого роутера, смарфона и тд на основе sing-box):

```jsonc
{
  "type": "hysteria2",
  "tag": "hy2-router-realm",
  "up_mbps": 15,    // Максимальная скорость отдачи (Upload) твоего провайдера для Brutal BBR
  "down_mbps": 50,  // Максимальная скорость скачивания (Download) твоего провайдера для Brutal BBR
  "password": "<ваш_пароль>",
  // Если на сервере включена обфускация QUIC (не для мобильных сетей)
  // "obfs": {
  //   "type": "gecko",
  //   "password": "<ваш_пароль_обфускации_quic>"
  // },
  "tls": {
    "enabled": true,
    "server_name": "realms.keenetic.netcraze.pro",
    "alpn": [ "h3" ],
    "certificate_public_key_sha256": "<хэш_публичного_ключа>"
  },
  "stream_receive_window": 0,
  "connection_receive_window": 0,
  "realm": {
    "server_url": "https://realms.keenetic.netcraze.pro",
    "token": "<ваш_токен>",
    "realm_id": "<ваш_идентификатор>",
    // Список STUN-серверов для NAT Traversal
    "stun_servers": [
      "stun.sipnet.ru:3478",
      "stun.miwifi.com:3478",
      "stun.nextcloud.com:3478"
    ]
  }
}
```

На этом всё!

> ⚠️ **ВАЖНО:** Установление соединения («пробитие» NAT с обеих сторон) может занять некоторое время после запуска. Как только соединение будет установлено, связь станет стабильной.

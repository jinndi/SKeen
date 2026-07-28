## Пример синхронизации конфигурации с помощью Sub-Store

**Спешиал фор Россия**

Чтобы обеспечить стабильную работу в условиях современной интернет-цензуры, пора уже забыть про наивную веру в один собственный сервер с поднятым VLESS XHTTP. Гораздо эффективнее использовать пул из десятков или сотен прокси-узлов, собранных из кучи разных подписок. Беспомощный формат «добавить одну ссылочку вида `vless://` через очередной веб-интерфейсик» в текущих реалиях - это путь в тупик при первом же чихе на ТСПУ, оставляющий вас вообще без связи. И если вас это безумие ещё почему-то не коснулось, то это лишь вопрос времени. Именно для гибкого управления огромным пулом прокси узлов и необходим `Sub-Store`.

Помимо конструирования конфигов и их локальной синхронизации с помощью программы `GUI.for.SingBox` и моего плагина [sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen) (в настоящее время только для стабильной версии Sing-box), вы также можете настроить удалённую синхронизацию конфигурации sing-box из `Sub-Store` с помощью команды `skeen sync`.

### Настройка Sub-Store

1. Устанавливаем [Sub-Store](https://github.com/jinndi/Sub-Store-Docker) на сервер.

2. Настраиваем `Sub-Store`:

  - **`Профиль`**: Во-первых, переключитесь на русский язык (в меню слева самая последняя вкладка - `Профиль`, там вверху справа будет значок переключения).

  - **`Подписки`**: Создаём подписку (первая вкладка - **Подписки**). Доступно добавление по ссылке (**Удаленный URL**) либо локальная вставка (**Локальный**), можно использовать и то и другое сразу указав тип в **Слияние источников**. В поле **Имя (ID)** вводим название на английском - допустим, `mysub`. Запомним его и сохраним настройки кнопкой внизу, завершив добавление подписки.

  > Вы можете объединить несколько подписок в коллекцию, если это необходимо, а также настроить фильтрацию и сортировку в самой подписке или коллекции. В общем, советую ознакомиться с этим мощным инструментом, у которого просто нет аналогов - его популярность в КНР не даст соврать.

  - **`Файлы`**: Переходим во вкладку **Файлы**, нажимаем сверху на `+` и выбираем в появившемся боковом меню **Файл**. Задаём имя на английском в поле **Имя (ID)** (например, `router`). Ниже убеждаемся, что в поле **Тип** выбрано значение **Файл**, а не **Профиль Mihomo**. Затем в поле **Источник** переключаемся в режим **Локальный**.

  **Добавляем следующий базовый шаблон в поле ввода:**

  > Вы можете использовать любой собственный вариант - отредактированный или дополненный. Единственное, что необходимо, - это наличие структуры блока `outbounds`, схожей с примером. Если вы любите конструировать, создайте шаблон через `GUI.for.SingBox` и скопируйте его с помощью плагина [sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen).


```jsonc
{
  "$schema": "https://sing-box.sagernet.org/schema.json",

  "log": { "level": "trace", "output": "", "timestamp": false },

  "dns": {
    "servers": [
      {
        "tag": "hosts", "type": "hosts",
        "predefined": {
          "cloudflare-dns.com": [ "104.16.248.249", "104.16.249.249" ],
          "dns.quad9.net": [ "9.9.9.9", "149.112.112.112" ],
          "dns.google": [ "8.8.8.8", "8.8.4.4" ],
          "common.dot.dns.yandex.net": [ "77.88.8.8", "77.88.8.1" ]
        }
      },
      { "tag": "dns_local",    "type": "local" },
      { "tag": "dns_direct",   "type": "https",  "server": "common.dot.dns.yandex.net", "domain_resolver": "hosts" },
      { "tag": "dns_proxy_cf", "type": "https",  "server": "cloudflare-dns.com", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_proxy_q9", "type": "https",  "server": "dns.quad9.net", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_proxy_gg", "type": "https",  "server": "dns.google", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_fakeip",   "type": "fakeip", "inet4_range": "198.18.0.0/15" }
    ],

    "rules": [
      { "preferred_by": "hosts", "server": "hosts" },
      { "query_type": "A", "invert": true, "action": "reject" },
      { "rule_set": "ipdetect", "action": "reject" },
      { "domain_keyword": [ "keenetic", "netcraze" ], "server": "dns_local" },
      { "rule_set": "private", "server": "dns_local" },
      { "clash_mode": "Direct", "server": "dns_direct" },
      { "rule_set": "adguard", "action": "predefined" },
      { "rule_set": "cheburnet", "server": "dns_direct" },
      { "rule_set": "trackers", "server": "dns_direct" },
      { "rule_set": "filter", "server": "dns_direct" },
      { "rule_set": [ "games", "ai", "proxy" ], "rewrite_ttl": 300, "server": "dns_fakeip" },
      { "action": "evaluate", "server": "dns_proxy_cf", "tag": "final-cf", "client_subnet": "77.88.8.0/24" },
      { "action": "evaluate", "server": "dns_proxy_q9", "tag": "final-q9", "client_subnet": "77.88.8.0/24" },
      { "action": "evaluate", "server": "dns_proxy_gg", "tag": "final-gg", "client_subnet": "77.88.8.0/24" },
      { "match_response": "final-cf", "rule_set": "ruip", "action": "respond", "race": true },
      { "match_response": "final-q9", "rule_set": "ruip", "action": "respond", "race": true },
      { "match_response": "final-gg", "rule_set": "ruip", "action": "respond", "race": true },
      { "server": "dns_fakeip" },
      { "clash_mode": "Global", "server": "dns_fakeip" }
    ],

    "final": "dns_proxy_cf",
    "strategy": "ipv4_only",
    "timeout": "10s",
    "cache_capacity": 16384,
    "optimistic": {
      "enabled": true,
      "timeout": "5m0s"
    },
    "reverse_mapping": true
  },

  "ntp": {
    "enabled": true,
    "interval": "30m0s",
    "server": "ntp.msk-ix.ru",
    "server_port": 123,
    "detour": "🇷🇺 RU"
  },

  "http_clients": [
    {
      "tag": "default",
      "version": 2,
      "detour": "GLOBAL",
      "stream_receive_window": 0,
      "connection_receive_window": 0
    }
  ],

  "inbounds": [
    {
      "tag": "tproxy-in",
      "type": "tproxy",
      "listen": "::",
      "listen_port": 65082
    }
  ],

  "outbounds": [
    { "tag": "🌍 Proxy",   "type": "selector", "outbounds": [] },
    { "tag": "🇷🇺 RU",      "type": "selector", "outbounds": [] },
    { "tag": "🏴‍☠️ Torrent", "type": "selector", "outbounds": [] },
    { "tag": "🕹️ Games",   "type": "selector", "outbounds": [] },
    { "tag": "🤖 AI",      "type": "selector", "outbounds": [] },
    { "tag": "🔌 DIRECT",  "type": "selector", "outbounds": [] },

    { "tag": "DIRECT", "type": "direct", "domain_resolver": "dns_direct" },
    { "tag": "GLOBAL", "type": "selector", "outbounds": [ "🌍 Proxy" ] },

    { "tag": "🌍 Auto", "type": "urltest", "outbounds": [], "interval": "10m", "tolerance": 100 },
    { "tag": "🇷🇺 Auto", "type": "urltest", "outbounds": [], "interval": "10m", "tolerance": 100 }
  ],

  "route": {
    "rules": [
      { "network": "icmp", "outbound": "🔌 DIRECT" },
      { "action": "sniff", "timeout": "500ms" },
      { "action": "hijack-dns", "type": "logical", "mode": "or", "rules": [ { "protocol": "dns" }, { "port": 53 } ] },
      { "ip_version": 6, "action": "reject" },
      { "port": [ 853, 5353 ], "action": "reject" },
      { "rule_set": "ipdetect", "action": "reject" },
      { "clash_mode": "Direct", "outbound": "🔌 DIRECT" },
      { "rule_set": "private", "outbound": "🔌 DIRECT" },
      { "rule_set": "cheburnet", "outbound": "🔌 DIRECT" },
      { "protocol": "ntp", "outbound": "🇷🇺 RU" },
      { "protocol": "bittorrent", "outbound": "🏴‍☠️ Torrent" },
      { "rule_set": "games", "outbound": "🕹️ Games" },
      { "rule_set": "ai", "outbound": "🤖 AI" },
      { "ip_is_private": true, "outbound": "🔌 DIRECT" },
      { "ip_cidr": "198.18.0.0/15", "outbound": "🌍 Proxy" },
      { "rule_set": "proxy", "outbound": "🌍 Proxy" },
      { "rule_set": [ "ru", "ruip" ], "outbound": "🇷🇺 RU" },
      { "protocol": [ "stun", "dtls" ], "action": "reject", "method": "drop" },
      {
        "type": "logical", "mode": "or",
        "rules": [
          { "network": "udp", "port": [ 3478, 5349, 5350, 19302, 10000 ] },
          { "domain_regex": "^stun\\..+" },
          { "domain_keyword": [ "stun", "turn", "httpdns" ] }
        ],
        "action": "reject", "method": "drop"
      },
      { "action": "route-options", "udp_disable_domain_unmapping": true, "udp_connect": true },
      { "action": "resolve", "timeout": "5s" },
      { "clash_mode": "Global", "outbound": "🌍 Proxy" }
    ],

    "rule_set": [
      {
        "type": "remote",
        "tag": [ "ipdetect", "private", "adguard", "cheburnet", "trackers", "filter", "games", "ai", "proxy", "ru", "ruip" ],
        "url": "https://cdn.jsdelivr.net/gh/jinndi/singbox_ruleset@main/{tag}.srs",
        "update_interval": "48h0m0s"
      }
    ],

    "final": "🌍 Proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "dns_direct",
    "default_http_client": "default"
  },

  "services": [
    {
      "type": "api",
      "tag": "api",
      "listen": "::",
      "listen_port": 9998,
      "access_control_allow_private_network": true,
      "dashboard": false
    }
  ],

  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "cache.db",
      "cache_id": "v1_14",
      "store_fakeip": true,
      "store_dns": true
    },

    "clash_api": {
      "external_controller": "0.0.0.0:9999",
      "external_ui": "zashboard",
      "external_ui_download_url": "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip",
      "external_ui_download_detour": "GLOBAL",
      "default_mode": "Rule"
    },

    "debug": {
      "gc_percent": 100,
      "memory_limit": "200MB"
    }
  }
}
```

  - **`Файлы` `Скрипт-модификатор (JS)`**: Там же, но чуть ниже будет карточка с заголовком **Добавить действие**. В ней выбираем **Скрипт-модификатор (JS)**. Появится новое окно ввода выше - переключаемся в нём на вкладку **Локальный скрипт** и вставляем следующий шаблон:


```javascript
//// Указываем имена ваших подписок/коллекций
// ВАЖНО: Теги прокси-узлов из подписок не должны дублироваться!
const subName = "mysub" // для зарубежных прокси
const subNameRU = "mysub_ru" // для российских прокси

////////////////////////////////////////////////////////////

// 1. Загружаем прокси из подписок/коллекций
let singboxProxies = []
try {
  singboxProxies = await produceArtifact({
    type: "collection", // если у вас подписка замените на 'subscription'
    name: subName,
    platform: "sing-box",
    produceType: "internal"
  })
} catch (e) {
  throw new Error(`Не удалось загрузить подписку '${subName}'. Проверьте имя во вкладке подписки.`)
}

// Пример добавления в singboxProxiesEU из другого файла вручную сконфигурированных прокси узлов,
// в формате массива outbounds (по примеру как в файле примера client-outbounds.jsonc)
// const mainOutbounds = (ProxyUtils.JSON5 || JSON).parse(await produceArtifact({
//  type: 'file',
//  name: 'my_name' // Ваше имя файла (ID)
// }))
// singboxProxiesEU.unshift(...mainOutbounds)

// дополнительно для RU серверов
let singboxProxiesRU = []
try {
  singboxProxiesRU = await produceArtifact({
    type: "collection", // если у вас подписка замените на 'subscription'
    name: subNameRU,
    platform: "sing-box",
    produceType: "internal"
  })
} catch (e) {
  throw new Error(`Не удалось загрузить подписку '${subNameRU}'. Проверьте имя во вкладке подписки.`)
}

// 2. Парсим шаблон (вставленный ранее как основа конфига)
let config
try {
  config = JSON.parse($files[0])
} catch (e) {
  throw new Error("Ошибка парсинга шаблона: " + e.message)
}

// 3. Извлекаем только имена (теги) всех прокси, чтобы добавить их в группы
let allProxyTags = singboxProxies.map(p => p.tag)
let allProxyTagsRU = singboxProxies.map(p => p.tag)

// 4. Находим и заполняем outbounds группы селекторов/urltest нашего шаблона
// (тут нужно отредактировать, если вы меняли предложенный шаблон на свои группы селекторов/urltest)
config.outbounds.find(p => p.tag === '🌍 Proxy')?.outbounds?.push('🌍 Auto', ...allProxyTags)
config.outbounds.find(p => p.tag === '🇷🇺 RU')?.outbounds?.push('🇷🇺 Auto', '🔌 DIRECT', ...allProxyTagsRU)
config.outbounds.find(p => p.tag === '🏴‍☠️ Torrent')?.outbounds?.push('🌍 Auto', '🔌 DIRECT', ...allProxyTags)
config.outbounds.find(p => p.tag === '🕹️ Games')?.outbounds?.push('🌍 Auto', '🔌 DIRECT', ...allProxyTags)
config.outbounds.find(p => p.tag === '🤖 AI')?.outbounds?.push('🌍 Auto', '🔌 DIRECT', ...allProxyTags)
config.outbounds.find(p => p.tag === '🌍 Auto')?.outbounds?.push(...allProxyTags)
config.outbounds.find(p => p.tag === '🇷🇺 Auto')?.outbounds?.push(...allProxyTagsRU)

// 5. Добавляем в самый конец сами узлы прокси-серверов из подписки/коллекции
config.outbounds.push(...singboxProxies, ...singboxProxiesRU)

// 6. Результат отдаем дальше
$content = JSON.stringify(config, null, 2)
```

В этом шаблоне требуется только укзатаь имя ранее созданных подписок/коллекций в начале:

```javascript
const subName = "mysub" // для зарубежных прокси
const subNameRU = "mysub_ru" // для российских прокси
```

И проверьте в пункте 1 (Загружаем прокси из подписок/коллекций) - там должно быть `type: "collection"`, или укажите `"subscription"`, если у вас тип «подписка».

После чего сохраните ваш файл кнопкой **Сохранить** внизу.

  - **`Поделиться`**: Последний этап настрпойки `Sub-Store` - создание ссылки на готовую подписку (**Файл**). Переходим во вкладку **Поделиться**, нажимаем на кнопку **Создать**. Далее в появившемся окне в поле **Источник** выбираем **Файл**, а затем - ваш созданный в предыдущем пункте файл (`router`). Задаём срок действия в поле **Срок действия** (количество дней/месяцев и т. д. в зависимости от выбранного режима в **Режим истечения срока**) и нажимаем **Создать ссылку**. Подписка готова! Она появится в списке вкладки **Поделиться**, скопировать ссылку можно нажатием на значок копирования.


### Настройка SKeen

Допустим, при настройке `Sub-Store` мы получили ссылку на синхронизацию нашей конфигурации для `sing-box` вида `https://mydomain.ydns.eu/share/file/router?token=22kiO29piehSe2105yYYR`.

1. Редактируем и сохраняем в `skeen.json` секцию `sing_config`:

```json
  "sing_config":{
    "enable": 1,
    "path": "/opt/etc/skeen/config.json",
    "sync_url": "https://mydomain.ydns.eu/share/file/router?token=22kiO29piehSe2105yYYR"
  }
```

2. Выполняем команду синхронизации из SSH Entware (или из WEB CLI роутера добавив `exec` в начале):

```sh
skeen sync
```

3. Перезагружаем SKeen

```sh
skeen restart
```

Поздравляем, вы стали продвинутым пользователем!

### Бонус: Шаблоны для Windows/Linux ПК и Android смартфонов.

Начиная **с версии sing-box 1.14.0-alpha.45** доступен графический клиент для `Windows`, для `Linux` **начиная с 1.14.0-alpha.48**.

Ниже пример шаблона для настольных клиентов Linux/Windows, отличие от шаблона для роутера только в:

 - `inbouns`: вместо `tproxy` используется `tun`
 - отсутвия блока `services` и `experimental.clash_api`
 - Увеличено в два раза значение `experimental.debug.memory_limit`.

> Вы также можете дополнительно использовать больше правил и действий доступных в таких средах, например  маршрутизацию по процессам в зависимости от используемой системы (`process_*`)


```jsonc
{
  "$schema": "https://sing-box.sagernet.org/schema.json",

  "log": { "level": "trace", "output": "", "timestamp": true },

  "dns": {
    "servers": [
      {
        "tag": "hosts", "type": "hosts",
        "predefined": {
          "cloudflare-dns.com": [ "104.16.248.249", "104.16.249.249" ],
          "dns.quad9.net": [ "9.9.9.9", "149.112.112.112" ],
          "dns.google": [ "8.8.8.8", "8.8.4.4" ],
          "common.dot.dns.yandex.net": [ "77.88.8.8", "77.88.8.1" ]
        }
      },
      { "tag": "dns_local",    "type": "local" },
      { "tag": "dns_direct",   "type": "https",  "server": "common.dot.dns.yandex.net", "domain_resolver": "hosts" },
      { "tag": "dns_proxy_cf", "type": "https",  "server": "cloudflare-dns.com", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_proxy_q9", "type": "https",  "server": "dns.quad9.net", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_proxy_gg", "type": "https",  "server": "dns.google", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_fakeip",   "type": "fakeip", "inet4_range": "198.18.0.0/15" }
    ],

    "rules": [
      { "preferred_by": "hosts", "server": "hosts" },
      { "query_type": "A", "invert": true, "action": "reject" },
      { "rule_set": "ipdetect", "action": "reject" },
      { "domain_keyword": [ "keenetic", "netcraze" ], "server": "dns_local" },
      { "rule_set": "private", "server": "dns_local" },
      { "clash_mode": "Direct", "server": "dns_direct" },
      { "rule_set": "adguard", "action": "predefined" },
      { "rule_set": "cheburnet", "server": "dns_direct" },
      { "rule_set": "trackers", "server": "dns_direct" },
      { "rule_set": "filter", "server": "dns_direct" },
      { "rule_set": [ "games", "ai", "proxy" ], "rewrite_ttl": 300, "server": "dns_fakeip" },
      { "action": "evaluate", "server": "dns_proxy_cf", "tag": "final-cf", "client_subnet": "77.88.8.0/24" },
      { "action": "evaluate", "server": "dns_proxy_q9", "tag": "final-q9", "client_subnet": "77.88.8.0/24" },
      { "action": "evaluate", "server": "dns_proxy_gg", "tag": "final-gg", "client_subnet": "77.88.8.0/24" },
      { "match_response": "final-cf", "rule_set": "ruip", "action": "respond", "race": true },
      { "match_response": "final-q9", "rule_set": "ruip", "action": "respond", "race": true },
      { "match_response": "final-gg", "rule_set": "ruip", "action": "respond", "race": true },
      { "server": "dns_fakeip" },
      { "clash_mode": "Global", "server": "dns_fakeip" }
    ],

    "final": "dns_proxy_cf",
    "strategy": "ipv4_only",
    "timeout": "10s",
    "cache_capacity": 16384,
    "optimistic": {
      "enabled": true,
      "timeout": "5m0s"
    },
    "reverse_mapping": true
  },

  "ntp": {
    "enabled": true,
    "interval": "30m0s",
    "server": "ntp.msk-ix.ru",
    "server_port": 123,
    "detour": "🇷🇺 RU"
  },


  "http_clients": [
    {
      "tag": "default",
      "version": 2,
      "detour": "GLOBAL",
      "stream_receive_window": 0,
      "connection_receive_window": 0
    }
  ],

  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "address": "172.18.0.1/30",
      "loopback_address": "10.7.0.1",
      "mtu": 1500,
      "dns_mode": "hijack",
      "dns_address": "172.18.0.2",
      "auto_route": true,
      "auto_redirect": true, // ВАЖНО!: в Windows поставить значение false
      "strict_route": true,
      "stack": "mixed",
      "udp_nat_max": 4096,
      "endpoint_independent_nat": true
    }
  ],

  "outbounds": [
    { "tag": "🌍 Proxy",   "type": "selector", "outbounds": [] },
    { "tag": "🇷🇺 RU",      "type": "selector", "outbounds": [] },
    { "tag": "🏴‍☠️ Torrent", "type": "selector", "outbounds": [] },
    { "tag": "🕹️ Games",   "type": "selector", "outbounds": [] },
    { "tag": "🤖 AI",      "type": "selector", "outbounds": [] },
    { "tag": "🔌 DIRECT",  "type": "selector", "outbounds": [ "DIRECT" ] },

    { "tag": "DIRECT", "type": "direct" },
    { "tag": "GLOBAL", "type": "selector", "outbounds": [ "🌍 Proxy" ] },

    { "tag": "🌍 Auto", "type": "urltest", "outbounds": [], "interval": "30m", "tolerance": 100 },
    { "tag": "🇷🇺 Auto", "type": "urltest", "outbounds": [], "interval": "10m", "tolerance": 100 }
  ],

 "route": {
    "rules": [
      { "network": "icmp", "outbound": "🔌 DIRECT" },
      { "action": "sniff", "timeout": "500ms" },
      { "type": "logical", "mode": "or", "rules": [ { "protocol": "dns" }, { "port": 53 } ] },
      { "ip_version": 6, "action": "reject" },
      { "port": [ 853, 5353 ], "action": "reject" },
      { "rule_set": "ipdetect", "action": "reject" },
      { "clash_mode": "Direct", "outbound": "🔌 DIRECT" },
      { "rule_set": "private", "outbound": "🔌 DIRECT" },
      { "protocol": "ntp", "outbound": "🇷🇺 RU" },
      { "rule_set": "cheburnet", "outbound": "🔌 DIRECT" },
      { "protocol": "bittorrent", "outbound": "🏴‍☠️ Torrent" },
      { "rule_set": "games", "outbound": "🕹️ Games" },
      { "rule_set": "ai", "outbound": "🤖 AI" },
      { "ip_is_private": true, "outbound": "🔌 DIRECT" },
      { "ip_cidr": "198.18.0.0/15", "outbound": "🌍 Proxy" },
      { "rule_set": "proxy", "outbound": "🌍 Proxy" },
      { "rule_set": [ "ru", "ruip" ], "outbound": "🇷🇺 RU" },
      { "protocol": [ "stun", "dtls" ], "action": "reject", "method": "drop" },
      {
        "type": "logical", "mode": "or",
        "rules": [
          { "network": "udp", "port": [ 3478, 5349, 5350, 19302, 10000 ] },
          { "domain_regex": "^stun\\..+" },
          { "domain_keyword": [ "stun", "turn", "httpdns" ] }
        ],
        "action": "reject", "method": "drop"
      },
      { "action": "route-options", "udp_disable_domain_unmapping": true, "udp_connect": true },
      { "action": "resolve", "timeout": "5s" },
      { "clash_mode": "Global", "outbound": "🌍 Proxy" }
    ],

    "rule_set": [
      {
        "type": "remote",
        "tag": [ "ipdetect", "private", "adguard", "cheburnet", "trackers", "filter", "games", "ai", "proxy", "ru", "ruip" ],
        "url": "https://cdn.jsdelivr.net/gh/jinndi/singbox_ruleset@main/{tag}.srs",
        "update_interval": "48h0m0s"
      }
    ],

    "final": "🌍 Proxy",
    "auto_detect_interface": true,
    "find_process": true,
    "default_domain_resolver": "dns_direct",
    "default_http_client": "default"
  },

  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "cache.db",
      "store_fakeip": true,
      "store_dns": true
    },

    "debug": {
      "gc_percent": 100,
      "memory_limit": "400MB"
    }
  }
}
```

**Для Android смартфонов***

Шаблон для Windows/Linux легко адаптировать под Android смартфоны, достаточно удалить ненужные селекторы упростив его.

Отличия от Windows/Linux шаблона:

 - Удален один DNS под тегом `"dns_proxy_q9"` для оптимизации при слабом приеме сети.
 - Убраны селекторы: `"🏴‍☠️ Torrent"`, `"🕹️ Games"`, `"🤖 AI"`.
 - Добавлены небезопасные TCP/UDP порты в правила (rules) для их отклонения, подробнее см. в файле config-commented.jsonc.
 - Добавлена опция `route.auto_detect_interface`.

```jsonc
{
  "$schema": "https://sing-box.sagernet.org/schema.json",

  "log": { "level": "trace", "output": "", "timestamp": true },

  "dns": {
    "servers": [
      {
        "tag": "hosts", "type": "hosts",
        "predefined": {
          "cloudflare-dns.com": [ "104.16.248.249", "104.16.249.249" ],
          "dns.google": [ "8.8.8.8", "8.8.4.4" ],
          "common.dot.dns.yandex.net": [ "77.88.8.8", "77.88.8.1" ]
        }
      },
      { "tag": "dns_local",    "type": "local" },
      { "tag": "dns_direct",   "type": "https",  "server": "common.dot.dns.yandex.net", "domain_resolver": "hosts" },
      { "tag": "dns_proxy_cf", "type": "https",  "server": "cloudflare-dns.com", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_proxy_gg", "type": "https",  "server": "dns.google", "domain_resolver": "hosts", "detour": "🌍 Proxy" },
      { "tag": "dns_fakeip",   "type": "fakeip", "inet4_range": "198.18.0.0/15" }
    ],

    "rules": [
      { "preferred_by": "hosts", "server": "hosts" },
      { "query_type": "A", "invert": true, "action": "reject" },
      { "rule_set": "ipdetect", "action": "reject" },
      { "domain_keyword": [ "keenetic", "netcraze" ], "server": "dns_local" },
      { "rule_set": "private", "server": "dns_local" },
      { "clash_mode": "Direct", "server": "dns_direct" },
      { "rule_set": "adguard", "action": "predefined" },
      { "rule_set": "cheburnet", "server": "dns_direct" },
      { "rule_set": "trackers", "server": "dns_direct" },
      { "rule_set": "filter", "server": "dns_direct" },
      { "rule_set": [ "games", "ai", "proxy" ], "rewrite_ttl": 300, "server": "dns_fakeip" },
      { "action": "evaluate", "server": "dns_proxy_cf", "tag": "final-cf", "client_subnet": "77.88.8.0/24" },
      { "action": "evaluate", "server": "dns_proxy_gg", "tag": "final-gg", "client_subnet": "77.88.8.0/24" },
      { "match_response": "final-cf", "rule_set": "ruip", "action": "respond", "race": true },
      { "match_response": "final-gg", "rule_set": "ruip", "action": "respond", "race": true },
      { "server": "dns_fakeip" },
      { "clash_mode": "Global", "server": "dns_fakeip" }
    ],

    "final": "dns_proxy_cf",
    "strategy": "ipv4_only",
    "timeout": "10s",
    "cache_capacity": 16384,
    "optimistic": {
      "enabled": true,
      "timeout": "5m0s"
    },
    "reverse_mapping": true
  },

  "ntp": {
    "enabled": true,
    "interval": "30m0s",
    "server": "ntp.msk-ix.ru",
    "server_port": 123,
    "detour": "🇷🇺 RU"
  },

  "http_clients": [
    {
      "tag": "default",
      "version": 2,
      "detour": "GLOBAL",
      "stream_receive_window": 0,
      "connection_receive_window": 0
    }
  ],

  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "address": "172.18.0.1/30",
      "loopback_address": "10.7.0.1",
      "mtu": 1500,
      "dns_mode": "hijack",
      "dns_address": "172.18.0.2",
      "auto_route": true,
      "auto_redirect": true,
      "strict_route": true,
      "stack": "mixed",
      "udp_nat_max": 4096,
      "endpoint_independent_nat": true
    }
  ],

  "outbounds": [
    { "tag": "🌍 Proxy",   "type": "selector", "outbounds": [] },
    { "tag": "🇷🇺 RU",      "type": "selector", "outbounds": [] },
    { "tag": "🔌 DIRECT",  "type": "selector", "outbounds": [ "DIRECT" ] },

    { "tag": "DIRECT", "type": "direct" },
    { "tag": "GLOBAL", "type": "selector", "outbounds": [ "🌍 Proxy" ] },

    { "tag": "🌍 Auto", "type": "urltest", "outbounds": [], "interval": "30m", "tolerance": 100 },
    { "tag": "🇷🇺 Auto", "type": "urltest", "outbounds": [], "interval": "10m", "tolerance": 100 }
  ],

 "route": {
    "rules": [
      { "network": "icmp", "outbound": "🔌 DIRECT" },
      { "action": "sniff", "timeout": "500ms" },
      { "action": "hijack-dns", "type": "logical", "mode": "or", "rules": [ { "protocol": "dns" }, { "port": 53 } ] },
      { "ip_version": 6, "action": "reject" },
      { "port": [ 853, 5353 ], "action": "reject" },
      { "rule_set": "ipdetect", "action": "reject" },
      { "clash_mode": "Direct", "outbound": "🔌 DIRECT" },
      { "rule_set": "private", "outbound": "🔌 DIRECT" },
      { "protocol": "ntp", "outbound": "🇷🇺 RU" },
      { "rule_set": "cheburnet", "outbound": "🔌 DIRECT" },
      { "ip_is_private": true, "outbound": "🔌 DIRECT" },
      { "ip_cidr": "198.18.0.0/15", "outbound": "🌍 Proxy" },
      { "rule_set": [ "games", "ai", "proxy" ], "outbound": "🌍 Proxy" },
      { "rule_set": [ "ru", "ruip" ], "outbound": "🇷🇺 RU" },
      { "protocol": [ "stun", "dtls" ], "action": "reject", "method": "drop" },
      {
        "type": "logical", "mode": "or",
        "rules": [
          { "network": "udp", "port": [ 3478, 5349, 5350, 19302, 10000 ] },
          { "domain_regex": "^stun\\..+" },
          { "domain_keyword": [ "stun", "turn", "httpdns" ] }
        ],
        "action": "reject", "method": "drop"
      },
      {
        "network": "udp",
        "port": [
          20, 21, 22, 23, 25, 69, 80, 110, 123, 137, 138, 139, 143, 389, 445,
          500, 514, 666, 1194, 1433, 1701, 1719, 1720, 1723, 1900, 2049, 2710,
          3128, 3306, 3389, 3479, 4444, 4500, 4665, 4672, 5060, 5061, 5349, 5355,
          5432, 5900, 6443, 6711, 6776, 6881, 6882, 6883, 6884, 6885, 6886, 6887,
          6888, 6889, 7001, 7002, 8000, 8080, 8443, 8612, 8766, 8767, 9090, 9987,
          12345, 27015, 27016, 27017, 27018, 27019, 27020, 27021, 27022, 27023,
          27024, 27025, 27026, 27027, 27028, 27029, 27030
        ],
        "action": "reject"
      },
      {
        "network": "tcp",
        "port": [
          20, 21, 22, 23, 25, 80, 110, 143, 389, 445, 666, 1080, 1194, 1433, 1719,
          1720, 1723, 2049, 2710, 3128, 3306, 3389, 3478, 3479, 4444, 4661, 4662,
          5060, 5061, 5349, 5432, 5900, 6711, 6776, 7001, 7002, 8000, 8080, 8443,
          8612, 9090, 10000, 12345, 1243, 27374, 3127, 31337
        ],
        "action": "reject"
      },
      { "action": "route-options", "udp_disable_domain_unmapping": true, "udp_connect": true },
      { "action": "resolve", "timeout": "5s" },
      { "clash_mode": "Global", "outbound": "🌍 Proxy" }
    ],

    "rule_set": [
      {
        "type": "remote",
        "tag": [ "ipdetect", "private", "adguard", "cheburnet", "trackers", "filter", "games", "ai", "proxy", "ru", "ruip" ],
        "url": "https://cdn.jsdelivr.net/gh/jinndi/singbox_ruleset@main/{tag}.srs",
        "update_interval": "48h0m0s"
      }
    ],

    "final": "🌍 Proxy",
    "auto_detect_interface": true,
    "find_process": true,
    "override_android_vpn": true,
    "default_domain_resolver": "dns_direct",
    "default_http_client": "default"
  },

  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "cache.db",
      "store_fakeip": true,
      "store_dns": true
    },

    "debug": {
      "gc_percent": 100,
      "memory_limit": "400MB"
    }
  }
}
```

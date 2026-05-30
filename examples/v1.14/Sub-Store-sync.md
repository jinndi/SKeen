## Пример синхронизации конфигурации с помощью Sub-Store

**Спешиал фор Россия**

Чтобы обеспечить стабильную работу в условиях современной интернет-цензуры, пора уже забыть про наивную веру в один собственный сервер с XHTTP. Гораздо эффективнее использовать пул из десятков или сотен прокси-узлов, собранных из кучи разных подписок. Беспомощный формат «добавить одну ссылочку вида `vless://` через очередной веб-интерфейсик» в текущих реалиях - это путь в тупик при первом же чихе на ТСПУ, оставляющий вас вообще без связи. И если вас это безумие ещё почему-то не коснулось, то это лишь вопрос времени. Именно для гибкого управления огромным пулом прокси узлов и необходим `Sub-Store`.

Помимо конструирования конфигов и их локальной синхронизации с помощью программы `GUI.for.SingBox` и моего плагина [sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen), вы также можете настроить удалённую синхронизацию конфигурации sing-box из `Sub-Store` с помощью команды `skeen sync`.

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
  "log": { "disabled": false, "level": "debug", "output": "", "timestamp": false },

  "dns": {
    "servers": [
      {
        "tag": "hosts", "type": "hosts",
        "predefined": {
          "dns.google": [ "8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844" ],
          "common.dot.dns.yandex.net": [ "77.88.8.8", "77.88.8.1", "2a02:6b8::feed:0ff", "2a02:6b8:0:1::feed:0ff" ],
          "my.netcraze.pro": [ "192.168.1.1" ]
        }
      },
      { "tag": "dns_local", "type": "local" },
      { "tag": "dns_direct", "type": "https", "server": "common.dot.dns.yandex.net", "domain_resolver": "hosts" },
      { "tag": "dns_proxy", "type": "https", "server": "dns.google", "domain_resolver": "hosts", "detour": "GLOBAL" },
      { "tag": "dns_fakeip", "type": "fakeip", "inet4_range": "198.18.0.0/15", "inet6_range": "fc00::/18" }
    ],

    "rules": [
      { "preferred_by": [ "hosts" ], "server": "hosts" },
      { "query_type": [ "SVCB", "HTTPS", "PTR" ], "action": "reject" },
      { "rule_set": [ "ip_geo_detect"], "action": "reject" },
      { "rule_set": [ "private" ], "server": "dns_local" },
      { "clash_mode": "Direct", "server": "dns_direct" },
      { "rule_set": [ "adguard" ], "action": "predefined" },
      { "rule_set": [ "cheburnet" ], "server": "dns_direct" },
      { "rule_set": [ "trackerslist" ], "server": "dns_direct" },
      { "rule_set": [ "fakeip_filter" ], "server": "dns_direct" },
      { "rule_set": [ "games", "ai", "proxy"], "query_type": [ "A", "AAAA" ], "rewrite_ttl": 300, "server": "dns_fakeip" },
      { "rule_set": [ "ru" ], "server": "dns_direct" },
      { "action": "evaluate", "server": "dns_proxy", "client_subnet": "77.88.8.0/24" },
      { "match_response": true, "query_type": [ "A", "AAAA" ], "rule_set": [ "ru_ip_blocked" ], "server": "dns_fakeip" },
      { "match_response": true, "rule_set": [ "ru_ip" ], "action": "respond" },
      { "query_type": [ "A", "AAAA" ], "server": "dns_fakeip" },
      { "clash_mode": "Global", "server": "dns_proxy" }
    ],

    "final": "dns_proxy",
    "strategy": "ipv4_only",
    "timeout": "3s",
    "cache_capacity": 16384,
    "optimistic": { "enabled": true, "timeout": "1h0m0s" },
    "reverse_mapping": true
  },

  "http_clients": [
    { "tag": "global_client", "version": 2, "detour": "GLOBAL", "stream_receive_window": 0, "connection_receive_window": 0 },
    { "tag": "direct_client", "version": 2, "detour": "DIRECT", "stream_receive_window": 0, "connection_receive_window": 0 }
  ],

  "inbounds": [
    { "tag": "tproxy-in", "type": "tproxy", "listen": "::", "listen_port": 65082, "tcp_fast_open": true, "udp_fragment": true, "udp_timeout": "1m0s" }
  ],

  "outbounds": [
    { "tag": "🌍 Выбор узла", "type": "selector", "outbounds": [ ], "default": "🆚 vless узел 🌍", "interrupt_exist_connections": true },
    { "tag": "🇷🇺 Россия", "type": "selector", "outbounds": [ ], "default": "⚡️ Авто 🇷🇺", "interrupt_exist_connections": true },
    { "tag": "🏴‍☠️ Торрент", "type": "selector", "outbounds": [ ], "default": "⚡️ Авто 🌍", "interrupt_exist_connections": true },
    { "tag": "🕹️ Игры", "type": "selector", "outbounds": [ ], "default": "⚡️ Авто 🌍", "interrupt_exist_connections": true },
    { "tag": "🤖 AI", "type": "selector", "outbounds": [ ], "default": "⚡️ Авто 🌍", "interrupt_exist_connections": true },
    { "tag": "🔌 Провайдер", "type": "selector", "outbounds": [ "DIRECT" ] },

    { "tag": "DIRECT", "type": "direct", "domain_resolver": "dns_direct" },
    { "tag": "GLOBAL", "type": "selector", "outbounds": [ "🌍 Выбор узла" ], "interrupt_exist_connections": true },

    { "tag": "⚡️ Авто 🌍", "type": "urltest", "outbounds": [ ], "interval": "10m", "tolerance": 100, "interrupt_exist_connections": true },
    { "tag": "⚡️ Авто 🇷🇺", "type": "urltest", "outbounds": [ ], "interval": "10m", "tolerance": 100, "interrupt_exist_connections": true }
  ],

  "route": {
    "rules": [
      { "network": "icmp", "outbound": "🔌 Провайдер" },
      { "action": "sniff", "timeout": "500ms" },
      { "action": "hijack-dns", "type": "logical", "mode": "or", "rules": [ { "protocol": "dns" }, { "port": 53 } ] },
      { "port": [ 853, 5353 ], "action": "reject" },
      { "action": "reject", "type": "logical", "mode": "and", "rules": [ { "ip_version": 6 }, { "default_interface_address": "2000::/3", "invert": true } ] },
      { "protocol": [ "ntp" ], "outbound": "🇷🇺 Россия" },
      { "protocol": [ "stun" ], "action": "reject" },
      { "rule_set": [ "ip_geo_detect"], "action": "reject" },
      { "clash_mode": "Direct", "outbound": "🔌 Провайдер" },
      { "rule_set": [ "private" ], "outbound": "🔌 Провайдер" },
      { "rule_set": [ "cheburnet" ], "outbound": "🔌 Провайдер" },
      { "protocol": "bittorrent", "outbound": "🏴‍☠️ Торрент" },
      { "rule_set": [ "proxy" ], "outbound": "🌍 Выбор узла" },
      { "rule_set": [ "games" ], "outbound": "🕹️ Игры" },
      { "rule_set": [ "ai" ], "outbound": "🤖 AI" },
      { "rule_set": [ "ru" ], "outbound": "🇷🇺 Россия" },
      { "ip_is_private": true, "outbound": "🔌 Провайдер" },
      { "ip_cidr": [ "198.18.0.0/15",  "fc00::/18" ], "outbound": "🌍 Выбор узла" },
      { "rule_set": [ "ru_ip" ], "outbound": "🇷🇺 Россия" },
      { "action": "route-options", "udp_disable_domain_unmapping": true, "udp_connect": true },
      { "action": "resolve" },
      { "clash_mode": "Global", "outbound": "🌍 Выбор узла" }
    ],

    "rule_set": [
      { "tag": "adguard", "type": "remote", "url": "https://github.com/jinndi/adguard-filter-list-srs/releases/latest/download/adguard-filter-list.srs" },
      { "tag": "private", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/private.srs" },
      { "tag": "fakeip_filter", "type": "remote", "url": "https://github.com/jinndi/fakeip-filter-srs/releases/latest/download/fakeip-filter.srs" },
      { "tag": "trackerslist", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-public-tracker.srs" },
      { "tag": "games", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-games.srs" },
      { "tag": "ai", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ai-chat-!cn.srs" },
      { "tag": "proxy", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/russia/runetfreedom/sing-box/rule-set-geosite/geosite-ru-blocked.srs" },
      { "tag": "ip_geo_detect", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ip-geo-detect.srs" },
      { "tag": "cheburnet", "type": "remote", "url": "https://github.com/jinndi/geosite-cheburnet/releases/latest/download/geosite-cheburnet.srs" },
      { "tag": "ru", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ru.srs" },
      { "tag": "ru_ip", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/ru.srs" },
      { "tag": "ru_ip_blocked", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/russia/runetfreedom/sing-box/rule-set-geoip/geoip-ru-blocked.srs" }
    ],

    "final": "🌍 Выбор узла",
    "auto_detect_interface": true,
    "default_domain_resolver": "dns_direct",
    "default_http_client": "global_client"
  },

  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "cache.db",
      "cache_id": "",
      "store_fakeip": true,
      "store_dns": true
    },

    "clash_api": {
      "external_controller": "0.0.0.0:9999",
      "external_ui": "zashboard",
      "external_ui_download_url": "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip",
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
config.outbounds.find(p => p.tag === '🌍 Выбор узла')?.outbounds?.push('⚡️ Авто 🌍', ...allProxyTags)
config.outbounds.find(p => p.tag === '🇷🇺 Россия')?.outbounds?.push('⚡️ Авто 🇷🇺', '🔌 Провайдер', ...allProxyTagsRU)
config.outbounds.find(p => p.tag === '🏴‍☠️ Торрент')?.outbounds?.push('⚡️ Авто 🌍', '🔌 Провайдер', ...allProxyTags)
config.outbounds.find(p => p.tag === '🕹️ Игры')?.outbounds?.push('⚡️ Авто 🌍', '🔌 Провайдер', ...allProxyTags)
config.outbounds.find(p => p.tag === '🤖 AI')?.outbounds?.push('⚡️ Авто 🌍', '🔌 Провайдер', ...allProxyTags)
config.outbounds.find(p => p.tag === '⚡️ Авто 🌍')?.outbounds?.push(...allProxyTags)
config.outbounds.find(p => p.tag === '⚡️ Авто 🇷🇺')?.outbounds?.push(...allProxyTagsRU)

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

Поздравляем, вы стали продвинутым пользователем! Осталось [настроить мобильное устройство](https://github.com/jinndi/RKNHardering-defense/blob/main/SUB-STORE.md), если это вам необходимо.

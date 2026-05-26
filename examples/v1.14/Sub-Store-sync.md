## Пример синхронизации конфигурации с помощью Sub-Store

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
          "one.one.one.one": [ "1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001" ],
          "common.dot.dns.yandex.net": [ "77.88.8.8", "77.88.8.1", "2a02:6b8::feed:0ff", "2a02:6b8:0:1::feed:0ff" ],
          "my.netcraze.pro": [ "192.168.1.1" ]
        }
      },
      { "tag": "dns_local", "type": "local" },
      { "tag": "dns_resolver", "type": "udp", "server": "77.88.8.8" },
      { "tag": "dns_proxy", "type": "tls", "server": "one.one.one.one", "domain_resolver": "hosts", "detour": "GLOBAL"},
      { "tag": "dns_direct", "type": "https", "server": "common.dot.dns.yandex.net", "domain_resolver": "hosts" },
      { "tag": "dns_fakeip", "type": "fakeip", "inet4_range": "198.18.0.0/15", "inet6_range": "fc00::/18" }
    ],

    "rules": [
      { "preferred_by": [ "hosts" ], "server": "hosts" },
      { "clash_mode": "Direct", "server": "dns_direct" },
      { "clash_mode": "Global", "server": "dns_proxy" },
      { "rule_set": [ "private" ], "server": "dns_local" },
      { "rule_set": [ "adguard" ], "action": "predefined" },
      { "rule_set": [ "fakeip_filter", "trackerslist" ], "server": "dns_direct" },
      { "rule_set": [ "games", "ai", "proxy"], "query_type": [ "A", "AAAA" ], "server": "dns_fakeip" },
      { "rule_set": [ "ru" ], "server": "dns_direct" },
      { "action": "evaluate", "server": "dns_proxy", "client_subnet": "77.88.8.0/24" },
      { "match_response": true, "rule_set": [ "ru_ip" ], "action": "respond" },
      { "query_type": [ "A", "AAAA" ], "server": "dns_fakeip" }
    ],

    "final": "dns_proxy",
    "strategy": "prefer_ipv4",
    "optimistic": true,
    "reverse_mapping": true
  },

  "inbounds": [
    { "tag": "tproxy-in", "type": "tproxy", "listen": "::", "listen_port": 65082, "tcp_fast_open": true, "udp_fragment": true, "udp_timeout": "1m0s" }
  ],

  "outbounds": [
    { "tag": "🌍 Выбор узла", "type": "selector", "outbounds": [], "interrupt_exist_connections": true },
    { "tag": "🏴‍☠️ Торрент", "type": "selector", "outbounds": [], "interrupt_exist_connections": true },
    { "tag": "🕹️ Игры", "type": "selector", "outbounds": [], "interrupt_exist_connections": true },
    { "tag": "🤖 AI", "type": "selector", "outbounds": [], "interrupt_exist_connections": true },
    { "tag": "🔌 Провайдер", "type": "selector", "outbounds": [ "DIRECT" ] },

    { "tag": "DIRECT", "type": "direct" },
    { "tag": "GLOBAL", "type": "selector", "outbounds": [ "🌍 Выбор узла", "🔌 Провайдер" ], "default": "🌍 Выбор узла", "interrupt_exist_connections": true },

    { "tag": "⚡️ Авто", "type": "urltest", "outbounds": [], "interval": "10m", "tolerance": 100, "interrupt_exist_connections": true }
  ],

  "http_clients": [ { "tag": "detour_global", "detour": "GLOBAL" } ],

  "route": {
    "final": "🌍 Выбор узла",
    "auto_detect_interface": true,
    "default_domain_resolver": "dns_resolver",
    "default_http_client": "detour_global",

    "rules": [
      { "clash_mode": "Direct", "outbound": "🔌 Провайдер" },
      { "clash_mode": "Global", "outbound": "🌍 Выбор узла" },
      { "action": "sniff" },
      { "action": "hijack-dns", "type": "logical", "mode": "or", "rules": [ { "protocol": "dns" }, { "port": 53 } ] },
      { "rule_set": [ "private" ], "outbound": "🔌 Провайдер" },
      { "protocol": "bittorrent", "outbound": "🏴‍☠️ Торрент" },
      { "rule_set": [ "games" ], "outbound": "🕹️ Игры" },
      { "rule_set": [ "ai" ], "outbound": "🤖 AI" },
      { "rule_set": [ "proxy" ], "outbound": "🌍 Выбор узла" },
      { "rule_set": [ "ru" ], "outbound": "🔌 Провайдер" },
      { "ip_is_private": true, "outbound": "🔌 Провайдер" },
      { "rule_set": [ "ru_ip" ], "outbound": "🔌 Провайдер" }
    ],

    "rule_set": [
      { "tag": "adguard", "type": "remote", "url": "https://github.com/jinndi/adguard-filter-list-srs/releases/latest/download/adguard-filter-list.srs" },
      { "tag": "private", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/private.srs" },
      { "tag": "fakeip_filter", "type": "remote", "url": "https://github.com/jinndi/fakeip-filter-srs/releases/latest/download/fakeip-filter.srs" },
      { "tag": "trackerslist", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-public-tracker.srs" },
      { "tag": "games", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-games.srs" },
      { "tag": "ai", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ai-chat-!cn.srs" },
      { "tag": "proxy", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/russia/runetfreedom/sing-box/rule-set-geosite/geosite-ru-blocked.srs" },
      { "tag": "ru", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ru.srs" },
      { "tag": "ru_ip", "type": "remote", "url": "https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/ru.srs" }
    ]
  },

  "experimental": {
    "cache_file": { "enabled": true, "path": "cache.db", "store_fakeip": true, "store_dns": true },

    "clash_api": {
      "external_controller": "0.0.0.0:9999",
      "external_ui": "zashboard",
      "external_ui_download_url": "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip",
      "external_ui_download_detour": "GLOBAL",
      "default_mode": "Rule"
    }
  }
}
```

  - **`Файлы` `Скрипт-модификатор (JS)`**: Там же, но чуть ниже будет карточка с заголовком **Добавить действие**. В ней выбираем **Скрипт-модификатор (JS)**. Появится новое окно ввода выше - переключаемся в нём на вкладку **Локальный скрипт** и вставляем следующий шаблон:


```javascript
//// Указываем имя вашей подписки/коллекции
const subName = "mysub"

////////////////////////////////////////////////////////////

// 1. Загружаем прокси из подписки/коллекции
// (по аналогии можно повторить блок если необходимо использовать дополнительные ссылки)
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

// 2. Парсим шаблон (вставленный ранее как основа конфига)
let config
try {
  config = JSON.parse($files[0])
} catch (e) {
  throw new Error("Ошибка парсинга шаблона: " + e.message)
}

// 3. Извлекаем только имена (теги) всех прокси, чтобы добавить их в группы
let allProxyTags = singboxProxies.map(p => p.tag)

// 4. Находим и заполняем outbounds группы селекторов/urltest нашего шаблона
// (тут нужно отредактировать, если вы меняли предложенный шаблон на свои группы селекторов/urltest)
config.outbounds.find(p => p.tag === '🌍 Выбор узла')?.outbounds?.push('🔌 Провайдер', '⚡️ Авто', ...allProxyTags)
config.outbounds.find(p => p.tag === '🏴‍☠️ Торрент')?.outbounds?.push('⚡️ Авто', '🔌 Провайдер', ...allProxyTags)
config.outbounds.find(p => p.tag === '🕹️ Игры')?.outbounds?.push('⚡️ Авто', '🔌 Провайдер', ...allProxyTags)
config.outbounds.find(p => p.tag === '🤖 AI')?.outbounds?.push('⚡️ Авто', '🔌 Провайдер', ...allProxyTags)
config.outbounds.find(p => p.tag === '⚡️ Авто')?.outbounds?.push(...allProxyTags)

// 5. Добавляем в самый конец сами узлы прокси-серверов из подписки/коллекции
config.outbounds.push(...singboxProxies)

// 6. Результат отдаем дальше
$content = JSON.stringify(config, null, 2)
```

В этом шаблоне требуется только укзатаь имя ранее созданной подписки/коллекции в начале:

```javascript
const subName = "mysub"
```

И проверьте в пункте 1 (Загружаем прокси из подписки/коллекции) - там должно быть `type: "collection"`, или укажите `"subscription"`, если у вас тип «подписка».

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

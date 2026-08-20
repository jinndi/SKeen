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

  > [!TIP]
  > Вы можете использовать любой собственный вариант - отредактированный или дополненный. Единственное, что необходимо, - это наличие структуры блока `outbounds`, схожей с примером. Если вы любите конструировать, создайте шаблон через `GUI.for.SingBox` (только для стабыльных версий sing-box) и скопируйте его с помощью плагина [sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen).

  > [!TIP]
  > Если вам нужен шаблон для Windows, Linux или Android официальных клиентов sing-box, возьмите шаблоны из файлов `template-desktop.json` или `template-android.json` соответственно.

```jsonc
{
  "$schema": "https://sing-box.sagernet.org/schema.json",

  "log": { "level": "debug", "output": "", "timestamp": false },

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
      { "rule_set": "proxy", "rewrite_ttl": 300, "server": "dns_fakeip" },
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
      "detour": "🌍 Proxy"
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
    { "tag": "🌍 Auto",    "type": "urltest",  "outbounds": [], "interval": "10m", "tolerance": 100 },
    { "tag": "🇷🇺 Auto",    "type": "urltest",  "outbounds": [], "interval": "5m",  "tolerance": 100 },
    { "tag": "🔌 DIRECT",  "type": "direct",   "domain_resolver": "dns_direct" },
    { "tag": "❌ REJECT",  "type": "block" },
    { "tag": "🚦 FINAL",   "type": "selector", "outbounds": [ "🌍 Proxy", "🔌 DIRECT", "❌ REJECT" ] }
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
    "final": "🚦 FINAL",
    "auto_detect_interface": true,
    "default_domain_resolver": "dns_direct",
    "default_http_client": "default"
  },

  "services": [
    {
      "type": "api",
      "tag": "api",
      "listen": "::",
      "listen_port": 9999,
      "access_control_allow_private_network": true,
      "dashboard": {
        "enabled": true,
        "path": "zashboard",
        "download_url": "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip"
      }
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
    "debug": {
      "gc_percent": 100,
      "memory_limit": "200MB"
    }
  }
}
```

  - **`Файлы` `Скрипт-модификатор (JS)`**: Там же, но во вкладке "Действия" ниже выбираем **Скрипт-модификатор (JS)**. Появится окно ввода - переключаемся в нём на вкладку **Локальный скрипт** и вставляем следующий шаблон:

**Вариант 1: По раздельным подпискам/коллекциям с нужной фильтрацией заданных в них**

```javascript
//// Указываем имена ваших подписок/коллекций
// ВАЖНО: Теги прокси-узлов из подписок не должны дублироваться!
const subName = "mysub"      // для зарубежных прокси
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
// в формате массива outbounds (по примеру как в файле примера outbounds.jsonc папка server-client)
// const mainOutbounds = (ProxyUtils.JSON5 || JSON).parse(await produceArtifact({
//  type: 'file',
//  name: 'myfile' // Ваше имя файла (ID) c массивом прокси-узлов
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

**Вариант 2: Из одной подписки/коллекции и/или файла с фильтрацией в самом скрипте**

```javascript
//// Указываем имя подписки/коллекции/файла с массивом узлов
const subNameId = "main"     // Имя(ID) одписки/коллекции (если пусто, то не добавится)
const fileNameId = "myfile"  // Имя(ID) файла (если пусто, то не добавится)
////////////////////////////////////////////////////////////

//// Определяем переменные для хранения прокси узлов
const proxies = []

//// Переменная для шаблона конфига sing-box
let config = {}

// 1. Загружаем прокси узлы из подписки/коллекции, если имя указано
if (subNameId) {
  try {
    proxies.push(...await produceArtifact({
      type: "collection", // укажите "subscription" если у вас подписка
      name: subNameId,
      platform: "sing-box",
      produceType: "internal"
    }))
  } catch (e) {
    throw new Error(`Не удалось загрузить подписку '${subNameId}'. Проверьте имя и формат подписки.`)
  }
}

// 1.1. Загружаем прокси узлы из файла если имя файла указано
if (fileNameId) {
  try {
    proxies.unshift(...(ProxyUtils.JSON5 || JSON).parse(await produceArtifact({
      type: 'file',
      name: fileNameId
    })))
  } catch (e) {
    throw new Error(`Не удалось загрузить файл '${fileNameId}'. Проверьте имя и формат файла.`)
  }
}

// 2. Парсим шаблон sing-box (вставленный ранее как основа конфига)
try {
  config = JSON.parse($files[0])
} catch (e) {
  throw new Error("Ошибка парсинга шаблона конфига sing-box: " + e.message)
}

// Вспомогательная функция для фильтрации тегов узлов
// Принимает в себя 3 параметра:
//  tagsList - массив тегов для фильтрации
//  regex - регулятное выражение в виде строки либо самого выражения
//  invert - boolean значение, если false (по умолчанию) то оставлять указанные в regex узлы, если true - удалять
const getTags = (tagsList, regex, invert=false) => {
  if (!Array.isArray(tagsList)) return []
  if (tagsList.length === 0) return []
  if (!regex) return tagsList
  if (typeof regex === 'string') regex = new RegExp(regex, 'i')
  if (typeof invert !== 'boolean') invert = false

  return tagsList.filter(t => {
    const testResult = regex.test(t)
    return invert ? !testResult : testResult
  })
}

// 3. Извлекаем и фильтруем только имена (теги) прокси
// - реальные теги прокси-узлов
const proxiesTags = proxies.map(p => p.tag)
// - все теги включая URLTest группы и 🔌 DIRECT
const allTags = ['🌍 Auto', '🇷🇺 Auto', '🔌 DIRECT', ...proxiesTags]

// 3.1. Заполняем группы (регулярные выражения для примера)
// Допустим эмодзи 😎 - унас содержится в названиях (тегах) в нашем файле с массивом узлов
// - формат смотрите в client-outbounds.jsonc
const proxyGroups = {
  // Selectors
  '🌍 Proxy':   getTags(allTags, '✅|😎', true),  // из всех тегов удаляем содержащие ✅ или 😎
  '🇷🇺 RU':      getTags(allTags, '🇷🇺|🔌'),        // из всех тегов оставляем содержащие 🇷🇺 или 🔌
  '🏴‍☠️ Torrent': getTags(allTags, '🔌|✅|😎'),     // из всех тегов оставляем содержащие 🔌, ✅ или 😎
  '🕹️ Games':   getTags(allTags, '😎|Hys'),       // из всех тегов оставляем содержащие 😎 или подстроку Hys
  '🤖 AI':      getTags(allTags, '🇳🇴|😎'),        // из всех тегов оставляем содержащие 🇳🇴 или 😎
  // URL-Test группы (принимают ТОЛЬКО реальные прокси-узлы из proxiesTags)
  '🌍 Auto': getTags(proxiesTags, '😎', true),    // из тегов реальных прокси узлов удаляем содержащие 😎
  '🇷🇺 Auto': getTags(proxiesTags, '🇷🇺')           // из тегов реальных прокси узлов оставляем только с 🇷🇺
}

// 4. Находим и заполняем outbounds групп селекторов/urltest
for (const [tag, outbounds] of Object.entries(proxyGroups)) {
  const group = config.outbounds.find(p => p.tag === tag)
  if (group && Array.isArray(group.outbounds)) {
    if (outbounds.length === 0) {
      group.outbounds.push('🔌 DIRECT')
      continue
    }
    // Исключаем дубликаты при добавлении
    const uniqueOutbounds = [...new Set(outbounds)]
    group.outbounds.push(...uniqueOutbounds)
  }
}

// 5. Добавляем сами узлы прокси-серверов
config.outbounds.push(...proxies)

// 6. Результат отдаем дальше
$content = JSON.stringify(config, null, 2)
```

В этом типе шаблона требуется указатаь имя ранее созданной подписки/коллекции/файла в начале:

```javascript
const subNameId = "main"     // Имя(ID) одписки/коллекции (если пусто, то не добавится)
const fileNameId = "myfile"  // Имя(ID) файла (если пусто, то не добавится)
```

В пунке и подпунке №3 настроить фильтрацию по данным вашей подписки/коллекции/файла с прокси-узлами.


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

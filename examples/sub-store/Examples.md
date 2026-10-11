# Разные примеры скриптов для Sub-Store

Ознакомится с демонстрации использования скриптов можно в файле [Demo.md](./Demo.md), тут будут наиболее полезные примеры использовани.

**Важное замечание:** Во вкладке "Действия" может находиться несколько скриптов одного и того же типа. Они выполняются последовательно сверху вниз (порядок выполнения можно менять). Старайтесь сначала фильтровать узлы, а затем модифицировать их.

> Лучше всего организовать работу созданием коллекции, куда вы будете включать нужные подписки, а уже в самой коллекции выполнять действия над ними. На неё потом можно ссылаться для дальнейшей обработки в разделе "Файлы".

> Чтобы видеть логи бэкенда в том числе по работе ваших скриптов желательно включить их в разделе "Профиль" -> "Конфигурация кеша" и в поле "Макс. количество логов" ввести например 1000.

### Фильтрация прокси узлов (Cкрипт-фильтр JS)

В Sub-Store доступны простые и очевидные действия фильтраций такие как:

- Фильтр по ригионам
- Фильтр по типам протоколов
- Regex-фильтр по именам тегов

Помимо этих есть и продвинутый тип - *Cкрипт-фильтр JS*

**Наболее полезные примеры использования Cкрипт-фильтр JS:**

1. Убрать небезопасные прокси (`insecure`)

Очень часто прокси-провайдеры предоставляют прокси узлы с `"insecure": true`, что является небезопасным, поэтому во вкладке "Действия" вашей подписки/коллекции мы добавляем локальный Cкрипт-фильтр JS со следующим содержимым типа shortcut:

```javascript
return $server['skip-cert-verify'] !== true
```

Помимо этого, мы можем не убирать их из фильтрации, а принудительно отключить пропуск проверки TLS (`"insecure": false`) через «Общие настройки узлов».

### Модификация узлов (Скрипт-модификатор JS)

В Sub-Store уже из коробки доступны простые и очевидные действия модификаций такие как:

- Операции с флагами (эмодзи)
- DNS-резолв доменов
- Regex-удаление по тегам
- Regex-переименование тегов
- Обработка дубликатов (тегов)

Помимо этих есть и продвинутый тип - *Скрипт-модификатор JS*

**Наболее полезные примеры использования Скрипт-модификатор JS:**

1. Проверка доступности узлов по TCP и ICMP. Узлы помечаются как недоступные, только если обе проверки не проходят. UDP-протоколы исключены из проверки. По оценке, в 90% случаев позволяет выявить узлы, которые не будут работать или будут работать нестабильно.

> Чтобы вместо исключения недоступных узлов из результата помечать их, раскомментируйте строку маркировки и закомментируйте строку исключения.

**Важно**: запускайте скрипт только в Sub-Store, установленном на VPS.

```javascript
const net = require("net")
const dns = require("dns").promises
const { execFile } = require("child_process")
const { promisify } = require("util")

const execFileAsync = promisify(execFile)

const TCP_TIMEOUT = 800
const PING_TIMEOUT = 100
const MAX_CONCURRENT = 50

function checkTcp(server, port, timeout = TCP_TIMEOUT) {
  return new Promise((resolve) => {
    const socket = net.createConnection({
      host: server,
      port: Number(port),
    })

    let finished = false

    const done = (available) => {
      if (finished) return
      finished = true
      socket.destroy()
      resolve(available)
    }

    socket.setTimeout(timeout)
    socket.once("connect", () => done(true))
    socket.once("timeout", () => done(false))
    socket.once("error", () => done(false))
  })
}

async function checkPing(server, timeoutMs = PING_TIMEOUT) {
  try {
    const { address, family } = await dns.lookup(server)

    const args = family === 6
      ? ["-6", "-c", "1", "-W", "2", address]
      : ["-4", "-c", "1", "-W", "2", address]

    await execFileAsync("ping", args, {
      timeout: timeoutMs,
      windowsHide: true,
    })

    return true
  } catch (err) {
    return false
  }
}

async function operator(proxies, targetPlatform, context) {
  if (targetPlatform !== "sing-box") {
    console.warn("[TCP+Ping] Проверка доступна только для sing-box.")
    return proxies
  }

  console.log(`[TCP+Ping] Проверка ${proxies.length} узлов...`)

  const output = new Array(proxies.length)
  let nextIndex = 0
  let available = 0
  let unavailable = 0
  let skipped = 0

  async function worker() {
    while (true) {
      const index = nextIndex++

      if (index >= proxies.length) return

      const proxy = proxies[index]
      const server = proxy.server
      const port = Number(proxy.port)
      const type = String(proxy.type || "").toLowerCase()

      // QUIC/UDP-протоколы пропускаем.
      if (["hysteria2", "tuic", "hysteria"].includes(type)) {
        output[index] = proxy
        skipped++
        continue
      }

      if (
        !server ||
        !Number.isInteger(port) ||
        port < 1 ||
        port > 65535
      ) {
        output[index] = proxy
        skipped++
        continue
      }

      const [tcpAvailable, pingAvailable] = await Promise.all([
        checkTcp(server, port),
        checkPing(server),
      ])

      if (tcpAvailable || pingAvailable) {
        // Хотя бы одна проверка прошла — тег не меняем.
        output[index] = proxy
        available++
      } else {
        // Обе проверки не прошли:

        // 1-й вариант — исключаем узел из результата:
        output[index] = null

        // 2-й вариант — добавляем пометку 🚫 без дублирования:
        // proxy.name = `🚫 ${String(proxy.name).replace(/^🚫\s*/, "")}`
        // output[index] = proxy

        unavailable++

        console.warn(
          `[TCP+Ping] Обе проверки не пройдены: ` +
          `${proxy.name} (${server}:${port})`
        )
      }
    }
  }

  const workerCount = Math.min(MAX_CONCURRENT, proxies.length)

  await Promise.all(
    Array.from({ length: workerCount }, () => worker())
  )

  const result = output.filter(Boolean)

  console.log(
    `[TCP+Ping] Готово. ` +
    `Хотя бы одна проверка пройдена: ${available}, ` +
    `обе не пройдены: ${unavailable}, ` +
    `пропущено: ${skipped}. ` +
    `Осталось: ${result.length}/${proxies.length}.`
  )

  return result
}
```

2. Автоматически сделать привязку открытого ключа `certificate_public_key_sha256` из раздела "Подписки" для TCP протоколов.

В [настройке сервера](./Server-sing-box.md) уже описано что и для чего это нужно, но мы не будем делать это вручную, а предоставим работу скрипту.

**Обратите внимание:** скрипт не требуется, если ваша подписка полностью состоит из прокси-узлов с транспортом `REALITY` или протоколом `naive`. QUIC-протоколы (`Hysteria2`, `TUIC`, `Hysteria`) также пропускаются при обработке.

> **NOTICE:** Для наилучшей совместимости и эффективности рекомендуется использовать это с бэкендом **Sub-Store версии 2.42.3 или выше**. В этой версии добавлена автоматическая конвертация в опцию `certificate_sha256`, поддерживаемую `sing-box` начиная с версии **1.15.0-alpha.7**.
>
> Это позволяет избежать проблем совместимости, например: *«Почему на телефоне в приложении серверы работают, а на роутере - нет?»*

```javascript
const tls = require("tls")
const crypto = require("crypto")

function getCertificateInfo(server, port = 443, sni = server, timeoutMs = 1000) {
  return new Promise((resolve) => {
    let isResolved = false

    const finish = (result) => {
      if (!isResolved) {
        isResolved = true
        resolve(result)
      }
    }

    const socket = tls.connect(
      {
        host: server,              // Реальный адрес TCP-сервера
        port,                      // Реальный TCP-порт
        servername: sni,           // SNI, передаваемый TLS-серверу
        rejectUnauthorized: false,
      },
      () => {
        try {
          const cert = socket.getPeerCertificate(true)

          if (!cert || !cert.raw) {
            console.warn(`[Сертификаты] ERROR: ${server}:${port} SNI=${sni} — сертификат не получен`)
            socket.destroy()
            return finish({ publicKeySha256: "" })
          }

          const x509 = new crypto.X509Certificate(cert.raw)

          const publicKeyDer = x509.publicKey.export({
            type: "spki",
            format: "der",
          })

          const publicKeySha256 = crypto
            .createHash("sha256")
            .update(publicKeyDer)
            .digest("base64")

          console.log(`[Сертификаты] OK: ${server}:${port} SNI=${sni} -> ${publicKeySha256}`)

          socket.destroy()
          finish({ publicKeySha256 })
        } catch(err) {
          console.warn(`[Сертификаты] ERROR: ${server}:${port} SNI=${sni} — ${err.message}`)
          socket.destroy()
          finish({ publicKeySha256: "" })
        }
      }
    )

    socket.setTimeout(timeoutMs)

    socket.on("timeout", () => {
      console.warn(`[Сертификаты] TIMEOUT: ${server}:${port} SNI=${sni}`)
      socket.destroy()
      finish({ publicKeySha256: "" })
    })

    socket.on("error", (err) => {
      console.warn(`[Сертификаты] ERROR: ${server}:${port} SNI=${sni} — ${err.code || ""} ${err.message}`)
      socket.destroy()
      finish({ publicKeySha256: "" })
    })
  })
}

async function operator(proxies, targetPlatform, context) {
  if (targetPlatform !== 'sing-box'){
    console.warn(`[Сертификаты] WARN: Обработка доступна только для платформы sing-box и в разделе "Подписки"...`)
    return proxies
  }

  console.log(`[Сертификаты] INFO: Начинается обработка ${proxies.length} узлов...`)

  let successCount = 0
  let failCount = 0
  let skipCount = 0

  const certCache = {}

  const promises = proxies.map(async (proxy) => {
    // Адрес, к которому устанавливаем TCP-соединение
    const server = proxy.server

    // TCP-порт
    const port = proxy.port || 443

    // SNI: если явно указан — используем его,
    // иначе используем server
    const sni = proxy.sni || server

    // 1. Выключен ли TLS вообще
    const tlsDisabled = proxy.tls === false
    // 2. Является ли узел REALITY?
    const isRealityNaive = proxy["reality-opts"] || proxy.type === "naive"
    // 3. Если протокол на QUIC
    const isQuic = ["hysteria2", "tuic", "hysteria"].includes(proxy.type)

    // 4. Есть ли уже какие-то другие настройки сертификатов?
    const hasCert = proxy.certificate || proxy._certificate
    const hasCertPath = proxy._certificate_path
    const hasPubKey = proxy._certificate_public_key_sha256
    const hasCertSha256 = proxy['tls-fingerprint'] || proxy._certificate_sha256

    // ПРОПУСКАЕМ узел, если:
    if (
      !server ||                 // Нет адреса сервера
      ProxyUtils.isIP(sni) ||    // SNI является IP
      tlsDisabled ||             // TLS выключен
      isRealityNaive ||          // REALITY / Naive
      isQuic ||                  // QUIC/UDP-протокол
      hasCert ||                 // Уже прописан сертификат
      hasCertPath ||             // Уже прописан путь к сертификату
      hasPubKey ||               // Ключ уже прописан
      hasCertSha256              // Уже прописан certificate_sha256
    ) {
      skipCount++
      return proxy
    }

    // Учитываем server, port и SNI:
    // один сервер может обслуживать несколько сертификатов
    // в зависимости от SNI.
    const cacheKey = `${server}:${port}:${sni}`

    // Если запрос для этого хоста еще не делался, запускаем и сохраняем Promise
    if (!certCache[cacheKey]) {
      certCache[cacheKey] = getCertificateInfo(server, port, sni, 2000)
    }

    // Дожидаемся результата из кэша
    const cert = await certCache[cacheKey]

    if (cert.publicKeySha256) {
      proxy._certificate_public_key_sha256 = [cert.publicKeySha256]
      successCount++
    } else {
      failCount++
    }

    return proxy
  })

  // Ждем выполнения всех промисов
  await Promise.all(promises)

  const processedCount = successCount + failCount

  // Выводим итоговую статистику
  console.log(
    `[Сертификаты] INFO: Обработка завершена. ` +
    `Успешно: ${successCount}, ` +
    `Ошибки: ${failCount}, ` +
    `Пропущено: ${skipCount}. ` +
    `Обработано: ${processedCount}.`
  )

  return proxies
}
```

2. Задать VLESS-REALITY узлам отпечаток `randomized` а прочим VLESS узлам `firefox`, например чтобы иметь возможность подключаться к серверу с Xray 26.9.8+ версии (подробнее https://github.com/jinndi/sing-box)

```javascript
if  ( $server.type === 'vless' && $server['reality-opts'] ) {
  $server['client-fingerprint'] = 'randomized'
} else if ( $server.type === 'vless' ) {
  $server['client-fingerprint'] = 'firefox'
}
```

Продолжение следует...

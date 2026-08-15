# Разные примеры скриптов для Sub-Store

Ознакомится с демонстрации использования скриптов можно в файле [Sub-Store-demo.md](./Sub-Store-demo.md), тут будут наиболее полезные примеры использовани.

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

1. Убрать небезопасные прокси (`insecure`) и прокси содержащие транспорт `grpc`

Очень часто прокси-провайдеры предоставляют прокси узлы с `"insecure": true`, что является небезопасным, а транспорт `grpc` не входит в состав сборки в оффициальных релизах sing-box, поэтому во вкладке "Действия" вашей подписки/коллекции мы добавляем локальный Cкрипт-фильтр JS со следующим содержимым типа shortcut:

```javascript
return $server['skip-cert-verify'] !== true && $server.network !== 'grpc'
```

### Модификация узлов (Скрипт-модификатор JS)

В Sub-Store уже из коробки доступны простые и очевидные действия модификаций такие как:

- Операции с флагами (эмодзи)
- DNS-резолв доменов
- Regex-удаление по тегам
- Regex-переименование тегов
- Обработка дубликатов (тегов)

Помимо этих есть и продвинутый тип - *Скрипт-модификатор JS*

**Наболее полезные примеры использования Скрипт-модификатор JS:**

1. Автоматически сделать привязку открытого ключа `certificate_public_key_sha256` из раздела "Подписки"

В [настройке сервера](./Server-sing-box.md) уже описано что и для чего это нужно, но мы не будем делать это вручную, а предоставим работу скрипту.

**Обратите внимание:** в этом нет необходимости, если ваша подписка полностью состоит из прокси узлов с транспортом `REALITY`

```javascript
const tls = require("tls")
const crypto = require("crypto")

function getCertificateInfo(host, port = 443, timeoutMs = 1000) {
  return new Promise((resolve) => {
    let isResolved = false

    const finish = (result) => {
      if (!isResolved) {
        isResolved = true
        resolve(result)
      }
    }

    const socket = tls.connect(
      { host, port, servername: host, rejectUnauthorized: false },
      () => {
        try {
          const cert = socket.getPeerCertificate(true)

          if (!cert || !cert.raw) {
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

          socket.destroy()
          finish({ publicKeySha256 })
        } catch {
          socket.destroy()
          finish({ publicKeySha256: "" })
        }
      }
    )

    socket.setTimeout(timeoutMs)

    socket.on("timeout", () => {
      socket.destroy()
      finish({ publicKeySha256: "" })
    });
    socket.on("error", () => {
      socket.destroy();
      finish({ publicKeySha256: "" })
    })
  })
}

async function operator(proxies, targetPlatform, context) {
  if (targetPlatform !== 'sing-box'){
    console.log(`[Сертификаты] WARN: Обработка доступна только для платформы sing-box и в разделе "Подписки"...`)
    return proxies
  }

  console.log(`[Сертификаты] INFO: Начинается обработка ${proxies.length} узлов...`)

  let successCount = 0
  let failCount = 0
  let skipCount = 0

  const certCache = {}

  const promises = proxies.map(async (proxy) => {
    const host = proxy.sni || proxy.server
    const port = proxy.port || 443

    // 1. Выключен ли TLS вообще
    const tlsDisabled = proxy.tls === false
    // 2. Является ли узел REALITY?
    const isRealityNaive = proxy['reality-opts'] || proxy.type === 'naive'
    // 3. Есть ли уже какие-то другие настройки сертификатов?
    const hasCert = proxy.certificate || proxy._certificate
    const hasCertPath = proxy._certificate_path
    const hasPubKey = proxy._certificate_public_key_sha256

    // ПРОПУСКАЕМ узел, если:
    if (
      !host ||                  // Нет хоста
      ProxyUtils.isIP(host) ||  // Хоcт является IP адресом
      tlsDisabled ||            // TLS выключен
      isRealityNaive ||         // Это REALITY или Naive (отпечаток не нужен)
      hasCert ||                // Уже прописан сам сертификат
      hasCertPath ||            // Уже прописан путь к файлу сертификата
      hasPubKey                 // Ключ уже прописан ранее
    ) {
      skipCount++
      return proxy
    }

    // Уникальный ключ кэша: домен + порт
    const cacheKey = `${host}:${port}`

    // Если запрос для этого хоста еще не делался, запускаем и сохраняем Promise
    if (!certCache[cacheKey]) {
      certCache[cacheKey] = getCertificateInfo(host, port)
    }

    // Дожидаемся результата из кэша (если запрос уже был, берется готовый ответ)
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
  console.log(`[Сертификаты] INFO: Обработка завершена. Успешно: ${successCount} из ${processedCount} (пропущено: ${skipCount}).`)

  return proxies
}
```

Продолжение следует...

# Устранение неполадок

<details>
  <summary>Не устанавливается? (кликнуть)</summary>
<br>

Если основной способ загрузки недоступен, воспользуйтесь одним из вариантов ниже:

**`Авто-подбор зеркала (рекомендуется):`**

```sh
( c="curl -sfL --connect-timeout 3"; s="skeen_ru";  \
m="https://cdn.jsdelivr.net/gh/jinndi/SKeen@static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://cdn.statically.io/gh/jinndi/SKeen@static/"; $c "${m}${s}" | MIRROR="$m" sh  || \
m="https://raw.githack.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://ghfast.top/https://raw.githubusercontent.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://ghproxy.net/https://raw.githubusercontent.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://gh-proxy.com/https://raw.githubusercontent.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
echo "Ошибка: Не удалось загрузить скрипт. Ни один из серверов не доступен." )
```

Либо выберите конкретное зеркало вручную:

**`CDN jsDelivr`**

```sh
m="https://cdn.jsdelivr.net/gh/jinndi/SKeen@static/"; curl -sfL --connect-timeout 3 "${m}skeen_ru" | MIRROR="$m" sh
```

**`CDN Statically`**

```sh
m="https://cdn.statically.io/gh/jinndi/SKeen@static/"; curl -sfL --connect-timeout 3 "${m}skeen_ru" | MIRROR="$m" sh
```

**`CDN Githack`**

```sh
m="https://raw.githack.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen_ru" | MIRROR="$m" sh
```

**`Proxy GHFast`**

```sh
m="https://ghfast.top/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen_ru" | MIRROR="$m" sh
```

**`Proxy GHProxy`**

```sh
m="https://ghproxy.net/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen_ru" | MIRROR="$m" sh
```

**`Proxy GH-Proxy (alt)`**

```sh
m="https://gh-proxy.com/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen_ru" | MIRROR="$m" sh
```

</details>
# Troubleshooting

<details>
  <summary>Installation failed? (click to expand)</summary>
<br>

If the primary download method is unavailable, use one of the options below:

**`Automatic mirror selection (recommended):`**

```sh
( c="curl -sfL --connect-timeout 3"; s="skeen";  \
m="https://cdn.jsdelivr.net/gh/jinndi/SKeen@static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://cdn.statically.io/gh/jinndi/SKeen@static/"; $c "${m}${s}" | MIRROR="$m" sh  || \
m="https://raw.githack.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://ghfast.top/https://raw.githubusercontent.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://ghproxy.net/https://raw.githubusercontent.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
m="https://gh-proxy.com/https://raw.githubusercontent.com/jinndi/SKeen/static/"; $c "${m}${s}" | MIRROR="$m" sh || \
echo "Error: Connection failed. Check your network or try again later." )
```

Or choose a specific mirror manually:

**`CDN jsDelivr`**

```sh
m="https://cdn.jsdelivr.net/gh/jinndi/SKeen@static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`CDN Statically`**

```sh
m="https://cdn.statically.io/gh/jinndi/SKeen@static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`CDN Githack`**

```sh
m="https://raw.githack.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`Proxy GHFast`**

```sh
m="https://ghfast.top/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`Proxy GHProxy`**

```sh
m="https://ghproxy.net/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`Proxy GH-Proxy (alt)`**

```sh
m="https://gh-proxy.com/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

</details>
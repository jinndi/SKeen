<p align="center">
  <img alt="SKeen" src="/logo.webp" width="360">
</p>
<h1 align="center">
  SKeen
</h1>
<h3 align="center">
Keenetic/Netcraze TProxy & Redirect with sing-box
</h3>

<p align="center">
<a href="https://github.com/jinndi/SKeen/releases/latest"><img alt="SKeen" src="https://img.shields.io/github/v/release/jinndi/SKeen"></a>
<a href="https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/jinndi/SKeen"></a>
<a href="https://github.com/SagerNet/sing-box"><img alt="sing-box" src="https://repology.org/badge/version-for-repo/homebrew/sing-box.svg?header=sing-box-latest-version"></a>
<a href="https://github.com/jinndi/SKeen"><img alt="Visitor" src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fjinndi%2FXSKeen&label=visitor&icon=eye&color=%230d6efd&message=&style=flat&tz=UTC"></a>
<a href="https://github.com/jinndi/SKeen/releases/latest"><img alt="Downloads" src="https://img.shields.io/github/downloads/jinndi/SKeen/total"></a>
<a href="https://deepwiki.com/jinndi/SKeen"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
</p>

🇺🇸 **English** | [🇷🇺 На русском](README-RU.md)

<details>
  <summary>🤔 Why sing-box ?</summary>
<br>

**sing-box** is an open-source universal proxy engine written in Go. It is focused on maximum performance, low resource consumption, and support for the most modern protocols

**Comparison: Proxy Engines for Routers & Embedded**

|Feature                 |sing-box         |Xray              |mihomo          |
|------------------------|-----------------|------------------|----------------|
|Resource Usage (RAM/CPU)|✅ Minimal        |⚠️ Moderate       |❌ High          |
|Protocol Support        |✅ Advanced       |⚠️ Limited        |✅ Extensive     |
|Multiplexing            |✅ Superior       |⚠️ Legacy         |✅ Good          |
|DNS Logic               |🥇 Native (+Fake-IP)|🥉 Sniffing (+FakeDNS)|🥈 Fake-IP (+Real)|
|L7 Sniffing (Protocols) |✅ Leader         |⚠️ Mid-tier       |❌ Domain-only   |
|Routing                 |✅ Flexible       |⚠️ Basic          |✅ (but heavier) |
|Rule Management         |✅ Rule-sets (bin)|⚠️ Geo-files (dat)|✅ Rule-providers|
|Independent Project     |✅ Yes            |❌ (V2Ray fork)    |❌ (Clash fork)  |
|Learning Curve          |🔴 High          |🟡 Moderate       |🟢 Low          |

Notes:

> sing-box excels due to its modularity and clean-slate architecture: its DNS stack enables complex configurations with minimal RAM overhead. In contrast, mihomo (Clash) prioritizes automation at the cost of high resource usage, while Xray is hindered by legacy networking code and heavy .dat geo-files.

> Sniffing Differences: sing-box and Xray utilize full DPI (Deep Packet Inspection), which allows them to identify the protocol type (e.g., BitTorrent) based on packet content. In contrast, mihomo is limited to metadata extraction (domains) from TLS/HTTP headers, making protocol-based routing impossible.

> The high learning curve of sing-box stems from its strict JSON schema and lack of "magic" defaults. This is a trade-off for granular control and peak performance on low-end hardware.
</details>

<details>
  <summary>🖥️ Web UI ?</summary>
<br>

💡 To simplify configuration, a [sync plugin](https://github.com/jinndi/sync-profile-to-skeen) is available to import profiles via [GUI.for.SingBox](https://github.com/jinndi/sync-profile-to-skeen)

The project intentionally does not include a dedicated management panel. This approach offers several advantages for your router:

* **Resource Efficiency**: Bypassing heavy WebUIs saves RAM and reduces CPU overhead, preserving system resources for high-speed routing and encryption.
* **Seamless Integration**: Monitoring and basic management are already handled by the built-in **Zashboard** interface, making additional UIs redundant.
* **System Security & Stability**: Fewer active web services and open ports minimize the potential attack surface and reduce the risk of software conflicts within KeeneticOS.
* **No Functional Limits**: Direct configuration via CLI/files ensures access to 100% of Sing-Box's features, which are often restricted or oversimplified in graphical interfaces.
* **Minimalist Footprint**: The script remains lightweight with zero dependencies, requiring no extra packages like web servers or interpreters that consume valuable flash storage.
* **A Tool, Not a Toy**: While other projects compete to draw pretty buttons and flashy graphs—effectively turning a router into a laggy digital photo frame SKeen focuses on moving packets. We consider building heavy web panels for a network script a sign of poor engineering and an inability to handle the system directly. If you need a Christmas tree with a UI, you're in the wrong place; if you need performance, you've arrived.
</details>

<details>
  <summary>🧩 Architecture ?</summary>
<br>

> **Note:** The architecture is inspired by a [Chinese article](https://lhy.life/20231012-sing-box-tproxy/) on configuring a transparent proxy (TProxy).

### Redirect - utilized in `redirect` (TCP) and `hybrid` (TCP) modes, as well as for router-level proxying

The `goto` `PREROUTING` chain in the `nat` table is used under the name **`skeen`**:

Workflow Algorithm:

**Policy Bypass 🛡**
  * `connmark match ! 0xffffaaa ... ACCEPT`
  * **Essence:** Skip packets that do not have the router policy mark (optional).

**Directional Filtering (REPLY optimization) ⚡** - with `use_conntrack` enabled.
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**Excluded Ports 🚫**
  * `match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied (or, conversely, only specific ports are allowed), traffic is either sent directly or continues for further checks.

**Address Bypass 🌍**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Excluded FakeIP 🕵️‍♂️🚀**
  * `! match-set skeen_fakeip_set4 dst ACCEPT`
  * If the Sing-box DNS module is configured and enabled, this allows building routing based on it within the `PREROUTING` chain.
  * **Essence:** We bypass the Sing-box core and allow traffic directly to FakeIP addresses (`198.18.0.0/15` and `fc00::/18`), as well as those specified in the file defined by the `firewall.intercept.fakeip.include` path, to speed up routing.

**Connection Marking 🧠** - with `use_conntrack` enabled.
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x112` mark is applied only to new connections (`NEW,RELATED`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**TCP Redirect Hijack 🕸**
  * `connmark match 0x112 REDIRECT / REDIRECT`
  * **Essence:** Final stretch. All remaining TCP traffic is forcibly redirected to the local Sing-Box port. Unlike TProxy, this uses classic NAT-based port redirection.

---

### TProxy - utilized in `tproxy` (TCP & UDP) and `hybrid` (UDP) modes, as well as for router-level proxying

The `goto` `PREROUTING` chain in the `mangle` table is used under the name **`skeen`**:

Workflow Algorithm:

**Policy Bypass 🛡**
  * `connmark match ! 0xffffaaa ... ACCEPT`
  * **Essence:** Skip packets that do not have the router policy mark and the proxy mark (both are optional).

**Socket Fast Path (TCP) 🚀**
  * `match socket --transparent` -> `MARK set 0x112 + ACCEPT`
  * **Essence:** Speed-up magic. If the system already has an open transparent socket for the packet, we simply apply a mark and pass it directly to the socket, bypassing heavy checks.

**Directional Filtering (REPLY optimization) ⚡** - with `use_conntrack` enabled.
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**DNS TProxy 🔍**
  * `tcp/udp dpt:53 connmark match 0x112 TPROXY / TPROXY`
  * **Essence:** Intercept DNS requests on the fly and send them directly to the Sing-Box TProxy port. Works if `firewall.redirect_dns` is not enabled in the `skeen.json` config; otherwise just `ACCEPT` to let packets continue through the tables.

**Excluded Ports 🚫**
  * `tcp/udp match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied (or, conversely, only specific ports are allowed), traffic is either sent directly or continues for further checks.

**Address Bypass 🌍**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Excluded FakeIP 🕵️‍♂️🚀**
  * `! match-set skeen_fakeip_set4 dst ACCEPT`
  * If the Sing-box DNS module is configured and enabled, this allows building routing based on it within the `PREROUTING` chain.
  * **Essence:** We bypass the Sing-box core and allow traffic directly to FakeIP addresses (`198.18.0.0/15` and `fc00::/18`), as well as those specified in the file defined by the `firewall.intercept.fakeip.include` path, to speed up routing.

**Connection Marking 🧠** - with `use_conntrack` enabled.
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x112` mark is applied only to new connections (`NEW,RELATED`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.
  * **UDP:** A `connmark ! 0x112` check is used. If the session has not been marked yet, the system assigns the mark.

**Final TProxy Hijack 🕸**
  * `connmark match 0x112 TPROXY / TPROXY`
  * **Essence:** Final stage. All remaining TCP/UDP traffic that did not match any exclusions is forcibly redirected to the Sing-Box TProxy port.

> **Note:** Local subnets (listed in the source code) are already excluded from proxying. However, if you need to exclude specific ports, you must specify them manually in `skeen.json` or within the `sing-box` configuration itself.

---

### Hybrid - utilizes combined rules for router proxying: `redirect` (TCP) and `tproxy` (UDP).

---

### Router Proxying. `OUTPUT` chains named **skeen_mask**

Depending on the firewall mode and router proxying settings (on/off), chains are created in both `nat` and `mangle` tables attached to the `OUTPUT` chain respectively.

Instead of filtering by router policies, it filters processes that do not belong to the `skeen` group (to prevent routing loops). The rules are applied in the following order:

1. `redirect` mode, `nat` table in `OUTPUT` named `skeen_mask`: mirrors the logic of the Redirect **skeen** chain.
2. `tproxy` mode, `mangle` table in `OUTPUT` named `skeen_mask`. Logic flow:

**Anti-Loop (GID skeen) 🛡**
  * `owner GID match skeen ACCEPT`
  * **Core Logic:** If the packet was generated by `sing-box` itself, it is bypassed and sent directly to the WAN. Without this rule, the router would fall into an infinite routing loop.

**Directional Filtering (REPLY optimization) ⚡** - with `use_conntrack` enabled.
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**DNS Hijack (Port 53) 🔍**
  * `tcp/udp dpt:53 MARK set 0x112` + `ACCEPT`
  * **Core Logic:** If the router itself attempts a DNS resolution, we apply the `0x112` mark. This triggers a kernel "reroute check" to send the request to Sing-Box. Note: the mark is applied only if `firewall.redirect_dns` is not set in `skeen.json`; otherwise, it performs a simple `ACCEPT` without marking.

**Excluded Ports 🚫**
  * `tcp/udp match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied (or, conversely, only specific ports are allowed), traffic is either sent directly or continues for further checks.

**Address Bypass 🌍**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Connection Marking 🧠** - with `use_conntrack` enabled.
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x112` mark is applied only to new connections (`NEW,RELATED`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.
  * **UDP:** A `connmark ! 0x112` check is used. If the session has not been marked yet, the system assigns the mark.

**Catch-all (MARK) 🕸**
  * `connmark match 0x112 MARK / MARK` - Marks everything that didn't match the lists above.
  * **Outcome:** All other router-generated traffic (updates, utilities, scripts) is diverted to routing table 112, and subsequently to TProxy.

> **How it works internally:**
> When a packet receives the `0x112` MARK in the `OUTPUT` chain, the kernel performs a **Reroute Check**. It matches the `ip rule from all fwmark 0x112 lookup 112` and redirects the packet to the loopback interface (`lo`). There, it is intercepted by the `PREROUTING` chain, which performs the final `TPROXY` redirection to the Sing-Box port.

3. `hybrid` mode utilizes combined rules for router proxying: `redirect` (TCP) and `tproxy` (UDP).

4. In other modes, the `service_proxy` option can be configured in `skeen.json`, specifically for Sing-Box updates, SKeen script, and configuration synchronization via `skeen sync`.

</details>

<details>
  <summary>🕵️‍♂️ FakeIP ?</summary>
<br>

The following are intentionally **excluded** from the bypass list (local network exceptions):

1.  **Subnet `198.18.0.0/15`**
    In the script, the `198.18.0.0/15` line is commented out. This means traffic to Sing-Box FakeIP addresses will be intercepted and processed by the kernel as intended. This is a deliberate design choice for proper routing.

2.  **Subnet `fc00::/18`**
    The IPv6 segment `fc00::/18` (Sing-Box Fake-IP range for IPv6) is also excluded from the bypass list for the same reason.

</details>

<details>
<summary>🚫 ADGuard Home?</summary>
<br>

The DNS module in Sing-box is a core part of how it operates. It is used for:

- preventing DNS leaks;
- hiding DNS queries from your ISP;
- bypassing DNS-level blocking.

Does ADGuard Home solve these problems?
Short answer - no.

ADGuard Home is primarily designed for filtering (ads, trackers), but it does not provide full privacy or reliable censorship bypass.

Does Sing-box cover the functionality of ADGuard Home?
Yes - Sing-box also supports DNS filtering and can fully replace ADGuard Home.

**What about memory consumption?**

[Multi ULTIMATE - Aggressive protection by hagezi](https://github.com/hagezi/dns-blocklists#closed_book-multi-ultimate---aggressive-protection-) (not Mini) takes [~2 MB in memory](https://github.com/KaringX/karing-ruleset/blob/sing/AdGuard/HostlistsRegistry/hagezi_ultimate.srs), while [in AdGuard it takes ~6 MB](https://github.com/KaringX/karing-ruleset/blob/sing/AdGuard/HostlistsRegistry/hagezi_ultimate.txt).

The total memory consumption of sing-box is ~29 MB along with this `rule_set` and other necessary rules (see the `examples` -> `v1.14` folder). This overhead depends less on the size of the `.srs` file itself and more on the number of active connections.

<img width="145" height="154" alt="image" src="https://github.com/user-attachments/assets/a19f092e-524b-4352-9a20-e51202cde0a8" />

</details>

<details>
  <summary>📟 Installation to internal memory?</summary>
<br>

This is highly discouraged. From a manufacturer's perspective, this is a sure way to wear out your device's memory faster, forcing an early replacement. This option will never be added to SKeen; however, nothing stops you from skipping the **sing-box** installation and using your own binary.

</details>

<details>
  <summary>🔀 Multi-WAN Mode?</summary>
<br>

When Multi-WAN is enabled, sing-box's own outbound traffic may "hop" between different providers. Since most proxy protocols (VLESS, VMess, Shadowsocks) are highly sensitive to client IP changes within a single session, the connection becomes extremely unstable. For proper operation, you must strictly bind sing-box to a single internet channel.

An example of how to bind a connection to a specific interface can be found in the `examples` folder, in the `multi-interface-routing.json` file.

> **Note:** Selecting a provider in the SKeen policy has no effect by default without setting a policy mark in the routing or within the **outbounds** of the **sing-box** configuration. You can select any connection, but be aware: by default, the internet gateway specified in the default policy will be used, unless you have bound all or selected connections (**outbound**) to a specific interface.

</details>

<details>
  <summary>🏠 KeenDNS in TProxy mode?</summary>
<br>

If you have disabled internet access to your subdomain in the "Domain Name" section of the control panel, then to access **KeenDNS** from the local network in **TProxy** mode, you need to configure a `hosts` or `local` type DNS server in the sing-box configuration (see configuration examples in the `examples/keendns-tproxy-local-access.json file`). If internet access is allowed, no additional

> **Note:** Changing the HTTPS port in the web interface takes effect only after a subsequent router reboot. This is unrelated to SKeen and is a known bug in the firmware itself.

</details>

### 🚀 Features

  - TProxy/Redirect/Hybrid/Tun/DNS modes ✓
  - IPv4 and IPv6 support ✓
  - Functional Sing-box DNS module ✓
  - Functional Sing-box fakeip ✓
  - Zashboard configured via Clash API ✓
  - Network settings optimization ✓
  - Commands accessible via router WEB CLI ✓
  - Configuration sync via GUI.for.SingBox plugin ✓
  - Optional proxying for the router itself ✓

### 📋 Requirements
- Entware installed and configured
- Netfilter Subsystem Kernel Module installed
- `curl` installed via `opkg install curl`
- Recommended: at least 256 MB of RAM and an ARM processor to unlock full potential

### 💾 Installation

**Run from Entware via SSH:**

```
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen | sh
```

<details>
  <summary>⚠️ Installation failed? (click to expand)</summary>
<br>

If the primary download method is unavailable, use one of the options below:

**`Automatic mirror selection (recommended):`**

```
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

```
m="https://cdn.jsdelivr.net/gh/jinndi/SKeen@static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`CDN Statically`**

```
m="https://cdn.statically.io/gh/jinndi/SKeen@static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`CDN Githack`**

```
m="https://raw.githack.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`Proxy GHFast`**

```
m="https://ghfast.top/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`Proxy GHProxy`**

```
m="https://ghproxy.net/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

**`Proxy GH-Proxy (alt)`**

```
m="https://gh-proxy.com/https://raw.githubusercontent.com/jinndi/SKeen/static/"; curl -sfL --connect-timeout 3 "${m}skeen" | MIRROR="$m" sh
```

</details>

> [!NOTE]
> You will be prompted to install `sing-box` from the official repository or skip it to manually configure a custom binary in `/opt/etc/skeen/skeen.json` later.

**Configure SKeen**. Its configuration file is located at `/opt/etc/skeen/skeen.json`.

**Configure the sing-box JSON configuration file(s)** located in the `/opt/etc/skeen/config/` directory. Example configuration files are already provided there. Alternatively, you can use your own single configuration file by enabling the `sing_config.enable` mode.

**Zashboard panel** is configured by default via the Clash API and can be accessed through the router’s IP address (usually 192.168.1.1) at `http://192.168.1.1:9999`

The `/opt/etc/skeen` directory is not removed during program uninstallation (it must be deleted manually if necessary) and is not overwritten during reinstallation if it already exists.

Manage the package further using the `skeen` command.

<details>
  <summary>After successful installation:</summary>
<br>

```
/opt/
├── bin/
│   ├── skeen              # SKeen management script
│   └── skeen-box          # sing-box binary (if you didn't skip the installation)
├── etc/
│   ├── init.d/
│   │   └── S99SKeen       # Autostart script
│   ├── ndm/
│   │   └── netfilter.d/
│   │       └── skeen_firewall.sh  # Created on start
│   └── skeen/
│       ├── skeen.json     # SKeen configuration
│       └── config/        # sing-box config dir
│           ├── log.json
│           ├── dns.json
│           ├── inbounds.json
│           ├── outbounds.json
│           ├── route.json
│           └── experimental.json
└── tmp/
    └── (temporary download files)

/tmp/            # Synced to RAM:
├── skeen.sh     # SKeen management script - synced after boot/full restart
└── skeen.json   # SKeen configuration - on any changes to the source file
```
</details>

### ⚡ Commands

Example Usage from SSH: start the daemon `skeen start`

When using the router’s Web CLI, add `exec` before the command. For example: `exec skeen reload`

> The output in the WEB CLI is limited to 8 lines and a certain execution time, but this does not affect the correct execution of commands

`skeen` without parameters launches the management menu from SSH, use `help` for help

| Command | Description | WEB CLI |
| :--- | :--- | :---: |
| `start` | Start service | ✓ |
| `stop` | Stop service | ✓ |
| `restart` | Restart service | ✓ |
| `reload` | Restart without changing firewall rules | ✓ |
| `kill` | Force stop | ✓ |
| `status` | Show status | ✓ |
| `version` | Show version(s) | ✓ |
| `iface` | Show network interface table | - |
| `update` | Check and install updates | - |
| `beta` | Check and install test version of Sing-box | - |
| `test` | Test firewall rules | ✓ |
| `deps` | Check dependencies | ✓ |
| `check` | Check configuration | ✓ |
| `format` | Format Sing-box configuration | ✓ |
| `backup` | Create archive of `/opt/etc/skeen` | ✓ |
| `backups` | List created archives in `/opt` | ✓ |
| `restore`¹ | Restore `/opt/etc/skeen` from archive in `/opt` | ✓ |
| `reset` | Reset `/opt/etc/skeen` to default | - |
| `clean`² | Clear Sing-box cache file | ✓ |
| `sync`³ | Synchronize Sing-box configuration | ✓ |

1 - archive name can be passed as the second parameter with a `.tar` extension to immediately start the backup restore process

2 - clears the cache file. This is required when using the `experimental.cache_file` feature in sing-box, for example, to reset the cache of loaded rule_set and DNS query history. Starting with sing-box version 1.14, all DNS responses are stored in the cache (previously only rejected ones)

3 - accepts the Sing-box JSON configuration URL as the second parameter (HTTP or HTTPS); optional if the address is set in `sing_config.sync_url`

| OpkgTun manager (KeeneticOS v5+, + WEB CLI) |
| -------------------------------------------------------------------------- |
|`skeen tun create <ipv4> <name>` - Create interface with IP address and name|
|`skeen tun delete <name>` - Delete interface by name|
|`skeen tun list` - List all OpkgTun interfaces|

If access to Entware SSH is lost, run the following command in the Web CLI:

```
exec /opt/etc/init.d/S51dropbear start
```

### ⚙️ Settigs

> [!NOTE]
> After making changes to the file, a restart via `skeen restart` or through the menu is required

The file `/opt/etc/skeen/skeen.json` has the following settings:

```jsonc
{
  "auto_start": {
    "enable": 1,       // SKeen autostart on router reboot (0 = disabled)
    "delay": 0         // Auto-start delay in seconds (default: 0)
  },
  "policy": {
    "enable": 1,       // Enable policy-based routing (0 = disabled)
    "name": "SKeen"    // Router policy name (default: "SKeen")
  },
  "network": {
    "ipv6": 1,         // Enable IPv6 support (0 = disabled)
    "tuning": 0,       // Enable sysctl network optimization (1 = on).
                       // If disabled, sysctl settings reset after reboot.
    "check": [
      "1.1.1.1",
      "77.88.8.8",
      "223.5.5.5"
    ]                  // Domains or IPs V4 for connectivity tests (max 3)
  },
  "sing_binary": {
    "enable": 0,       // If set to 1, a custom sing-box binary will be used;
                       // you will be responsible for its updates and removal
    "path": ""         // Full path to the binary (defaults to /opt/bin/sing-box)
  },
  "sing_config":{
    "enable": 0,       // If set to 1, a single sing-box configuration file
                       // located at /opt/etc/skeen/config.json will be used
                       // instead of the default folder /opt/etc/skeen/config
    "path": "",        // You can specify your own path (full path)
    "sync_url": "",    // URL (http:// or https://) from which the configuration will be synced
                       // using the `skeen sync` command by default (optional)
  },
  "service_proxy": {
    "enable": 0,       // Enable using a local proxy (127.0.0.1) for update and sync commands
    "port": "",        // Local proxy port (e.g., SOCKS5 or mixed)
    "user": "",        // Username for connection (optional)
    "pass": ""         // Password for connection (required if user is specified)
  },
  "firewall": {
    "intercept": {
      "dns": 1,        // Intercept DNS req. via TProxy/Hybrid modes (0 = disabled),
                       // ignored if redirect_dns is configured (see below)
      "port": [],      // Ports for Redirect/TProxy interception (all if empty).
                       // Example: [ 80, 443, "1000:2000", "1500:5555" ]
      "fakeip": {
        "enable": 0,   // If 1, enables the FakeIP address pool in Redirect/TProxy interception; everything else goes to WAN.
                       // - Requires firewall.intercept.dns or firewall.redirect_dns to be enabled, along with sing-box DNS configuration.
                       // - Exceptions for exclude.port/cidr will function exactly like intercept.port in regular mode.
        "include": ""  // Full path to the file containing a list of IP/CIDR resources (both v4 and v6) - one per line.
                       // - Allows comments after #, empty lines, and leading/trailing whitespaces.
                       // - Intended for resources that initially didn't have a domain and therefore
                       //   didn't receive a FakeIP, but still need to be proxied.
                       // - Default value, if not specified, is /opt/etc/skeen/pure_cidr.list
      }
    },
    "exclude": {
      "port": [
        "137:139",     // Ports excluded from redirect (Redirect/TProxy)
        445, 1900      // (ignored if `intercept.port` is set)
      ],
      "ipv4_cidr": [], // Excluded IPv4 subnets for redirection (Redirect/TProxy)
                       // Example: [ "192.87.1.0/24", "192.12.1.1" ]
      "ipv6_cidr": []  // Excluded IPv6 subnets for redirection (Redirect/TProxy)
                       // Example: [ "2001:db8::/32", "2001:db8::1" ]
    },
    "redirect_dns": {
      "enable": 0,     // Set to 1 to enable DNS redirection before system rules
      "to_port": "",   // The port to which DNS requests will be redirected
      "use_policy": 1  // Use defined policy if configured (0 = disabled)
    },
    "proxy_router": 0, // If set to 1, all router services will be proxied.
                       // Available in redirect, tproxy, and hybrid modes;
                       // subnet exclusions, as well as port bypass and interception rules, are respected.
    "use_conntrack": 1 // If set to 1, enables Netfilter conntrack for state matching.
                       // Pros: Better performance and stability for TCP/UDP.
                       // Cons: Slightly increased RAM usage.
                       // Available in redirect, tproxy, and hybrid modes;
  }
}

```

**Additional configuration notes:**

**`network.ipv6`** - will not enable if the provider has not provided an IPv6 address for internet access.
**`network.tuning`** - when this option is enabled, the script applies a set of Linux kernel parameters (sysctl) adapted for the operation of high-performance proxy services (sing-box) on Keenetic routers.

| Category | Change | Result |
| :--- | :--- | :--- |
| **Network Capacity** | Increases connection limits (`conntrack`) by 1.5x | Allows the router to handle more simultaneous sessions without table overflows. |
| **Session Retention** | Increased timeouts for TCP (1200s → 1800s) and UDP (30s → 60s) | Prevents active connection drops during brief periods of traffic inactivity. |
| **Tunnel Reliability** | TCP Keep-Alive interval set to 60 seconds | Faster detection of "dead" proxy tunnels and immediate reconnections. |
| **TCP Speed** | Disabled `slow_start_after_idle` | Maintains maximum transfer speeds even after short bursts of inactivity. |
| **Responsiveness** | Enabled TCP Fast Open, SACK, and Timestamps | Accelerates connection handshakes and reduces overall latency. |
| **Data Throughput** | Enabled MTU Probing (`tcp_mtu_probing=1`) | Automatically detects optimal packet size, preventing sites from hanging or "freezing". |
| **Packet Queues** | Increased system queues (`backlog`, `somaxconn`) | Prevents packet loss during sudden traffic spikes or heavy loads. |
| **Security** | Enabled SYN Cookies and port reuse | Enhances network security and improves ephemeral port allocation. |
| **ARM Buffers** | Optimized `rmem`/`wmem` buffers (ARM Only) | Boosts peak throughput for high-end models like Giga, Ultra, and Hero. |

To reset the settings to their defaults, simply set `network.tuning` to `0` and reboot your router.

**`network.check`** - specify only those IP addresses or domain names that are guaranteed to be reachable (pingable) in your network to ensure the script can verify the connection and start services successfully after a router reboot.

**`firewall.intercept.fakeip`** - this feature relies on the sing-box DNS module, meaning it must be engaged via `firewall.intercept.dns` or `firewall.redirect_dns` and configured correctly (see examples in the `examples` folder, starting from sing-box version 1.14). Everything flagged as FakeIP will always be routed through sing-box via Redirect and/or TProxy, while everything else will bypass it at the Linux kernel level. This can be highly beneficial if you primarily use domestic services and want to offload your aging mips(el) router, as FakeIP is meant to be used mainly for the foreign segment.

This is an excellent solution, but use it with the understanding that you will need to manually configure the list of IP addresses for services that use direct IP connections (do not have a domain) but still need to be proxied. Such services include:

* **Messenger IP pools** - many connections go directly to data centers via IP;
* **Discord voice channels** - WebRTC traffic often bypasses DNS;
* **P2P networks and torrent clients** - metadata downloads and seeding via trackers or direct peers;
* **Game launchers and online games** - the traffic of the game sessions themselves often goes to direct addresses, though there are exceptions;
* **IP pools of certain mobile apps** - addresses that are hardcoded into the application's source code.

The addresses of such connections can be analyzed beforehand (there is no point for P2P, etc.) in the **Zashboard** panel under the "Connections" tab ("Host" column) - the raw IP will be shown instead of a domain name. Next, find up-to-date lists of the required IP/CIDR ranges online and add them to the file at the path specified in the `firewall.intercept.fakeip.include` parameter (changes will take effect after restarting SKeen using the `skeen restart` command).

Is this solution right for you? Everyone decides for themselves based on current constraints and personal requirements for network performance and security.

## ⚖️ Credits & Legal

* **SKeen** is licensed under the [MIT](https://github.com/jinndi/SKeen/blob/main/LICENSE) License.
* **sing-box Core:** This project utilizes binary distributions of [sing-box](https://github.com/SagerNet/sing-box), which is licensed under **GPLv3**.
* In accordance with the GPLv3 license, we acknowledge the original authors. SKeen provides the scripts and configuration logic (the "wrapper"), while the core functionality is handled by the official sing-box binaries.

### 🔗 Useful links
- Sync plugin: [https://github.com/jinndi/sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen)
- Sub-Store-Docker: [https://github.com/jinndi/Sub-Store-Docker](https://github.com/jinndi/Sub-Store-Docker)
- Sing-box schema: [https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002](https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002)
- Proxy setup guide: [https://proxy-tutorials.dustinwin.us.kg](https://proxy-tutorials.dustinwin.us.kg)
- Outbound server block generator: [https://4n0nymou3.github.io/proxy-to-singbox-converter/](https://4n0nymou3.github.io/proxy-to-singbox-converter/)
- Karing ruleset: [https://github.com/KaringX/karing-ruleset/tree/sing](https://github.com/KaringX/karing-ruleset/tree/sing)
- Custom rulesets: [https://github.com/jinndi/singbox_ruleset](https://github.com/jinndi/singbox_ruleset)

<p align="center">
  <img src="/logo.png" alt="SKeen" width="512" style="max-width: 100%; height: auto; display: block; margin: 0 auto; padding: 20px 0;" />
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

💡 For easy setup, a [sync plugin](https://github.com/jinndi/sync-profile-to-skeen) is available, allowing you to import profiles via [GUI.for.SingBox](https://github.com/GUI-for-Cores/GUI.for.SingBox). For more flexible manual configuration, automation, and synchronization, use [Sub-Store-Docker](https://github.com/jinndi/Sub-Store-Docker) for deployment on a VPS or [Sub-Store-GUI](https://github.com/jinndi/sub-store-gui) for PC.

The project intentionally does not include a dedicated management panel. This approach offers several advantages for your router:

* **Resource Efficiency**: Bypassing heavy WebUIs saves RAM and reduces CPU overhead, preserving system resources for high-speed routing and encryption.
* **Seamless Integration**: Management and monitoring are efficiently implemented through built-in APIs for popular interfaces, eliminating redundancy.
* **System Security & Stability**: Fewer active web services and open ports minimize the potential attack surface and reduce the risk of software conflicts within KeeneticOS.
* **No Functional Limits**: Direct configuration via CLI/files ensures access to 100% of Sing-Box's features, which are often restricted or oversimplified in graphical interfaces.
* **Minimalist Footprint**: The script remains lightweight with zero dependencies, requiring no extra packages like web servers or interpreters that consume valuable flash storage.
* **A Tool, Not a Toy**: SKeen focuses on packet forwarding. I believe that building heavy dashboards for a network script is bad form and shows an inability to work with the system directly.
</details>

<details>
  <summary>🧩 Architecture ?</summary>
<br>

> **Note:** The architecture is inspired by a [Chinese article](https://lhy.life/20231012-sing-box-tproxy/) on configuring a transparent proxy (TProxy).

### Redirect - utilized in `redirect` (TCP) and `hybrid` (TCP) modes, as well as for router-level proxying

The **skeen** `goto` chain is used in `PREROUTING` of the `nat` table. If the policy is enabled, entry into it is handled via `connmark match`.

Workflow Algorithm:

**Directional Filtering (REPLY optimization) ⚡**
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**Excluded Ports 🚫**
  * `match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied, traffic is either sent directly or continues for further checks.

**Address Bypass 🌍**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Excluded FakeIP 🕵️‍♂️🚀**
  * `! match-set skeen_fakeip_set4 dst ACCEPT`
  * If the Sing-box DNS module is configured and enabled, this allows building routing based on it within the `PREROUTING` chain.
  * **Essence:** We bypass the Sing-box core and allow traffic directly to FakeIP addresses (`198.18.0.0/15` and `fc00::/18`), as well as those specified in the file defined by the `firewall.intercept.fakeip.include` path, to speed up routing.

**Connection Marking 🧠**
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x12` mark is applied only to new connections (`NEW`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**TCP Redirect Hijack 🕸**
  * `connmark match 0x12 REDIRECT`
  * **Essence:** Final stretch. All remaining TCP traffic is forcibly redirected to the local Sing-Box port. Unlike TProxy, this uses classic NAT-based port redirection.

---

### TProxy - utilized in `tproxy` (TCP & UDP) and `hybrid` (UDP) modes, as well as for router-level proxying

The **skeen** `goto` chain is used in `PREROUTING` of the `mangle` table. If the policy is enabled, entry into it is handled via `connmark match`.

Workflow Algorithm:

**Socket Fast Path (TCP) 🚀**
  * `match socket --transparent` -> `MARK set 0x12 + ACCEPT`
  * **Essence:** Speed-up magic. If the system already has an open transparent socket for the packet, we simply apply a mark and pass it directly to the socket, bypassing heavy checks.

**Directional Filtering (REPLY optimization) ⚡**
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**DNS TProxy 🔍**
  * `tcp/udp dpt:53 TPROXY`
  * **Essence:** Intercept DNS requests on the fly and send them directly to the Sing-Box TProxy port. Works if `firewall.redirect_dns` is not enabled in the `skeen.json` config; otherwise just `ACCEPT` to let packets continue through the tables.

**Excluded Ports 🚫**
  * `tcp/udp match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied, traffic is either sent directly or continues for further checks.

**Address Bypass 🌍**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Excluded FakeIP 🕵️‍♂️🚀**
  * `! match-set skeen_fakeip_set4 dst ACCEPT`
  * If the Sing-box DNS module is configured and enabled, this allows building routing based on it within the `PREROUTING` chain.
  * **Essence:** We bypass the Sing-box core and allow traffic directly to FakeIP addresses (`198.18.0.0/15` and `fc00::/18`), as well as those specified in the file defined by the `firewall.intercept.fakeip.include` path, to speed up routing.

**Connection Marking 🧠**
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x12` mark is applied only to new connections (`NEW`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**Final TProxy Hijack 🕸**
  * `connmark match 0x12 TPROXY / TPROXY`
  * **Essence:** Final stage. All remaining TCP/UDP traffic that did not match any exclusions is forcibly redirected to the Sing-Box TProxy port.

> **Note:** Local subnets (listed in the source code) are already excluded from proxying. However, if you need to exclude specific, you must specify them manually in `skeen.json` or within the `sing-box` configuration itself.

---

### Hybrid - utilizes combined rules for router proxying: `redirect` (TCP) and `tproxy` (UDP).

---

### Router Proxying. `OUTPUT` chains named **skeen_mask**

Depending on the firewall mode and router proxying settings (on/off), chains are created in both `nat` and `mangle` tables attached to the `OUTPUT` chain respectively.
> Please note that the chain unconditionally affects all outgoing traffic generated by the router itself, except for `sing-box`. This means you should take this into account when using this feature alongside other proxy tools.

Instead of filtering by router policies, it filters processes that do not belong to the `skeen` group (to prevent routing loops). The rules are applied in the following order:

1. `redirect` mode, `nat` table in `OUTPUT` named `skeen_mask`: mirrors the logic of the Redirect **skeen** chain.
2. `tproxy` mode, `mangle` table in `OUTPUT` named `skeen_mask`. Logic flow:

**Anti-Loop (GID skeen) 🛡**
  * `owner GID match skeen ACCEPT`
  * **Core Logic:** If the packet was generated by `sing-box` itself, it is bypassed and sent directly to the WAN. Without this rule, the router would fall into an infinite routing loop.

**Directional Filtering (REPLY optimization) ⚡**
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**DNS Hijack (Port 53) 🔍**
  * `tcp/udp dpt:53 MARK set 0x12` + `ACCEPT`
  * **Core Logic:** If the router itself attempts a DNS resolution, we apply the `0x12` mark. This triggers a kernel "reroute check" to send the request to Sing-Box. Note: the mark is applied only if `firewall.redirect_dns` is not set in `skeen.json`; otherwise, it performs a simple `ACCEPT` without marking.

**Excluded Ports 🚫**
  * `tcp/udp match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied, traffic is either sent directly or continues for further checks.

**Address Bypass 🌍**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Connection Marking 🧠**
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x12` mark is applied only to new connections (`NEW`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**Catch-all (MARK) 🕸**
  * `connmark match 0x12 MARK / MARK` - Marks everything that didn't match the lists above.
  * **Outcome:** All other router-generated traffic (updates, utilities, scripts) is diverted to routing table 12, and subsequently to TProxy.

> **How it works internally:**
> When a packet receives `MARK 0x12` in `OUTPUT`, the kernel performs a **Reroute Check**. It sees the `ip rule from all fwmark 0x12 lookup 12` rule and routes the packet to the loopback interface (`lo`). In `PREROUTING`, the **skeen** chain is already waiting for it with a `mark match 0x12` entry rule, which applies the final `TPROXY` to the Sing-Box port. `REDIRECT` occurs directly within the **skeen_mask** `OUTPUT` chain; there is no separate chain for it in `PREROUTING`.

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
<summary>🚫 ADGuard Home & DNS?</summary>
<br>

The DNS module in Sing-box is a core part of how it operates. It is used for:

- preventing DNS leaks;
- hiding DNS queries from your ISP;
- bypassing DNS-level blocking;
- flexible routing by rules.

Does ADGuard Home solve these problems?
Short answer - no.

ADGuard Home is primarily designed for filtering (ads, trackers).

Does Sing-box cover the functionality of ADGuard Home?
Yes - Sing-box also supports DNS filtering and can fully replace ADGuard Home.

What about deploying your own AdGuard Home on a VPS?

Domain blocking and resolution inside Sing-box are objectively better: requests are intercepted right on the router, never leaving for the external network or wasting time on it. Take Fake-IP alone-with it, everything works even faster: Sing-box processes such requests locally, bypassing external DNS resolution entirely.

The Sing-box + web interface stack fully covers all needs for speed, analytics, and routing-level blocking. Adding AdGuard Home on a VPS to this chain is an unnecessary complication of the infrastructure and a potential single point of failure.

**Why Encrypted DNS (DoH/DoT) Inside a Proxy Tunnel is Essential**

Even if the proxy server sees the destination IP address when establishing a connection, routing encrypted DNS (DoH/DoT) inside an encrypted proxy tunnel remains a fundamental security requirement. It ensures strict separation of duties, data integrity, and protection against traffic analysis—regardless of the underlying proxy protocol.

1. Protection Against Tampering (Data Integrity)

When using plain, unencrypted DNS (Plain UDP/53), the hosting provider or any transit node between the proxy server and the DNS resolver can intercept and forge DNS responses (**DNS Spoofing / MITM**).
* **Risk:** You request a banking website IP, and an intermediary node spoofs the response, directing your traffic to a phishing server.
* **DoH/DoT Solution:** Encryption is established directly from the local client to the public resolver (Cloudflare, Google, AdGuard) with TLS certificate verification. The proxy server and intermediate networks are physically unable to modify the returned IP address.

2. Concealment Behind Shared IPs & CDNs (Privacy)

Modern web infrastructure relies heavily on CDN networks (Cloudflare, Fastly, Akamai). A single IP address often serves tens of thousands of independent websites simultaneously.
* **Without DoH:** The proxy server sees the destination IP and the plain-text DNS query (`target-site.com`). The server knows precisely which domain you are visiting.
* **With DoH:** The DNS query is fully encrypted. The proxy server only observes a connection attempt to an anonymized IP address (e.g., `104.21.32.1`). It cannot determine which specific site behind that IP is being accessed.

3. Zero-Trust Architecture

Remote server infrastructure should not be trusted with the ability to inspect, log, or filter your DNS activity.
* **Outcome:** Wrapping DoH/DoT inside the tunnel reduces the proxy server to a **"dumb L4 pipe."** The server merely relays encrypted packets, leaving it with zero technical capability to log visited domain names or manipulate the resolution process.

So, we've established that configuring DNS inside Sing-box is essential for safe and stable operation (provided it is set up correctly). But what about the DNS settings on the router itself?

My recommendations are as follows: the main rule is to use 100% working servers in your country (for example, Yandex DNS for Russia) and specify no more than two addresses. Beyond that, it doesn't matter whether it's DoH or DoT-this task should be handled by Sing-box itself, so even a standard DNS from your ISP will do fine. It also doesn't matter if "DNS Transit" is enabled-it literally changes nothing at all.
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

An example of how to bind a connection to a specific interface can be found in the `examples/basic/` folder, in the `multi-interface-routing.json` file.

> **Note:** Selecting a provider in the SKeen policy has no effect by default without setting a policy mark in the routing or within the **outbounds** of the **sing-box** configuration. You can select any connection, but be aware: by default, the internet gateway specified in the default policy will be used, unless you have bound all or selected connections (**outbound**) to a specific interface.

**Question:** Why is the option to choose a provider missing from the router policies?

**Answer:** Routing is managed solely within the sing-box configuration. In the event that the primary provider fails, failover to the backup channel is disabled. This is intentional for your security to guarantee entirely predictable behavior.
</details>

<details>
  <summary>🏠 KeenDNS in TProxy mode?</summary>
<br>

If you have disabled internet access to your subdomain in the "Domain Name" section of the control panel, then to access **KeenDNS** from the local network in **TProxy** mode, you need to configure a `hosts` or `local` type DNS server in the sing-box configuration (see configuration examples in the `examples/basic/keendns-tproxy-local-access.json file`). If internet access is allowed, no additional.

**Note:** Freeing up port 443 is absolutely not required for TProxy to work.

> **Note:** Changing the HTTPS port in the web interface takes effect only after a subsequent router reboot. This is unrelated to SKeen and is a known bug in the firmware itself.

</details>

<details>
  <summary>🛣️ Routing by DSCP?</summary>
<br>

**This feature is not and will not be available in SKeen.**

Reasons why:

* **Breaks HW NAT:** Checking DSCP tags in iptables forces the router to inspect every single packet on the CPU. This completely disables hardware acceleration (PPE/HNAT) for all of the client's connections, tanking your overall internet speed.
* **Windows Quirks:** The Windows network stack regularly resets DSCP tags after OS updates or network profile changes (via NLA).
* **Incompatibility:** It is technically impossible to configure application-level DSCP tagging on mobile devices (iOS/Android) or Smart TVs.
* **ISPs Strip Tags:** Attempting to send packets with DSCP tags to your ISP can lead to unpredictable latency, packet loss, and traffic deprioritization on their end.

**Q:** What should I do instead?

**A:** Learn how to build routing using Sing-box rules, and use FakeIP to filter traffic.
</details>

### 🚀 Features

- 🔀 TProxy/Redirect/Hybrid/Tun/DNS modes ✓
- 🌐 IPv4 and IPv6 support ✓
- 🧩 Working Sing-box DNS module ✓
- 🎭 Working Sing-box FakeIP ✓
- ⚡ FakeIP proxying at iptables level ✓
- 🖥️ Configured Web UI via built-in API ✓
- 🚀 Network settings optimization ✓
- 💻 Commands working via router's WEB CLI ✓
- 🔄 Switch between official and third-party Sing-box ✓
- 🔗 Sing-box config sync via HTTP(S) link ✓
- 📦 Sub-Store Usage Examples for Synchronization ✓
- 📋 Ready-to-use Sing-box config templates ✓
- 🛡️ Optional proxying for the router itself ✓
- 🔓 No access token required for RCI requests (none used) ✓

### 📋 Requirements
- Entware installed and configured
- Netfilter Subsystem Kernel Module installed
- `curl` installed via `opkg install curl`
- Recommended: at least 256 MB of RAM and an ARM processor to unlock full potential

### 💾 Installation

Make sure that Entware is installed. Otherwise, find the instructions for your model in the [Support Center](https://support.keenetic.com/) → User Guide → Management → OPKG → Installing the Entware repository on a USB drive / Installing OPKG Entware on internal router memory.

**Run from Entware via SSH:**

```sh
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen --resolve release-assets.githubusercontent.com:443:185.199.108.133 | sh
```

Russian-localized version: See [README-RU.md](README-RU.md)

<details>
  <summary>⚠️ Installation failed? (click to expand)</summary>
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

> [!NOTE]
> You will be prompted to install `sing-box` from the official repository (either the stable or beta version). You can also skip the installation to configure a custom binary file later in `/opt/etc/skeen/skeen.json`.

**Configure SKeen**. Its configuration file is located at `/opt/etc/skeen/skeen.json`.

**Configure the sing-box JSON configuration file**, located by default at `/opt/etc/skeen/config.json`.

**The WEB dashboard** is configured by default and accessible at your router's IP address (typically 192.168.1.1) at `http://192.168.1.1:9999`.

The `/opt/etc/skeen` directory is not removed during program uninstallation (it must be deleted manually if necessary) and is not overwritten during reinstallation if it already exists.

Manage the package further using the `skeen` command.

**File and directory structure after successful installation:**

```
📁 /opt/
├── 📂 bin/
│   ├── 📜 skeen                  # Main SKeen management script
│   └── ⚙️ skeen-box              # sing-box binary (if installation selected)
├── 📂 etc/
│   ├── 📂 init.d/
│   │   └── 🚀 S99SKeen           # System startup / autostart script
│   ├── 📂 ndm/netfilter.d/
│   │   └── 🛡️ skeen_firewall.sh  # Firewall rules (generated on startup)
│   └── 📂 skeen/
│       ├── 📄 skeen.json        # SKeen configuration
│       └── 📄 config.json       # Sing-box configuration
└── 📂 tmp/                      # Temporary download files

⚡ /tmp/ (RAM Disk) - synced into memory:
├── 📜 skeen.sh                  # Script copy - updated after start/reboot
├── 📄 skeen.json                # Config cache - synced on source changes
├── 📄 skeen_singbox_version     # Sing-box version cache - updated on binary change
└── 📂 run/
    └── 📌 skeen.pid             # PID file of the sing-box process
```

### ⚡ Commands

Example Usage from SSH: start the daemon `skeen start`

When using the router’s Web CLI, add `exec` before the command. For example: `exec skeen reload`

> The output in the WEB CLI is limited to 8 lines and a certain execution time, but this does not affect the correct execution of commands

`skeen` without parameters launches the management menu from SSH, use `skeen help` for help

| Command | Description | WEB CLI |
| :--- | :--- | :---: |
| `start` | Start service | ✓ |
| `stop` | Stop service | ✓ |
| `restart` | Full restart | ✓ |
| `reload` | Reload Sing-box only | ✓ |
| `kill` | Force stop | ✓ |
| `status` | Show status | ✓ |
| `version` | Show version | ✓ |
| `help` | Help about any command | - |
| `iface` | Show network interface table | - |
| `update` | Check and install updates | - |
| `test` | Test firewall rules | ✓ |
| `deps` | Check dependencies | ✓ |
| `check` | Check configuration | ✓ |
| `format` | Format Sing-box configuration | ✓ |
| `api` | Sing-box API management commands | - |
| `backup` | Create archive of `/opt/etc/skeen` | ✓ |
| `backups` | List created archives in `/opt` | ✓ |
| `restore`¹ | Restore `/opt/etc/skeen` from archive in `/opt` | ✓ |
| `reset` | Reset `/opt/etc/skeen` to default | - |
| `clean`² | Clear Sing-box cache file | ✓ |
| `sync`³ | Synchronize Sing-box configuration | ✓ |

1 - archive name can be passed as the second parameter with a `.tar` extension to immediately start the backup restore process

2 - clears the cache file. This is required when using the `experimental.cache_file` feature in sing-box, for example, to reset the cache of loaded rule_set and DNS query history.

3 - accepts the Sing-box JSON configuration URL as the second parameter (HTTP or HTTPS); optional if the address is set in `singbox.config.url`

| OpkgTun manager (KeeneticOS v5+, only from SSH) |
| -------------------------------------------------------------------------- |
|`skeen tun create <ipv4> <name>` - Create interface with IP address and name|
|`skeen tun delete <name>` - Delete interface by name|
|`skeen tun list` - List all OpkgTun interfaces|

If access to Entware SSH is lost, run the following command in the Web CLI:

```sh
exec /opt/etc/init.d/S51dropbear start
```

### ⚙️ Settigs

> [!NOTE]
> After making changes to the file, a restart via `skeen restart` or through the menu is required

The file `/opt/etc/skeen/skeen.json` has the following settings:

```jsonc
{
  "auto_start": {      //// Automatic startup configuration for SKeen including Sing-box.
    "enabled": 1,      // SKeen autostart on router reboot (0 = disabled)
    "delay": 0         // Auto-start delay in seconds (default: 0)
  },
  "policy": {          //// Access policy configuration for the specified network segment.
    "enabled": 0,      // Enable routing based on segment policy (1 - enable, 0 - disable)
    "segment": "br1"   // Name of the segment interface (Bridge) whose policy will be used;
                       // starts with "br" followed by a number starting from 0.
                       // The number can be found in the URL under the "Segments" section,
                       // e.g., http://192.168.1.1/segments/Bridge1 corresponds to "br1".
                       // Alternatively, use the command: skeen iface
  },
  "network": {         //// Network configuration
    "ipv6": 1,         // Enable IPv6 support (0 = disabled)
    "tuning": 0,       // Enable sysctl network optimization (1 = on).
                       // If disabled, sysctl settings reset after reboot.
    "check": [
      "1.1.1.1",
      "77.88.8.8",
      "223.5.5.5"
    ]                  // Domains or IPs V4 for connectivity tests (max 3)
  },
  "singbox": {         //// Sing-box configuration
    "config": {        // + Configuration file
      "path": "",      // Absolute path or relative to the working directory /opt/etc/skeen
                       // to a local file or Sing-box configuration directory.
                       // By default, the file at /opt/etc/skeen/config.json is used.
      "url": "",       // URL (http:// or https://) for syncing configuration
                       // via `skeen sync` by default (optional)
      "split": 1       // If 1, the synced config via link (skeen sync) will be split
                       // into files named after the top-level Sing-box configuration keys.
                       // Available only if path points to a directory.
    },
    "api": {           // + sing-box API settings for commands via the intermediary layer (skeen api)
                       // sing-box version 1.14.beta.15 or higher is required
      "url": "",       // URL to the sing-box API service; default http://127.0.0.1:9999
      "secret": ""     // API secret key; specify this if it is set in the sing-box configuration.
    },
    "external": {      // + External Sing-box usage
      "enabled": 0,    // If set to 1, an external Sing-box binary is used;
                       // its installation, updates, and removal are managed manually.
      "path": "",      // Full path to binary (default: /opt/bin/sing-box).
      "config": {      // Configuration file for external Sing-box (optional)
        "path": "",    // Similar to the singbox.config object above;
        "url": "",     // its data will be used if left blank here.
        "split": 1
      },
      "api": {         // Parameters for accessing the sing-box API (optional)
        "url": "",     // Similar to the singbox.api object above,
        "secret": ""   // its data will be used if not specified here.
      }
    }
  },
  "services": {        //// Additional services configuration
    "proxy": {         // + Local proxy service for update and sync commands
      "enabled": 0,    // If set to 1, a local proxy (127.0.0.1) is used
      "port": "",      // Local proxy port (SOCKS5 or mixed)
      "user": "",      // Username for authentication (optional)
      "pass": ""       // Password for authentication (required if username is provided)
    }
  },
  "firewall": {        /// SKeen firewall configuration (iptables chains/rules)
    "intercept": {     // + Interception rules to the Sing-box core
      "dns": 1,        // Intercept DNS queries in TProxy/Hybrid modes (0 = disabled),
                       // ignored if redirect_dns is configured (see below)

      "fakeip": {      // Interception based on Sing-box FakeIP DNS
        "enabled": 0,  // If set to 1, includes the FakeIP pool in Redirect/TProxy interception;
                       // all other traffic goes directly, bypassing sing-box:
                       // - Requires firewall.intercept.dns or firewall.redirect_dns to be enabled,
                       //   along with sing-box DNS configuration.
                       // - The exclude.port/cidr exceptions will function as normal.
        "include": "", // Full path to the file containing a list of IP/CIDR resources (both v4 and v6):
                       // - Allows comments after #, empty lines, and leading/trailing whitespaces.
                       // - Intended for resources that initially didn't have a domain and therefore
                       //   didn't receive a FakeIP, but still need to be proxied.
                       // - Default value, if not specified, is /opt/etc/skeen/pure_cidr.list
        "clients": []  // Clients (IP addresses or CIDRs) that need FakeIP interception applied
                       // Example: [ "192.168.2.10", "192.168.2.11" ], if [] - all are used.
                       // For stable operation, a static IP address must be assigned to these clients;
                       // this is done in the Keenetic/Netcraze WebUI under the "Client Lists" tab
      }
    },
    "exclude": {       // + Exclude rules from Sing-box core interception
      "port": [
        "137:139",     // Ports excluded from Redirect/TProxy
        445, 1900      // (80 and 443 won't be added, exclude only the necessary system ones.)
      ],
      "ipv4_cidr": [], // Excluded IPv4 subnets from Redirect/TProxy
                       // Example: [ "192.87.1.0/24", "192.12.1.1" ]

      "ipv6_cidr": []  // Excluded IPv6 subnets from Redirect/TProxy
                       // Example: [ "2001:db8::/32", "2001:db8::1" ]
    },
    "redirect_dns": {  // + DNS query redirection (as an alternative to interception)
      "enabled": 0,    // Set to 1 to enable DNS redirection before system rules
      "to_port": "",   // The port to which DNS requests will be redirected
      "use_policy": 1  // Use defined policy if configured (0 = disabled)
    },
    "proxy_router": 0, // If set to 1, all router services will be proxied.
                       // Available in redirect, tproxy, and hybrid modes;
                       // subnet exclusions, as well as port bypass and interception rules, are respected.
  },
  "update": {          /// Update settings (skeen update)
    "singbox": {       // Sing-box updates (does not work with singbox.external.enabled=1)
      "enabled": 1,    // Enable Sing-box update check (0 = disabled)
      "beta": 0        // If set to 1, enables checking for pre-release versions (alpha, beta, rc)
    },
    "skeen": {
      "enabled": 1     // Enable SKeen update check (0 = disabled)
    }
  }
}

```

**Additional configuration notes:**

**`policy.segment`** - if you change the policy in the specified segment while SKeen is running, restart it to apply the changes. If the internet traffic rules are set to «Default policy» or «No internet access», SKeen will process traffic for the entire device.

**`network.ipv6`** - will not enable if the provider has not provided an IPv6 address for internet access.

**`network.tuning`** - when this option is enabled, the script applies a set of Linux kernel parameters (sysctl) adapted for the operation of high-performance proxy services (sing-box) on Keenetic routers.

<details>
  <summary>🔽 More details</summary>

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

</details>

To reset the settings to their defaults, simply set `network.tuning` to `0` and reboot your router.

**`network.check`** - specify only those IP addresses or domain names that are guaranteed to be reachable (pingable) in your network to ensure the script can verify the connection and start services successfully after a router reboot.

**`firewall.intercept.fakeip`** - this feature relies on the sing-box DNS module, meaning it must be engaged via `firewall.intercept.dns` or `firewall.redirect_dns` and configured correctly (see examples in the `examples` folder). Everything flagged as FakeIP will always be routed through sing-box via Redirect and/or TProxy, while everything else will bypass it at the Linux kernel level. This can be highly beneficial if you primarily use domestic services and want to offload your aging mips(el) router, as FakeIP is meant to be used mainly for the foreign segment.

<details>
  <summary>🔽 Advantages over GeoIP IPset Country-Based Filtering</summary>

* **Minimal RAM Consumption:** The `geoipset` method requires loading tens of thousands of Russian subnets into the router's RAM just to exclude them. FakeIP does not store massive IP address databases at all. It operates dynamically and "on the fly" within a single small local subnet, freeing up precious memory for system needs.

* **Low CPU Load (Crucial for mips/mipsel):** Instead of a heavy IP address lookup across the complex hash tables of a massive GeoIP database for *every single* network packet, the Linux kernel under FakeIP performs a single, instantaneous bitwise check: does the IP belong to the fake subnet (e.g., `198.18.0.0/15`). All direct IP-based connections (messengers, games, P2P) that didn't initiate a DNS request will, by default, immediately route directly, completely bypassing any CPU-heavy checks. Only resources that received a FakeIP via domain resolution, or specific IP/CIDR ranges you explicitly added to the `include` list, will hit the proxy. This maximizes CPU cycles, preventing internet speed drops and ping spikes under load.

* **Autonomy and Independence from Updates:** GeoIP databases constantly become outdated, causing websites to mistakenly route through the proxy (or vice versa). FakeIP operates on domains right here and now; it doesn't require regular updates since sing-box handles everything for you natively.

* **Precise Traffic Filtering:** The FakeIP method routes **only the specific target resources** from your sing-box DNS routing list into the proxy, saving both traffic and server resources.

* **Built-in DNS Leak Protection:** FakeIP is inherently tied to the sing-box DNS module, meaning flagged websites physically cannot expose your real IP address through a provider's DNS query.

* **Clean Architecture Without Third-Party Software:** To make GeoIP work alongside domains, alternative solutions require installing AdGuard Home or similar tools, linking them to ipset, and managing a mess of configuration files. Keep in mind that AdGuard Home is a heavyweight application that can rival the proxy core itself in terms of RAM usage and CPU load. Running such a "zoo" of services on a weak router makes little sense. In SKeen, the entire FakeIP functionality works right out of the box within a single compact sing-box binary, completely free of extra software or kludgy workarounds.
</details>

This is an excellent solution, but use it with the understanding that you will need to manually configure the list of IP addresses for services that use direct IP connections (do not have a domain) but still need to be proxied. Such services include:

* **Messenger IP pools** - many connections go directly to data centers via IP;
* **Discord voice channels** - WebRTC traffic often bypasses DNS;
* **P2P networks and torrent clients** - metadata downloads and seeding via trackers or direct peers;
* **Game launchers and online games** - the traffic of the game sessions themselves often goes to direct addresses, though there are exceptions;
* **IP pools of certain mobile apps** - addresses that are hardcoded into the application's source code.

The addresses of such connections can be analyzed beforehand (there is no point for P2P, etc.) in the web panel, under the “Connections” or “Sessions” tab (the “Host” column, target address) - the raw IP will be shown instead of a domain name. Next, find up-to-date lists of the required IP/CIDR ranges online and add them to the file at the path specified in the `firewall.intercept.fakeip.include` parameter (changes will take effect after restarting SKeen using the `skeen restart` command).

Is this solution right for you? Everyone decides for themselves based on current constraints and personal requirements for network performance and security.

**`firewall.proxy_router`** - Note that enabling this feature will force the use of sing-box DNS (if it is configured and enabled). Additionally, if you have not added the IP addresses or subnets (`ipv4_cidr` / `ipv6_cidr`) of your built-in router VPN servers to `firewall.exclude`, traffic to them will also route through sing-box, creating unnecessary overhead.

### 🔗 Useful links

- Sub-Store-GUI 🔥: [https://github.com/jinndi/sub-store-gui](https://github.com/jinndi/sub-store-gui)
- Sub-Store-Docker 🔥: [https://github.com/jinndi/Sub-Store-Docker](https://github.com/jinndi/Sub-Store-Docker)
- Plugin GUI.for.SingBox: [https://github.com/jinndi/sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen)
- Custom rulesets: [https://github.com/jinndi/singbox_ruleset](https://github.com/jinndi/singbox_ruleset)
- Karing ruleset: [https://github.com/KaringX/karing-ruleset/tree/sing](https://github.com/KaringX/karing-ruleset/tree/sing)
- Tutorial: [https://core-tutorial.argsment.com/singbox](https://core-tutorial.argsment.com/singbox)
- sing-box-lx core (XHTTP): [https://github.com/Leadaxe/sing-box-lx](https://github.com/Leadaxe/sing-box-lx)

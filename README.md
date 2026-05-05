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
<a href="https://github.com/jinndi/SKeen/releases/latest"><img alt="Downloads" src="https://img.shields.io/github/downloads/jinndi/SKeen/total?color=%23AAEEEE"></a>
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

The goto PREROUTING chain in the `nat` table is used under the name **skeen**:

It follows this rule order:

* **ACCEPT** - bypasses all router policies based on `fwmark`, except for those configured in skeen.json (optional).
* **ACCEPT** — bypasses ports specified in `skeen.json` if "selected ports mode" is disabled; otherwise, it filters traffic strictly for the specified ports.
* **ACCEPT** - bypasses local, reserved, and user-defined addresses.
* **REDIRECT** - redirects TCP traffic to the Sing-Box `redirect` port.

---

### TProxy - utilized in `tproxy` (TCP & UDP) and `hybrid` (UDP) modes, as well as for router-level proxying

The goto PREROUTING chain in the `mangle` table is used under the name **skeen**:

It follows this rule order:

* **ACCEPT** - bypasses all router policies based on `fwmark`, except for those configured in skeen.json (optional).
* **TPROXY DNS** - redirects TCP/UDP port 53 traffic to the Sing-Box TProxy port (optional, otherwise - ACCEPT).
* **ACCEPT** — bypasses ports specified in `skeen.json` if "selected ports mode" is disabled; otherwise, it filters traffic strictly for the specified ports.
* **ACCEPT** - bypasses local, reserved, and user-defined addresses.
* **TCP MARK + ACCEPT SOCKET** - a "fast path" for already established transparent sockets (socket transparent).
* **TPROXY** - directs the remaining TCP/UDP traffic to the Sing-Box TProxy port.

> **Note:** Local subnets (listed in the source code) are already excluded from proxying. However, if you need to exclude specific ports, you must specify them manually in `skeen.json` or within the `sing-box` configuration itself.

---

### Hybrid - utilizes combined rules for router proxying: `redirect` (TCP) and `tproxy` (UDP).

---

### Router Proxying. `OUTPUT` chains named **skeen_mask**

Depending on the firewall mode and router proxying settings (on/off), chains are created in both `nat` and `mangle` tables attached to the `OUTPUT` chain respectively.

Instead of filtering by router policies, it filters processes that do not belong to the `skeen` group (to prevent routing loops). The rules are applied in the following order:

1. `redirect` mode, `nat` table in `OUTPUT` named `skeen_mask`: mirrors the logic of the Redirect **skeen** chain.
2. `tproxy` mode, `mangle` table in `OUTPUT` chain named `skeen_mask`: Similar to the TProxy chain rules, with the exception of the absence of DNS redirection and rules for direct traffic routing to Sing-Box. Instead, it concludes with:

* **ACCEPT 53 PORT** - to prevent subsequent rules from executing, only if the `redirect_dns` function is enabled in the SKeen configuration.
* **MARK** - marks local outgoing traffic, which then enters `PREROUTING` where it is processed based on this mark. If policy-based routing is enabled in the SKeen config, it is processed via the **skeen** chain (added as a second instance after the main client chain), or simply directed to the client chain if proxying is configured without policies.
* **CONNMARK save** - saves the mark to the entire connection (conntrack) for firewall "memory."

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

### 🚀 Features
- TProxy/Redirect/Hybrid modes ✓
- IPv4 and IPv6 supports ✓
- Sing-box DNS module working ✓
- Sing-box fakeip working ✓
- Zashboard via Clash API configured ✓
- Network settings optimization ✓
- Commands working via the router's Web CLI ✓

### 📋 Requirements
- Entware installed and configured on **non-internal memory**
- Netfilter Subsystem Kernel Module installed
- `curl` installed via `opkg install curl`
- Recommended: at least 256 MB of RAM and an ARM processor to unlock full potential

### 💾 Installation

**Run from Entware via SSH:**

```
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen | sh
```

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
│   └── skeen-box          # sing-box binary
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

| OpkgTun manager (KeeneticOS v5+, only from SSH) |
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
      "port": []       // Ports to intercept (all if empty).
                       // Example: [ 80, 443, "1000:2000", "1500:5555" ]
    },
    "exclude": {
      "port": [
        "137:139",     // Ports excluded from redirect
        445, 1900      // (ignored if `intercept.port` is set)
      ],
      "ipv4_cidr": [], // Excluded IPv4 subnets for redirection.
                       // Example: [ "192.87.1.0/24", "192.12.1.1" ]
      "ipv6_cidr": []  // Excluded IPv6 subnets for redirection.
                       // Example: [ "2001:db8::/32", "2001:db8::1" ]
    },
    "redirect_dns": {
      "enable": 0,     // Set to 1 to enable DNS redirection before system rules
      "to_port": "",   // The port to which DNS requests will be redirected
      "use_policy": 1  // Use defined policy if configured (0 = disabled)
    },
    "proxy_router": 0  // If set to 1, all router services will be proxied.
                       // Available in redirect, tproxy, and hybrid modes;
                       // subnet exclusions, as well as port bypass and interception rules, are respected.
  }
}

```

### 🔗 Useful links
- Sync plugin: [https://github.com/jinndi/sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen)
- Sing-box schema: [https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002](https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002)
- Proxy setup guide: [https://proxy-tutorials.dustinwin.us.kg](https://proxy-tutorials.dustinwin.us.kg)
- Outbound server block generator: [https://4n0nymou3.github.io/proxy-to-singbox-converter/](https://4n0nymou3.github.io/proxy-to-singbox-converter/)
- Karing ruleset: [https://github.com/KaringX/karing-ruleset/tree/sing](https://github.com/KaringX/karing-ruleset/tree/sing)

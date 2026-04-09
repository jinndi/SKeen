<p align="center">
  <img alt="SKeen" src="/logo.webp" width="214">
</p>
<h1 align="center">
  SKeen
</h1>
<h3 align="center">
Keenetic/Netcraze TProxy & Redirect with sing-box + Firewall-only mode
</h3>

<p align="center">
<a href="https://github.com/jinndi/SKeen"><img alt="SKeen" src="https://img.shields.io/github/v/release/jinndi/SKeen"></a>
<a href="https://github.com/SagerNet/sing-box"><img alt="sing-box" src="https://repology.org/badge/version-for-repo/homebrew/sing-box.svg?header=sing-box-latest-version"></a>
<img alt="Code size in bytes" src="https://img.shields.io/github/languages/code-size/jinndi/SKeen">
<img alt="Visitor" src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fjinndi%2FXSKeen&label=visitor&icon=eye&color=%230d6efd&message=&style=flat&tz=UTC">
<a href="https://deepwiki.com/jinndi/SKeen"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
</p>

🇺🇸 **English** | [🇷🇺 На русском](README-RU.md)

### 🌟 Why sing-box?

**sing-box** is an open-source universal proxy engine written in Go. It is focused on maximum performance, low resource consumption, and support for the most modern protocols

**Comparison: Proxy Engines for Routers & Embedded**

|Feature                 |sing-box         |Xray              |mihomo          |
|------------------------|-----------------|------------------|----------------|
|Resource Usage (RAM/CPU)|✅ Minimal        |⚠️ Moderate       |❌ High          |
|Protocol Support        |✅ Advanced       |⚠️ Limited        |✅ Extensive     |
|Multiplexing            |✅ Superior       |⚠️ Legacy         |✅ Good          |
|DNS Logic               |🥇 Native (+Fake-IP)|🥉 Sniffing (+FakeDNS)|🥈 Fake-IP (+Real)|
|Routing                 |✅ Flexible       |⚠️ Basic          |✅ (but heavier) |
|Rule Management         |✅ Rule-sets (bin)|⚠️ Geo-files (dat)|✅ Rule-providers|
|Independent Project     |✅ Yes            |❌ (V2Ray fork)    |❌ (Clash fork)  |
|Learning Curve          |🔴 High          |🟡 Moderate       |🟢 Low          |

Notes:

> sing-box excels due to its modularity and clean-slate architecture: its DNS stack enables complex configurations with minimal RAM overhead. In contrast, mihomo (Clash) prioritizes automation at the cost of high resource usage, while Xray is hindered by legacy networking code and heavy .dat geo-files.

> The high learning curve of sing-box stems from its strict JSON schema and lack of "magic" defaults. This is a trade-off for granular control and peak performance on low-end hardware.

### ❌ No Web UI

Doesn’t include a separate configuration Web UI. The built-in **Zashboard** interface is already used for management, making additional UIs unnecessary.

💡 To simplify configuration, a [sync plugin](https://github.com/jinndi/sync-profile-to-skeen) is available to import profiles via [GUI.for.SingBox](https://github.com/jinndi/sync-profile-to-skeen)

### 🚀 Features
- TProxy/Redirect/Hybrid modes ✓
- IPv4 and IPv6 supports ✓
- Sing-box DNS module working ✓
- Sing-box fakeip working ✓
- Zashboard via Clash API configured ✓
- Network settings optimization ✓
- Firewall-only mode ✓
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

Before installation begins, you will be prompted to choose whether to install in full mode with sing-box, or to use it only as a firewall.

After installation, if full mode was selected, configure the sing-box JSON configuration files located in the `/opt/etc/skeen/config/` directory, where example configuration files are provided.

The SKeen settings are located in the file at `/opt/etc/skeen/skeen.json`.

`/opt/etc/skeen` directory is not removed during program uninstallation and must be deleted manually if required. It is also not overwritten during reinstallation if it already exists.

Also, if the full installation was selected, the Zashboard panel is configured by default via the Clash API and can be accessed through the router’s IP address (usually 192.168.1.1) at `http://192.168.1.1:9090`

Manage the package further using the `skeen` command.

After successful installation:

```
/opt/
├── bin/
│   ├── skeen              # SKeen management script
│   └── skeen-box          # sing-box binary (with a full installation)
├── etc/
│   ├── init.d/
│   │   └── S99SKeen       # Autostart script
│   ├── ndm/
│   │   └── netfilter.d/
│   │       └── skeen_firewall.sh  # Created on start
│   └── skeen/
│       ├── skeen.json     # SKeen configuration
│       └── config/        # sing-box config dir (with a full installation)
│           ├── log.json
│           ├── dns.json
│           ├── inbounds.json
│           ├── outbounds.json
│           ├── route.json
│           └── experimental.json
└── tmp/
    └── (temporary download files)
```

### ⚡ Commands

Example Usage from SSH: start the daemon `skeen start`

When using the router’s Web CLI, add `exec` before the command. For example: `exec skeen reload`

> The output in the WEB CLI is limited to 8 lines and a certain execution time, but this does not affect the correct execution of commands

`skeen` without parameters launches the management menu from SSH, use `help` for help

| Command | Description | WEB CLI support |  FW Only support |
| :--- | --- | :---: | :---: |
|`start`|Starts Sing-box. Checks configuration and will not start again if the process is already running|✓|✓|
|`stop`|Stops Sing-box. If the process is not found, reports that the daemon is already stopped|✓|✓|
|`restart`|Stops and then starts Sing-box again|✓|✓|
|`reload`|Reload sing-box (full restart, not a hot reload) without touching firewall rules|✓|✓|
|`kill`|Forcefully terminates the Sing-box process (`kill -9`)|✓|-|
|`status`|Shows the current status of the process Sing-box|✓|✓|
|`version`|Displays the current application version|✓|✓|
|`update`|Checks for available updates of the sing-box core and the SKeen script, and allows updating|-|✓|
|`test`|Check whether iptables rules are correctly applied for the current operating mode (requires Sing-box to be running and the mode to be anything except none)|✓|✓|
|`deps`|Check if all dependencies are installed (installs missing ones)|✓|✓|
|`check`| Checks current Sing-box configuration (if working without `firewall.only`) for syntax and logical errors + `skeen.json` for JSON validity |✓|✓|
|`format`| Formats current Sing-box configuration without changing its behavior |✓|-|
|`backup`|Creates a backup (archive) of the `/opt/etc/skeen` directory and places it in the `/opt` root|✓|✓|
|`backups`|Show all created backup copies in the /opt folder|✓|✓|
|`restore`¹|Restores a backup of the `/opt/etc/skeen` directory by archive name from the `/opt` directory|✓|✓|
|`reset`|Resets `/opt/etc/skeen` directory to its default state after performing a `backup` beforehand|-|✓|
|`sync`²|Synchronizes the sing-box configuration (or another one in `firewall.only` mode) to the location specified in the `sing_config` section of the `skeen.json` configuration file|✓|✓|

1 - archive name can be passed as the second parameter with a .tar extension to immediately start the backup restore process

2 - accepts the Sing-box JSON configuration URL (or another one in `firewall.only` mode) as the second parameter (HTTP or HTTPS); optional if the address is set in `sing_config.sync_url`

| OpkgTun manager (KeeneticOS v5+, only from SSH) |
| -------------------------------------------------------------------------- |
|`skeen tun create <ipv4> <name>` - Create interface with the specified IP and name|
|`skeen tun delete <name>` - Delete interface with the specified name|
|`skeen tun list` - Shows all OpkgTun interfaces in the system|


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
    "only": {
      "enable": 0,         // Enable Firewall-only mode (1 = on)
      "process_name": "",  // Name process or path to binary with ports listening for TProxy/Redirect
      "redirect_port": "", // Redirect port for TCP traffic
      "tproxy_port": "",   // TProxy port for redirecting UDP traffic if 'redirect_port' is set,
                           // otherwise both TCP and UDP traffic will go entirely through TProxy
      "opkgtun_use": 0     // Whether opkgtun configuration is used (1 = on)
    },
    "intercept": {
      "dns": 1,        // Intercept DNS req. via TProxy/Hybrid modes (0 = disabled)
      "port": []       // Ports to intercept (all if empty).
                       // Example: [ 80, 443, "1000:2000", "1500:5555" ]
    },
    "exclude": {
      "port": [
        123, 137,
        138, 139,
        445            // Ports excluded from redirect
                       // (ignored if `intercept.port` is set)
      ],
      "ipv4_cidr": [], // Excluded IPv4 subnets for redirection.
                       // Example: [ "192.87.1.0/24", "192.12.1.1" ]
      "ipv6_cidr": []  // Excluded IPv6 subnets for redirection.
                       // Example: [ "2001:db8::/32", "2001:db8::1" ]
    }
  }
}

```

### 🔗 Useful links
- Sync plugin: [https://github.com/jinndi/sync-profile-to-skeen](https://github.com/jinndi/sync-profile-to-skeen)
- Sing-box schema: [https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002](https://gist.github.com/artiga033/fea992d95ad44dc8d024b229223b1002)
- Proxy setup guide: [https://proxy-tutorials.dustinwin.us.kg](https://proxy-tutorials.dustinwin.us.kg)
- Outbound server block generator: [https://4n0nymou3.github.io/proxy-to-singbox-converter/](https://4n0nymou3.github.io/proxy-to-singbox-converter/)
- Karing ruleset: [https://github.com/KaringX/karing-ruleset/tree/sing](https://github.com/KaringX/karing-ruleset/tree/sing)

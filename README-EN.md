<p align="center">
  <img src="/logo.png" alt="SKeen" width="512" style="max-width: 100%; height: auto; display: block; margin: 0 auto; padding: 20px 0;" />
</p>
<h1 align="center">SKeen</h1>
<h3 align="center">Lightweight transparent proxy for Keenetic/Netcraze powered by sing-box</h3>

<p align="center">
<a href="https://github.com/jinndi/SKeen/releases/latest"><img alt="SKeen" src="https://img.shields.io/github/v/release/jinndi/SKeen"></a>
<a href="https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/jinndi/SKeen"></a>
<a href="https://github.com/SagerNet/sing-box"><img alt="sing-box" src="https://repology.org/badge/version-for-repo/homebrew/sing-box.svg?header=sing-box-latest-version"></a>
<a href="https://deepwiki.com/jinndi/SKeen"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
</p>

🇺🇸 **English** | [🇷🇺 На русском](README.md)

SKeen configures transparent proxying on Keenetic and Netcraze routers using sing-box. It manages firewall rules, service lifecycle and configuration synchronization.

<details>
  <summary>Why sing-box?</summary>
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
  <summary>Web UI?</summary>
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
  <summary>Architecture?</summary>
<br>

The same architecture description is available as a standalone document: [Architecture](docs/ARCHITECTURE.md).

</details>

<details>
  <summary>FakeIP?</summary>
<br>

The complete FAQ is available in [docs/FAQ.md](docs/FAQ.md).

</details>

## Features

- TProxy, Redirect, Hybrid, Tun and DNS modes
- IPv4 and IPv6 support
- Working sing-box DNS module
- Working sing-box FakeIP
- FakeIP proxying at iptables level
- Configured Web UI via built-in API
- Network settings optimization
- Commands working via router's Web CLI
- Switch between official and third-party sing-box
- Sing-box config sync via HTTP(S) link
- Sub-Store usage examples for synchronization
- Ready-to-use sing-box config templates
- Optional proxying for the router itself
- No access token required for RCI requests

## Requirements

- Entware installed and configured.
- Netfilter Subsystem Kernel Module installed.
- `curl` installed via `opkg install curl`.
- Recommended: at least 256 MB of RAM and an ARM processor to unlock full potential.

## Installation

Make sure that Entware is installed. Otherwise, find the instructions for your model in the [Support Center](https://support.keenetic.com/) → User Guide → Management → OPKG → Installing the Entware repository on a USB drive / Installing OPKG Entware on internal router memory.

**Run from Entware via SSH:**

```sh
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen --resolve release-assets.githubusercontent.com:443:185.199.108.133 | sh
```

Russian-localized version: See [README-RU.md](README-RU.md)

<details>
  <summary>Installation failed? (click to expand)</summary>
<br>

See the <a href="docs/TROUBLESHOOTING.md">troubleshooting guide</a>.

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
/opt/
├── bin/
│   ├── skeen                  # Main SKeen management script
│   └── skeen-box              # sing-box binary (if installation selected)
├── etc/
│   ├── init.d/
│   │   └── S99SKeen           # System startup / autostart script
│   ├── ndm/netfilter.d/
│   │   └── skeen_firewall.sh  # Firewall rules (generated on startup)
│   └── skeen/
│       ├── skeen.json         # SKeen configuration
│       └── config.json        # sing-box configuration
└── tmp/                       # Temporary download files

/tmp/ (RAM Disk) - synced into memory:
├── skeen.sh                   # Script copy - updated after start/reboot
├── skeen.json                 # Config cache - synced on source changes
├── skeen_singbox_version      # sing-box version cache - updated on binary change
└── run/
    └── skeen.pid              # PID file of the sing-box process
```

## Commands

Example Usage from SSH: start the daemon `skeen start`

When using the router’s Web CLI, add `exec` before the command. For example: `exec skeen reload`

> The output in the Web CLI is limited to 8 lines and a certain execution time, but this does not affect the correct execution of commands.

`skeen` without parameters launches the management menu from SSH, use `skeen help` for help

| Command | Description | Web CLI |
| :--- | :--- | :---: |
| `start` | Start service | ✓ |
| `stop` | Stop service | ✓ |
| `restart` | Full restart | ✓ |
| `reload` | Reload sing-box only | ✓ |
| `kill` | Force stop | ✓ |
| `status` | Show status | ✓ |
| `version` | Show version | ✓ |
| `help` | Help about any command | - |
| `iface` | Show network interface table | - |
| `update` | Check and install updates | - |
| `test` | Test firewall rules | ✓ |
| `deps` | Check dependencies | ✓ |
| `check` | Check configuration | ✓ |
| `format` | Format sing-box configuration | ✓ |
| `api` | sing-box API management commands | - |
| `backup` | Create archive of `/opt/etc/skeen` | ✓ |
| `backups` | List created archives in `/opt` | ✓ |
| `restore`¹ | Restore `/opt/etc/skeen` from archive in `/opt` | ✓ |
| `reset` | Reset `/opt/etc/skeen` to default | - |
| `clean`² | Clear sing-box cache file | ✓ |
| `sync`³ | Synchronize sing-box configuration | ✓ |
| `headers` | Generate fake client headers for subscriptions | - |

1 - archive name can be passed as the second parameter with a `.tar` extension to immediately start the backup restore process

2 - clears the cache file. This is required when using the `experimental.cache_file` feature in sing-box, for example, to reset the cache of loaded rule_set and DNS query history.

3 - accepts the sing-box JSON configuration URL as the second parameter (HTTP or HTTPS); optional if the address is set in `singbox.config.url`

| OpkgTun manager (KeeneticOS v5+, only from SSH) |
| -------------------------------------------------------------------------- |
|`skeen tun create <ipv4> <name>` - Create interface with IP address and name|
|`skeen tun delete <name>` - Delete interface by name|
|`skeen tun list` - List all OpkgTun interfaces|


## Settings

The full configuration reference is available in [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

## Useful links

**Sync and GUI**
- [Sub-Store Desktop](https://github.com/jinndi/sub-store-gui) — desktop subscription manager.
- [Sub-Store Android](https://github.com/sionnx/SubCase) — Android app for managing subscriptions.
- [Sub-Store Docker](https://github.com/jinndi/Sub-Store-Docker) — Docker deployment for VPS and servers.
- [GUI.for.SingBox sync plugin](https://github.com/jinndi/sync-profile-to-skeen) — plugin for importing profiles into SKeen.

**Rulesets**
- [Karing ruleset](https://github.com/KaringX/karing-ruleset/tree/sing) — rule sets for sing-box.
- [Custom sing-box rulesets](https://github.com/jinndi/singbox_ruleset) — custom rule sets.

**Documentation and references**
- [core-tutorial.argsment.com](https://core-tutorial.argsment.com/singbox) — sing-box reference guide.
- [sing-box-lx core (XHTTP)](https://github.com/Leadaxe/sing-box-lx) — alternative XHTTP-capable core.

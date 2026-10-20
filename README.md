<p align="center">
  <img src="/assets/logo.png" alt="SKeen" width="512" style="max-width: 100%; height: auto; display: block; margin: 0 auto; padding: 20px 0;" />
</p>

<h1 align="center">SKeen</h1>

> Lightweight transparent proxy for Keenetic/Netcraze routers, powered by sing-box.

[![Build](https://github.com/jinndi/SKeen/actions/workflows/release.yml/badge.svg)](https://github.com/jinndi/SKeen/actions/workflows/release.yml) [![SKeen](https://img.shields.io/github/v/release/jinndi/SKeen)](https://github.com/jinndi/SKeen/releases/latest) [![License](https://img.shields.io/github/license/jinndi/SKeen)](https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/main/LICENSE) [![sing-box-latest](https://img.shields.io/github/v/release/SagerNet/sing-box?label=sing-box-latest&display_name=tag)](https://github.com/SagerNet/sing-box/releases/latest) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/jinndi/SKeen)

🇺🇸 **English** | [🇷🇺 На русском](./README-RU.md) | [🧩 FAQ](docs/FAQ.md)

SKeen configures transparent proxying on Keenetic and Netcraze routers using sing-box. It manages firewall rules, service lifecycle and configuration synchronization.

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

> [!TIP]
> Nothing gets installed **at all**?
>
> Try the [offline Entware installer with SKeen preinstalled](https://github.com/jinndi/SKeen/tree/static/entware).

**Run the following command via SSH from the Entware environment:**

```sh
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen --resolve release-assets.githubusercontent.com:443:185.199.108.133 | sh
```

Russian-localized version: See [README-RU.md](README-RU.md)

<details>
  <summary>Still can't install it? (click to expand)</summary>
<br>

1. [Try the offline Entware installer with SKeen preinstalled](https://github.com/jinndi/SKeen/tree/static/entware).
2. See also the [troubleshooting guide](docs/TROUBLESHOOTING.md).

</details>

> [!NOTE]
> You will be prompted to install `sing-box` from the official repository (either the stable or beta version). You can also skip the installation to configure a custom binary file later in `skeen.json`.

**Configure the following:**

1. SKeen in [`/opt/etc/skeen/skeen.json`](./docs/CONFIGURATION.md).
2. sing-box in [`/opt/etc/skeen/config.json`](./examples/configs/stable/config-commented.jsonc).
3. The web dashboard at `http://192.168.1.1:9999`. By default, it is available at the router's IP address (typically `192.168.1.1`).

**Important:**

The `/opt/etc/skeen` directory is preserved when the program is uninstalled and is not overwritten during reinstallation if it already exists. Delete it manually if necessary.

Manage SKeen using the `skeen` command.

**File and directory structure after successful installation:**

```
/opt/
├── bin/
│   ├── skeen                  # Main SKeen management script
│   └── skeen-box              # sing-box binary (if installation selected)
│
├── etc/
│   ├── init.d/
│   │   └── S99SKeen           # System startup / autostart script
│   ├── ndm/netfilter.d/
│   │   └── skeen_firewall.sh  # Firewall rules (generated on startup)
│   └── skeen/
│       ├── skeen.json         # SKeen configuration
│       ├── config.json        # sing-box configuration
│       └── ruleset/           # Folder with .srs files for the initial start
│
└── tmp/                       # Temporary download files

/tmp/  (RAM Disk) - synced into memory:
├── .skeen/
│   ├── skeen.sh               # Script copy - updated after start/reboot
│   ├── skeen.json             # Config cache - synced on source changes
│   └── version                # sing-box version cache - updated on binary change
└── run/
    └── skeen.pid              # PID file of the sing-box process
```

### Web Panels for Local Network

The following domains are pre-configured in the base `config.json` template for accessing the panels from the router's local network:

| Dashboard URL | Used API | Panel Connection Address | Brief Description |
| :--- | :--- | :--- | :--- |
| **[sing-box-dashboard.sagernet.org](https://sing-box-dashboard.sagernet.org)** *(in Chrome)*<br>[HTTP version](http://sing-box-dashboard.sagernet.org) *(others)* | Native `sing-box` API (`9999`) | `http://192.168.1.1:9999` | Built-in `sing-box` web dashboard (files are stored locally on the router). |
| **[sdash.u1.pw](https://sdash.u1.pw)** *(in Chrome)*<br>[HTTP version](http://sdash.u1.pw) *(others)* | Native `sing-box` API (`9999`) | `http://192.168.1.1:9999` | Very lightweight web interface for `sing-box` management. |
| **[board.zash.run.place](https://board.zash.run.place)** *(in Chrome)*<br>[HTTP version](http://board.zash.run.place) *(others)* | Clash API (`9090`) | `http://192.168.1.1:9090` | Remote **Zashboard** frontend for managing proxy connections. |
| **[d.metacubex.one](https://d.metacubex.one)** / **[metacubexd.pages.dev](https://metacubexd.pages.dev)** *(Chrome only)* | Clash API (`9090`) | `http://192.168.1.1:9090` | Alternative **MetacubexD** (Yacd-meta) web interface for Clash API. |


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
| `connstat` | Connection diagnostics | - |
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

**OpkgTun manager (KeeneticOS v5+, only from SSH)**

| Command | Description |
| :--- | :--- |
| `skeen tun create <ipv4> <name>` | Create interface with IP address and name |
| `skeen tun delete <name>` | Delete interface by name |
| `skeen tun list` | List all OpkgTun interfaces |


## Settings

The full configuration reference is available in [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

## Useful links

**Sync and GUI**
- [Sub-Store Docker](https://github.com/jinndi/Sub-Store-Docker) — Docker build for VPS or local deployment.
- [Sub-Store Desktop](https://github.com/jinndi/sub-store-gui) — desktop subscription manager.
- [Sub-Store Android](https://github.com/sionnx/SubCase) — Android app for managing subscriptions.
- [GUI.for.SingBox sync plugin](https://github.com/jinndi/sync-profile-to-skeen) — plugin for importing profiles into SKeen.

**Rulesets**
- [Karing ruleset](https://github.com/KaringX/karing-ruleset/tree/sing) — rule sets for sing-box.
- [Custom sing-box rulesets](https://github.com/jinndi/singbox_ruleset) — custom rule sets.

**Other**
- [core-tutorial.argsment.com](https://core-tutorial.argsment.com/singbox) — sing-box reference guide.
- [An In-Depth Look at Modern sing-box 1.14](https://www.qichiyu.com/1111.html) — for Chinese speakers.
- [Complete Sub-Store Guide](https://www.qichiyu.com/1119.html) — for Chinese speakers.
- [jinndi/skeen-box](https://github.com/jinndi/skeen-box) — sing-box builds with REALITY patch and UPX compression.
- [sing-box-lx core (XHTTP)](https://github.com/Leadaxe/sing-box-lx) — alternative core with XHTTP.

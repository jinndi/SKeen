<p align="center">
  <img alt="SKeen" src="/logo.webp" width="214">
</p>
<h1 align="center">
  SKeen
</h1>
<h3 align="center">
Installation script for sing-box on Keenetic/Netcraze routers
</h3>

<p align="center">
<img alt="SKeen" src="https://img.shields.io/github/v/release/jinndi/SKeen">
<img alt="sing-box" src="https://repology.org/badge/version-for-repo/homebrew/sing-box.svg?header=sing-box-latest-version">
<img alt="Code size in bytes" src="https://img.shields.io/github/languages/code-size/jinndi/SKeen">
<img alt="License" src="https://img.shields.io/github/license/jinndi/SKeen">
<img alt="Visitor" src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fjinndi%2FXSKeen&label=visitor&icon=eye&color=%230d6efd&message=&style=flat&tz=UTC">
<a href="https://deepwiki.com/jinndi/SKeen"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
</p>

> [!WARNING]
> Tested on the aarch64 (arm64) CPU architecture. Please report any issues.

### 🚀 Features
- TProxy/Redirect/Hybrid modes ✓
- IPv4 and IPv6 supports ✓
- Sing-box DNS module working ✓
- Sing-box fakeip working ✓
- Zashboard via Clash API configured ✓
- Network settings optimization ✓

### 📋 Requirements
- Entware installed and configured
- Netfilter Subsystem Kernel Module installed
- `curl` installed via `opkg install curl`

### 💾 Installation

**Run from Entware via SSH:**

```
curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen | sh
```

Configure the sing-box JSON configuration files located in the `/opt/etc/skeen/config/` directory, where example configuration files are provided.

The SKeen settings are located in the file at `/opt/etc/skeen/skeen.conf`.

`/opt/etc/skeen` directory is not removed during program uninstallation and must be deleted manually if required. It is also not overwritten during reinstallation if it already exists.

Access the web interface at the router's IP (usually 192.168.1.1) on http://192.168.1.1:9090

Manage the package further using the `skeen` command.

After successful installation:

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
│       ├── skeen.conf     # SKeen configuration
│       └── config/
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

Example Usage: start the daemon `skeen start`
(`skeen` without parameters launches the management menu, use `help` for help)

| Command | Description |
| ------------ | -------------------------------------------------------------- |
|`start`|Starts Sing-box. Checks configuration and will not start again if the process is already running|
|`stop`|Stops Sing-box. If the process is not found, reports that the daemon is already stopped|
|`restart`|Stops and then starts Sing-box again|
|`reload`|Reload sing-box (full restart, not a hot reload) without touching firewall rules|
|`kill`|Forcefully terminates the Sing-box process (`kill -9`)|
|`status`|Shows the current status of the process Sing-box|
|`version`|Displays the current application version|
|`update`|Checks for available updates of the sing-box core and the SKeen script, and allows updating|
|`test`|Check whether iptables rules are correctly applied for the current operating mode (requires Sing-box to be running and the mode to be anything except none)|
|`deps`|Check if all dependencies are installed (installs missing ones)|
|`check`| Checks Sing-box configuration in `/opt/etc/skeen/config/` for syntax and logical errors + `/opt/etc/skeen/skeen.json` for syntax error |
|`format`| Formats Sing-box configuration in `/opt/etc/skeen/config/` without changing its behavior |
|`backup`|Creates a backup (archive) of the `/opt/etc/skeen` directory and places it in the `/opt` root|
|`restore`|Restores a backup of the `/opt/etc/skeen` directory by archive name from the `/opt` directory|
|`reset`|Resets `/opt/etc/skeen/config/` and `/opt/etc/skeen/skeen.conf` to defaults, performing a `backup` beforehand|

### ⚙️ Settigs

> [!NOTE]
> After making changes to the file, a restart via `skeen restart` or through the menu is required

The file `/opt/etc/skeen/skeen.json` has the following settings:

```
{
  "auto_start": {
    "enable": 1,    // SKeen autostart on router reboot (0 = disabled)
    "delay": 0      // Auto-start delay in seconds (default: 0)
  },
  "policy": {
    "enable": 1,    // Enable policy-based routing (0 = disabled)
    "name": "SKeen" // Router policy name (default: "SKeen")
  },
  "network": {
    "ipv6": 1,      // Enable IPv6 support (0 = disabled)
    "tuning": 0,    // Enable sysctl network optimization (1 = on).
                    // If disabled, sysctl settings reset after reboot.
    "check": [
      "1.1.1.1",
      "77.88.8.8",
      "223.5.5.5"
    ]               // Domains or IPs for connectivity tests (max 3)
  },
  "firewall": {
    "intercept": {
      "dns": 1,     // Intercept DNS via TProxy/Redirect (0 = disabled)
      "port": []    // Ports to intercept (all if empty).
                    // Example: [ 80, 443, "1000:2000", "1500:5555" ]
    },
    "exclude": {
      "port": [
        123, 137,
        138, 139,
        445         // Ports excluded from redirect
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
- Proxy setup guide: [https://proxy-tutorials.dustinwin.us.kg/](https://proxy-tutorials.dustinwin.us.kg/)
- Outbound server block generator: [https://4n0nymou3.github.io/proxy-to-singbox-converter/](https://4n0nymou3.github.io/proxy-to-singbox-converter/)

<p align="center">
  <img alt="SKeen" src="/logo.webp" width="300">
</p>
<h1 align="center">
  SKeen
</h1>
<h3 align="center">
Installation script for sing-box on Keenetic/Netcraze routers
</h3>

<p align="center">
<img alt="Release" src="https://img.shields.io/github/v/release/jinndi/SKeen">
<img alt="Code size in bytes" src="https://img.shields.io/github/languages/code-size/jinndi/SKeen">
<img alt="License" src="https://img.shields.io/github/license/jinndi/SKeen">
<img alt="Visitor" src="https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fjinndi%2FXSKeen&label=visitor&icon=eye&color=%230d6efd&message=&style=flat&tz=UTC">
</p>

> [!WARNING]
> Tested on the aarch64 (arm64) CPU architecture. Please report any issues.

### 🚀 Features
- TProxy/Redirect/Hybrid modes ✓
- IPv4 and IPv6 supports ✓
- Sing-box DNS module working ✓
- Sing-box fakeip working ✓
- Zashboard via Clash API configured ✓

### 📋 Requirements
- Entware installed and configured
- Netfilter Subsystem Kernel Module installed
- `curl` installed via `opkg install curl`

### 💾 Installation

**Run from Entware via SSH:**

```
curl -Ls https://raw.githubusercontent.com/jinndi/SKeen/main/install.sh | sh
```

Configure the sing-box JSON configuration files located in the `/opt/etc/skeen/config/` directory, where example configuration files are provided.

The SKeen settings are located in the file at `/opt/etc/skeen/skeen.conf`.

`/opt/etc/skeen` directory is not removed during program uninstallation and must be deleted manually if required. It is also not overwritten during reinstallation if it already exists.

Access the web interface at the router's IP (usually 192.168.1.1) on http://192.168.1.1:9090

Manage the package further using the `skeen` command.

### ⚡ Commands

Example Usage: start the daemon `skeen start`
(`skeen` without parameters launches the management menu)

| Command | Description |
| ------------ | -------------------------------------------------------------- |
|`start`|Starts Sing-box. Checks configuration and will not start again if the process is already running|
|`stop`|Stops Sing-box. If the process is not found, reports that the daemon is already stopped|
|`restart`|Stops and then starts Sing-box again|
|`status`|Shows the current status of the process|
|`kill`|Forcefully terminates the Sing-box process (`kill -9`)|
|`version`|Displays the current application version|

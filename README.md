<p align="center">
  <img alt="SKeen" src="/logo.webp" width="280">
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
- Installing the latest version of sing-box on Keenetic/Netcraze routers
- Detecting CPU architecture and type to select the appropriate sing-box IPK package
- Creating and configuring a proxy interface for sing-box inbound
- Start/stop/restart/update/uninstall options from the script menu
- Pre-configured Zashboard web panel via Clash API

### 📋 Requirements
- CPU types: aarch64, mipsel, mips
- Entware installed and configured on the router
- `curl` installed via `opkg install curl`
- **Proxy Client** component is installed on the router
- GitHub connection is available (for installation and updates)

### 💾 Installation

**Run from Entware via SSH:**

```
curl -Ls https://raw.githubusercontent.com/jinndi/SKeen/main/install.sh | sh
```
Manage the package further using the `skeen` command.

Configure the sing-box JSON configuration files located in the `/opt/etc/skeen/config/` directory, where example configuration files are provided.
The directory is not removed during program uninstallation and must be deleted manually if required.
It is also not overwritten during reinstallation if it already exists.

Access the web interface at the router's IP (usually 192.168.1.1) on port `9090`

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
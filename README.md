<p align="center">
  <img alt="SKeen" src="/logo.webp" width="180">
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
- CPU types: aarch64 (arm64), mipsel (little-endian), mips (big-endian)
- Entware installed and configured on the router
- `curl` and `tar` packages installed via `opkg install`
- **Proxy Client** component is installed on the router
- Other sing-box packages removed beforehand

### 💾 Installation

**Run from Entware via SSH:**

```
curl -Ls https://raw.githubusercontent.com/jinndi/XKeen/main/install.sh | sh
```
Manage the package further using the `skeen` command.

Configure sing-box by editing `/opt/etc/skeen/config/config.json`

You can organize the files in the `/opt/etc/skeen/config` folder however you like.  
All of them will be used when running sing-box.  
The folder itself will not be deleted when uninstalling the program — this must be done manually.  
It will also not be overwritten if it already exists during a reinstallation.

Access the web interface at the router's IP (usually 192.168.1.1) on port `9090`
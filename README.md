<p align="center">
  <img alt="SKeen" src="/logo.webp" width="235">
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
|`status`|Shows the current status of the process Sing-box|
|`diagnostic`|Check whether iptables rules are correctly applied for the current operating mode (requires Sing-box to be running and the mode to be anything except none)|
|`check_deps`|Check if all dependencies are installed (installs missing ones)|
|`kill`|Forcefully terminates the Sing-box process (`kill -9`)|
|`version`|Displays the current application version|

### ⚙️ Settigs

The file `/opt/etc/skeen/skeen.conf` has the following settings:

| Variable | Description |
| ------------ | -------------------------------------------------------------- |
|`AUTO_START`|Sing-box autostart on router reboot (0 - disabled, 1 - enabled)|
|`AUTO_START_DELAY`|Auto-start delay in seconds (Default 0)|
|`IPV4_TEST_HOSTS`, `IPV6_TEST_HOSTS` |Domains or IPs for testing the internet connection (no more than 3). List: ya.ru,77.88.8.8,... or ya.ru 77.88.8.8|
|`POLICY_NAME`|Router policy name for SKeen traffic (Default `SKeen`)|
|`INTERCEPT_PORTS`|Ports to intercept and redirect via TProxy/Redirect (all ports if not specified). List: port and port ranges use colon e.g. 80,443,1000:2000 or 80 443 1000:2000|
|`EXCLUDE_PORTS`|Ports to excluded redirect via TProxy/Redirect (Not working if ports are set in `INTERCEPT_PORTS`). List: port and port ranges use colon e.g. 8080,1443,1300:2300 or 8080 1443 1300:2300|
|`EXCLUDE_IPV4_ADDRESES`, `EXCLUDE_IPV6_ADDRESES`|Excluded ip addreses for traffic redirection. List: 192.155.1.1,192.200.1.1,... or 192.155.1.1 192.200.1.1 ...|
|`EXCLUDE_IPV4_SUBNETS`, `EXCLUDE_IPV6_SUBNETS`|Excluded subnets for traffic redirection. List: 192.155.1.1/24,192.200.1.1/24,... or 192.155.1.1/24 192.200.1.1/24 ...|

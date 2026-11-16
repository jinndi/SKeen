# SKeen REST API Documentation

REST API documentation for the **SKeen** system — a lightweight HTTP configuration and management server for the SKeen utility, written in Lua using the `luasocket` library.

## Table of Contents

1. [Installation & Dependencies](#1-installation--dependencies)

2. [Overview & Architecture](#2-overview--architecture)

3. [Daemon & CLI Management](#3-daemon--cli-management)

4. [API Configuration](#4-api-configuration)

5. [Authentication & Security](#5-authentication--security)

6. [REST API Endpoints](#6-rest-api-endpoints)

   * [GET /](#1-get-)

   * [GET /api/ping](#2-get-apiping)

   * [GET /api/status](#3-get-apistatus)

   * [GET /api/system/status](#4-get-apisystemstatus)

   * [GET /api/files-list](#5-get-apifiles-list)

   * [GET /api/file](#6-get-apifile)

   * [POST /api/file](#7-post-apifile)

   * [POST /api/exec](#8-post-apiexec)

   * [GET /api/dash](#9-get-apidash)

7. [HTTP Response Codes](#7-http-response-codes)

## 1. Installation & Dependencies

Starting with SKeen version 5.9.0, `skeen-api` is automatically installed as a required dependency along with SKeen.

### Disk Space Requirements

The total installation footprint is **less than 400 KB**:
- **SKeen API (Backend + Frontend)**: < 100 KB
- **Lua package (`opkg package: lua`)**: ~20 KB
- **LuaSocket package (`opkg package: luasocket`)**: ~250 KB

### Recovering Missing Dependencies

If the dependency check was interrupted during an update, you can run the following command at any time to verify and install missing packages:

```bash
skeen deps
```

## 2. Overview & Architecture

`skeen-api` is a combined module featuring a CLI service/daemon management utility and an embedded single-threaded web server.

### Key Features:

- **Stack**: Lua (verified for compatibility with `/opt/bin/lua`), `luasocket`.

- **Architecture & Resilience**:
  - Synchronous HTTP/1.1 request handling.
  - The request line and all headers have a **10-second combined deadline**; reading the request body has a separate **10-second timeout**.
  - Safe request execution wrapped in `pcall` to ensure socket cleanup and prevent file descriptor leaks during connection drops.

- **Performance Optimization & Compression**:
  - Built-in TTL caches for SKeen system status calls and hardware telemetry (refreshed every 2–3 seconds), significantly reducing router CPU load during frequent web dashboard polling.
  - **Gzip Compression Support**: The server checks the client's `Accept-Encoding` header. If `gzip` is supported, text responses, JSON, and HTML pages are compressed "on the fly" with a `Content-Encoding: gzip` header to minimize network bandwidth consumption.

- **Data Format**: JSON (custom parser with support for stripping `//`, `/* */`, and `#` comments while preserving key ordering via the `__order` field).

- **SKeen CLI Integration**: System command execution via `io.popen`, dynamic fetching of Sing-box configurations via `skeen get_singbox_config --json`, API settings retrieval via `skeen get_api_config`, and dashboard parameters via `skeen dash --json`.

- **Safe File Management**: Atomic writes using temporary `.tmp` files.

## 3. Daemon & CLI Management

The `skeen-api` script includes a CLI interface for background process management powered by `start-stop-daemon`.

### CLI Commands:

```bash
skeen-api {start|stop|restart|run|status|update|version}
```

- `start` — Starts the API server in the background (PID saved to `/tmp/run/skeen-api.pid`).

- `stop` — Stops the background process.

- `restart` — Restarts the service.

- `run` — Runs the server directly in the current terminal (foreground).

- `status` — Displays current status: PID, Uptime (days/hours/minutes), and memory usage (VmRSS/VmHWM from `/proc`).

- `update` — Checks for updates and downloads the latest script version from GitHub.

- `version` (or `-v`) — Prints current script version (e.g., `v1.0.0`).

## 4. API Configuration

Server settings are dynamically requested from the main CLI system by executing `skeen get_api_config`.

### Default Settings:

```json
{
  "port": 3000,
  "secret": "",
  "cors_origin": ["*"],
  "dashboard": 1
}
```

- **port** (*number*): Port bound on socket `0.0.0.0` (default is `3000`).

- **secret** (*string*): Secret authentication key (`X-API-Key` header). If empty, authentication is disabled.

- **cors_origin** (*array*): CORS (Cross-Origin Resource Sharing) configuration. Defines allowed origin sites/domains for browser requests.
  - `["*"]` — Allows access from any domain.
  - `["http://192.168.1.1:3000", "https://skeen.indevs.in"]` — Restricts access strictly to specified origins.

- **dashboard** (*number*): `1` — Enables serving the HTML Dashboard page at route `/`, `0` — returns `404 Not Found`.

## 5. Authentication & Security

### Rate Protection & DoS Defense

The server incorporates strict system-level limits to protect router memory and execution resources:

1. **Request read timeouts**: The request line and all headers must arrive within a **10-second combined deadline**. Reading the request body has a separate **10-second timeout**.

2. **Request size limits**: The body is limited to **1 MB** (`1024 * 1024` bytes), the request line to **4096 bytes**, each header line to **8192 bytes**, and all headers combined to **16384 bytes**.

3. **Header Slowloris Protection**: A limit of **50 header lines** per connection is enforced. Exceeding a header limit returns `431 Request Header Fields Too Large`; an oversized body is rejected with `413 Payload Too Large`.

4. **Request rate limiting**: The limit depends on authorization. Authorized clients (valid `X-API-Key`) get **100 requests in any rolling minute** (a 60-second sliding window, counter updated per request); unauthorized clients get **3 requests in any rolling minute**. Applies to all `/api/*` paths. Exceeding the limit returns `429 Too Many Requests` with a `Retry-After` header. CORS `OPTIONS` preflight requests are excluded.

Note: SKeen commands execute synchronously and are not limited by these socket timeouts. While a long-running command is executing, the single-threaded server cannot process other connections.

### API Key (X-API-Key)

If `secret` is configured (non-empty string), all endpoints starting with `/api/` require the header:

```http
X-API-Key: your_secret_key
```

If missing or invalid, the server returns `401 Unauthorized`.

### CORS & Security Headers

For successfully parsed requests, the server adds security and CORS headers. Malformed or oversized requests may receive only minimal HTTP headers; `OPTIONS` preflight requests use a separate response path.

- `Access-Control-Allow-Origin` — Dynamically populated based on the `cors_origin` whitelist from the configuration. If the domain is allowed, the client's exact `Origin` is returned; if not, the header is omitted, and the browser blocks the request.
- `Vary: Origin` — Added with an allowed `Access-Control-Allow-Origin` header.
- `Vary: Accept-Encoding` — Added to responses from `/` because Dashboard delivery depends on gzip support. When both values apply, the server sends two `Vary` header lines; HTTP treats them as equivalent to one `Vary: Origin, Accept-Encoding`.
- `Access-Control-Allow-Methods: GET, POST, OPTIONS` — Advertises methods allowed for browser CORS preflight; it does not block direct HTTP requests by itself.
- `Access-Control-Allow-Headers: X-API-Key, Content-Type` — Allows browsers to send these headers in CORS requests.
- `X-Content-Type-Options: nosniff` — Prevents browsers from guessing the response MIME type.
- `X-Frame-Options: SAMEORIGIN` — Allows the page to be displayed in a frame only by the same origin.
- `Content-Type` — Response media type, such as `application/json`, `text/html`, or `text/plain`; present on regular responses.
- `Content-Length` — Response body size in bytes; present on regular responses.
- `Content-Encoding: gzip` — Added to the gzip-compressed Dashboard when the client supports it.
- `Connection: close` — The server closes the connection after the response; also sent for `OPTIONS` and some request-parsing errors.
- `Retry-After` and `Access-Control-Expose-Headers: Retry-After` — Sent with `429`; the latter lets browser code read the `Retry-After` value.
- `Cache-Control: no-store, no-cache, must-revalidate` — Added to regular responses; the separate `OPTIONS` response does not include it.

The `OPTIONS` response includes CORS and security headers, but not `Content-Type`, `Content-Length`, or `Cache-Control`. Some early failures (such as a timeout or an overlong request line) close the connection without an HTTP response; other parsing errors return only the status and `Connection: close`.

> **Important when deploying via KeenDNS/CrazeDNS (OS 4.2+):**
> To prevent the router's built-in proxy server from stripping the `Origin` header (provided that specific allowed domain names are specified in `cors_origin`) for requests from the external network, make sure that the corresponding option is enabled in the router's CLI for your application:
>
> ```text
> ip http proxy myapi preserve-origin
> system configuration save
> ```
> Where "myapi" is the 4th-level application DNS name from the KeenDNS/CrazeDNS section.

## 6. REST API Endpoints

### 1. GET /

Requests the main web interface page.

- **Method**: `GET`

- **Authentication**: Not required.

- **Details**: Behavior depends on the `dashboard` parameter in the configuration:
  - If `dashboard: 1`, returns the interface HTML code (`text/html; charset=utf-8`) with optional gzip compression (when requested via `Accept-Encoding: gzip`). In production mode, if the client lacks gzip support, the server returns `406 Not Acceptable`.
  - If `dashboard: 0`, the endpoint is disabled and returns status `404 Not Found`.

#### Request Example:

```bash
curl -X GET http://192.168.1.1:3000/
```

- **Response**: HTML UI code (`text/html; charset=utf-8`).

### 2. GET /api/ping

Checks server availability and health.

- **Method**: `GET`

- **Authentication**: Required (if `secret` is set).

#### Request Example:

```bash
curl -X GET http://192.168.1.1:3000/api/ping \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response (`200 OK`):

```json
{
  "status": "ok",
  "message": "pong"
}
```

### 3. GET /api/status

Retrieves SKeen system status and API version.

- **Method**: `GET`

- **Authentication**: Required.

- **Feature**: Data is served from a local TTL cache (3-second lifetime), eliminating redundant system process spawns during high-frequency UI polling.

#### Request Example:

```bash
curl -X GET http://192.168.1.1:3000/api/status \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response (`200 OK`):

```json
{
  "success": true,
  "running": true,
  "mode": "sing-box",
  "version": "1.2.0",
  "sb_version": "1.8.0",
  "api_version": "1.0.0"
}
```

### 4. GET /api/system/status

Retrieves hardware metrics and system resource load (CPU, RAM, SWAP, Entware `/opt` disk, network throughput, active connection count).

- **Method**: `GET`

- **Authentication**: Required.

- **Feature**: Cached for 2 seconds (TTL) in the Lua daemon to minimize CPU overhead on the router.

#### Response Field Reference:

| Field | Type | Description |
| ----- | ----- | ----- |
| `device` | *string* | Router model name. |
| `cpu_load` | *number* | CPU load percentage (0 to 100). |
| `cpu_temp` | *number* | CPU temperature in degrees Celsius (°C). |
| `mem_used` | *number* | Used RAM memory size (in kilobytes, KB). |
| `mem_total` | *number* | Total RAM memory size (in kilobytes, KB). |
| `swap_used` | *number* | Used SWAP space (in kilobytes, KB). |
| `swap_total` | *number* | Total SWAP space (in kilobytes, KB; `0` if not configured). |
| `opt_used` | *number* | Used Entware `/opt` partition space (in kilobytes, KB). |
| `opt_total` | *number* | Total Entware `/opt` partition space (in kilobytes, KB). |
| `uptime` | *number* | System uptime in seconds. |
| `loadavg` | *array* | System load average percentage for 1, 5, and 15 minutes `[1m, 5m, 15m]`. |
| `def_iface` | *string* | Primary network interface name (e.g., `br0` or `eth3`). |
| `rx_speed` | *number* | Inbound network traffic speed (in bytes per second, B/s). |
| `tx_speed` | *number* | Outbound network traffic speed (in bytes per second, B/s). |
| `conn_cnt` | *number* | Total tracked active connections count from `/proc/net/nf_conntrack`. |

#### Request Example:

```bash
curl -X GET http://192.168.1.1:3000/api/system/status \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response (`200 OK`):

```json
{
  "cpu_load": 12,
  "def_iface": "br0",
  "rx_speed": 1048576,
  "tx_speed": 524288,
  "conn_cnt": 142,
  "mem_used": 262144,
  "mem_total": 524288,
  "swap_used": 0,
  "swap_total": 0,
  "opt_used": 154200,
  "opt_total": 7771236
}
```

### 5. GET /api/files-list

Retrieves list of configuration files allowed for reading and editing.

- **Method**: `GET`

- **Authentication**: Required.

Dynamically queries file paths and structure from SKeen:

- `skeen`: Primary configuration file `skeen.json`.

- `pure_cidr`: CIDR list (`pure_cidr.list`).

- `singbox` / `sb_file_*`: Sing-box configurations (`config.json` or directory map array) queried via CLI command `skeen get_singbox_config --json`.

#### Request Example:

```bash
curl -X GET http://192.168.1.1:3000/api/files-list \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response (`200 OK`):

```json
[
  {
    "id": "pure_cidr",
    "name": "pure_cidr.list"
  },
  {
    "id": "skeen",
    "name": "skeen.json"
  },
  {
    "id": "singbox",
    "name": "config.json"
  }
]
```

### 6. GET /api/file

Reads the contents of a configuration file by its identifier (`id`).

- **Method**: `GET`

- **URL Parameters**: `name` (string) — file `id` (e.g., `skeen`, `pure_cidr`, `singbox`, `sb_file_0`). Default: `skeen`.

- **Authentication**: Required.

#### Request Example:

```bash
curl -X GET "http://192.168.1.1:3000/api/file?name=skeen" \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response for `skeen.json` (`200 OK`):

*Comments `//`, `/* */`, and `#` are automatically stripped before returning.*

```json
{
  "success": true,
  "content": {
    "mode": "rule",
    "singbox": {
      "auto_start": true
    }
  }
}
```

#### Successful Response for Other JSON Files (`200 OK`):

```json
{
  "success": true,
  "content": {
    "inbounds": []
  }
}
```

#### Successful Response for Text File (`200 OK`):

```json
{
  "success": true,
  "content": "192.168.1.0/24\n10.0.0.0/8\n"
}
```

### 7. POST /api/file

Saves or updates configuration file content.

- **Method**: `POST`

- **Header**: `Content-Type: application/json`

- **Authentication**: Required.

#### Request Body (JSON):

- `name` (*string*): Target file identifier.

- `content` (*object|string*): New content. JSON object for `json` files, string for `text` files.

#### Request Example (updating text file `pure_cidr`):

```bash
curl -X POST http://192.168.1.1:3000/api/file \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "pure_cidr",
       "content": "192.168.1.0/24\n172.16.0.0/12\n"
     }'
```

#### Request Example (updating JSON file `skeen`):

```bash
curl -X POST http://192.168.1.1:3000/api/file \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "skeen",
       "content": {
         "mode": "rule"
       }
     }'
```

#### Successful Response (`200 OK`):

```json
{
  "success": true,
  "message": "File updated"
}
```

### 8. POST /api/exec

Executes allowed CLI commands (`skeen <param>`).

- **Method**: `POST`

- **Header**: `Content-Type: application/json`

- **Authentication**: Required.

#### Allowed Commands (`param`):

`start`, `stop`, `restart`, `reload`, `kill`, `status`, `version`, `help`, `iface`, `connstat`, `test`, `deps`, `check`, `format`, `backup`, `backups`, `clean`, `sync`, `headers`, `restore <file>`, `sync <url>`, `tun list`, `tun create <ip> <dev>`, `tun delete <dev>`, `areload`, `aupdate`.

> **Note:** The `areload` and `aupdate` commands are executed directly via the API server's internal functions (without spawning the external `skeen` CLI tool). The `aupdate` check and download run synchronously. When a new version is installed successfully, the API returns `"updated": true` and schedules a service restart after 2 seconds so the current HTTP request can complete. The built-in web interface then automatically reloads the page. If no update was installed (for example, the API is already up to date or an error occurred), `"updated": false`; the service is not restarted and the page is not automatically reloaded.

#### Response after a successful API update:

```json
{
  "success": true,
  "updated": true,
  "stdout": "[OK] API script updated to v1.2.1"
}
```

#### Request Body (JSON):

```json
{
  "param": "restart"
}
```

#### Request Example:

```bash
curl -X POST http://192.168.1.1:3000/api/exec \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{"param": "status"}'
```

#### Successful Response (`200 OK`):

```json
{
  "success": true,
  "stdout": "SKeen status: running\nService is active."
}
```

### 9. GET /api/dash

Retrieves the configured list of external APIs and management dashboards (Sing-box API, Clash API, etc.).

- **Method**: `GET`

- **Authentication**: Required (if `secret` is set).

- **Description**: Executes the system command `skeen dash --json` and returns an array of available dashboards along with their URLs.

#### Request Example:

```bash
curl -X GET http://192.168.1.1:3000/api/dash \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response (`200 OK`):

```json
{
  "success": true,
  "data": [
    {
      "type": "api",
      "url": "http://192.168.1.1:9090"
    }
  ]
}
```

## 7. HTTP Response Codes

| Code | Status | Description |
| ----- | ----- | ----- |
| `200` | **OK** | Request completed successfully. |
| `204` | **No Content** | Successful response for `OPTIONS` CORS preflight request. |
| `400` | **Bad Request** | Malformed HTTP request, invalid JSON, or unregistered command in `/api/exec`. |
| `401` | **Unauthorized** | Missing or invalid `X-API-Key` header. |
| `404` | **Not Found** | Route does not exist or Dashboard is disabled. |
| `406` | **Not Acceptable** | The client did not send the required `Accept-Encoding: gzip` header needed to serve the embedded dashboard at `/`. |
| `413` | **Payload Too Large** | Request body size exceeds the **1 MB** limit. |
| `429` | **Too Many Requests** | Rate limit exceeded. See the `Retry-After` header. |
| `431` | **Request Header Fields Too Large** | Number of header lines exceeds the **50 line** limit (Slowloris mitigation). |
| `500` | **Internal Server Error** | Disk write error. |

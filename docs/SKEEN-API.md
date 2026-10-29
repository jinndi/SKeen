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

   * [GET /api/files-list](#4-get-apifiles-list)

   * [GET /api/file](#5-get-apifile)

   * [POST /api/file](#6-post-apifile)

   * [POST /api/exec](#7-post-apiexec)

7. [HTTP Response Codes](#7-http-response-codes)

## 1. Installation & Dependencies

Starting with SKeen version 5.9.0, `skeen-api` is automatically installed as a required dependency along with SKeen.

### Disk Space Requirements

The total installation footprint is **less than 500 KB**:
- **SKeen API (Backend + Frontend)**: < 150 KB
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

- **Architecture**: Synchronous HTTP/1.1 request handling with a client connection timeout (`30 sec`).

- **Data Format**: JSON (custom parser with support for stripping `//`, `/* */`, and `#` comments while preserving key ordering via the `__order` field).

- **SKeen CLI Integration**: System command execution via `io.popen`, dynamic fetching of Sing-box configurations via `skeen get_singbox_config --json`, and API settings retrieval via `skeen get_api_config`.

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

### API Key (X-API-Key)

If `secret` is configured (non-empty string), all endpoints starting with `/api/` require the header:

```http
X-API-Key: your_secret_key
```

If missing or invalid, the server returns `401 Unauthorized`.

### CORS & Security Headers

Every server response includes security headers:

- `X-Content-Type-Options: nosniff`

- `X-Frame-Options: SAMEORIGIN`

- `Access-Control-Allow-Methods: GET, POST, OPTIONS`

- `Access-Control-Allow-Headers: X-API-Key, Content-Type`

## 6. REST API Endpoints

### 1. GET /

Requests the main web interface page.

- **Method**: `GET`

- **Authentication**: Not required.

- **Dependency**: Requires `dashboard: 1`.

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

### 4. GET /api/files-list

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

### 5. GET /api/file

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

### 6. POST /api/file

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

### 7. POST /api/exec

Executes allowed CLI commands (`skeen <param>`).

- **Method**: `POST`

- **Header**: `Content-Type: application/json`

- **Authentication**: Required.

#### Allowed Commands (`param`):

`start`, `stop`, `restart`, `reload`, `kill`, `status`, `version`, `help`, `iface`, `connstat`, `test`, `deps`, `check`, `format`, `backup`, `backups`, `clean`, `sync`, `headers`, `areload`, `restore <file>`, `sync <url>`, `tun list`, `tun create <ip> <dev>`, `tun delete <dev>`.

*(Note: `areload` executes asynchronously with a 2-second delay so that the current HTTP connection can return `200 OK` to the browser first).*

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

## 7. HTTP Response Codes

| Code | Status | Description |
| ----- | ----- | ----- |
| `200` | **OK** | Request completed successfully. |
| `204` | **No Content** | Successful response for `OPTIONS` CORS preflight request. |
| `400` | **Bad Request** | Malformed HTTP request, invalid JSON, or unregistered command in `/api/exec`. |
| `401` | **Unauthorized** | Missing or invalid `X-API-Key` header. |
| `404` | **Not Found** | Route does not exist or Dashboard is disabled. |
| `500` | **Internal Server Error** | Disk write error. |

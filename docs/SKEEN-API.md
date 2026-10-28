# SKeen REST API Documentation

REST API documentation for the **SKeen** system — a lightweight HTTP server written in Lua using the `luasocket` library for managing SKeen configuration and CLI utilities.

## Table of Contents

1. [Installation & Dependencies](#1-installation--dependencies)
2. [Overview & Architecture](#1-overview--architecture)
4. [Daemon & CLI Management](#2-daemon--cli-management)
5. [API Configuration](#3-api-configuration)
6. [Authentication & Security](#4-authentication--security)
7. [REST API Endpoints](#5-rest-api-endpoints)
   * [GET /](#1-get-)
   * [GET /api/ping](#2-get-apiping)
   * [GET /api/status](#3-get-apistatus)
   * [GET /api/files-list](#4-get-apifiles-list)
   * [GET /api/file](#5-get-apifile)
   * [POST /api/file](#6-post-apifile)
   * [POST /api/exec](#7-post-apiexec)
7. [HTTP Status Codes](#6-http-status-codes)

## 1. Installation & Dependencies

Starting with **SKeen v5.9.0**, `skeen-api` is bundled and automatically installed alongside SKeen as an essential dependency.

### Storage Footprint

The overall installation consumes **less than 500 KB** of disk space:
- **SKeen API (Backend + Frontend)**: < 150 KB
- **Lua Environment (`opkg package: lua`)**: ~20 KB
- **LuaSocket Extension (`opkg package: luasocket`)**: ~250 KB

### Resolving Missing Dependencies

If the dependency check or installation process was interrupted during an update, you can manually verify and reinstall all required packages by running:

```bash
skeen deps
```

## 2. Overview & Architecture

`skeen-api` is a combined module consisting of a CLI utility for managing the service (daemon) and an embedded single-threaded web server.

### Key Features:

* **Stack**: Lua (verified for compatibility with `/opt/bin/lua`), `luasocket`.
* **Architecture**: Synchronous HTTP/1.1 request handling with a client connection timeout (`30 sec`).
* **Data Format**: JSON (custom parser with support for stripping comments `//`, `/* */`, `#` and preserving key order via the `__order` field).
* **Integration**: Execution of system `skeen` commands via `io.popen` and safe filesystem management (atomic writes using temporary `.tmp` files).

## 3. Daemon & CLI Management

The `skeen-api` script includes a CLI interface for managing background processes using `start-stop-daemon`.

### CLI Commands:

```bash
skeen-api {start|stop|restart|run|status|update|version}
```

* `start` — Starts the API server in background mode (PID is saved to `/tmp/run/skeen-api.pid`).
* `stop` — Stops the background process.
* `restart` — Restarts the service.
* `run` — Runs the server directly in the current terminal (foreground).
* `status` — Displays current status: PID, Uptime (in days/hours/minutes), and memory usage (VmRSS/VmHWM from `/proc`).
* `update` — Checks for updates and downloads the latest version of the script from GitHub.
* `version` (or `-v`) — Prints the current version of the script (e.g., `v1.0.0`).

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

* **port** (*number*): Port bound to `0.0.0.0` (default `3000`).
* **secret** (*string*): Secret authorization key (Header `X-API-Key`). If empty, authorization is disabled.
* **cors_origin** (*array*): CORS (Cross-Origin Resource Sharing) setting. Defines a list of sites/domains allowed to make requests to the API from a browser.
  - `["*"]` — allows access from any domain.
  - `["http://192.168.1.1:3000", "https://skeen.indevs.in"]` — restricts access only to specified sources.
* **dashboard** (*number*): `1` — serves the Dashboard HTML page at route `/`, `0` — returns `404 Not Found`.

## 5. Authentication & Security

### API Key (X-API-Key)

If a `secret` key is configured (non-empty string), all endpoints starting with `/api/` require the header:

```http
X-API-Key: your_secret_key
```

If missing or invalid, the server returns `401 Unauthorized`.

### CORS & Security Headers

Every server response includes security headers:

* `X-Content-Type-Options: nosniff`
* `X-Frame-Options: SAMEORIGIN`
* `Access-Control-Allow-Methods: GET, POST, OPTIONS`
* `Access-Control-Allow-Headers: X-API-Key, Content-Type`

## 6. REST API Endpoints

### 1. GET /

Requests the main page (web interface).

* **Method**: `GET`
* **Authorization**: Not required.
* **Dependency**: Parameter `dashboard: 1` must be enabled.

#### Example Request:

```bash
curl -X GET http://192.168.1.1:3000/
```

* **Response**: Interface HTML code (`text/html; charset=utf-8`).

### 2. GET /api/ping

Checks server availability and health.

* **Method**: `GET`
* **Authorization**: Required (if `secret` is enabled).

#### Example Request:

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

Retrieves system status of SKeen and API version.

* **Method**: `GET`
* **Authorization**: Required.

#### Example Request:

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

Retrieves a list of configuration files allowed for reading and editing.

* **Method**: `GET`
* **Authorization**: Required.

Dynamically resolves paths from `/opt/etc/skeen/skeen.json`:

* `skeen`: Main configuration file `skeen.json`.
* `pure_cidr`: CIDR list (default `pure_cidr.list` or from field `firewall.intercept.fakeip.include`).
* `singbox` / `sb_file_*`: Sing-box configuration (`config.json` or matched `.json` files in the directory).

#### Example Request:

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

Reads configuration file contents by identifier (`id`).

* **Method**: `GET`
* **URL Parameters**: `name` (string) — file `id` (e.g., `skeen`, `pure_cidr`, `singbox`, `sb_file_0`). Default: `skeen`.
* **Authorization**: Required.

#### Example Request:

```bash
curl -X GET "http://192.168.1.1:3000/api/file?name=skeen" \
     -H "X-API-Key: your_secret_key"
```

#### Successful Response for JSON file (`200 OK`):

*Comments are automatically stripped before returning JSON objects.*

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

#### Successful Response for text file (`200 OK`):

```json
{
  "success": true,
  "content": "192.168.1.0/24\n10.0.0.0/8\n"
}
```

### 6. POST /api/file

Saves/updates configuration file contents.

* **Method**: `POST`
* **Header**: `Content-Type: application/json`
* **Authorization**: Required.

#### Request Body (JSON):

* `name` (*string*): Target file identifier.
* `content` (*object|string*): New content. JSON object for `json` files, string for `text` files.

#### Example Request (updating text file `pure_cidr`):

```bash
curl -X POST http://192.168.1.1:3000/api/file \
     -H "X-API-Key: your_secret_key" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "pure_cidr",
       "content": "192.168.1.0/24\n172.16.0.0/12\n"
     }'
```

#### Example Request (updating JSON file `skeen`):

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

Executes allowed CLI commands `skeen <param>`.

* **Method**: `POST`
* **Header**: `Content-Type: application/json`
* **Authorization**: Required.

#### Allowed Commands (`param`):

`start`, `stop`, `restart`, `reload`, `kill`, `status`, `version`, `help`, `iface`, `connstat`, `test`, `deps`, `check`, `format`, `backup`, `backups`, `clean`, `sync`, `headers`, `areload`, `restore <file>`, `sync <url>`, `tun list`, `tun create <ip> <dev>`, `tun delete <dev>`.

*(Note: `areload` runs asynchronously with a 2-second delay to ensure the HTTP 200 response is sent first).*

#### Request Body (JSON):

```json
{
  "param": "restart"
}
```

#### Example Request:

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

## 7. HTTP Status Codes

| Code | Status | Description |
| ----- | ----- | ----- |
| `200` | **OK** | Request completed successfully. |
| `204` | **No Content** | Successful response to `OPTIONS` CORS preflight request. |
| `400` | **Bad Request** | Invalid HTTP request, malformed JSON, or unregistered parameter in `/api/exec`. |
| `401` | **Unauthorized** | Missing or invalid `X-API-Key` header. |
| `404` | **Not Found** | Route does not exist or Dashboard is disabled. |
| `500` | **Internal Server Error** | File write failure on disk. |

#!/opt/bin/lua

local socket = require("socket")

-------------------------------------------------------------------------------
-- 0. VERSION AND COMMAND LINE ARGUMENT (CLI) HANDLING
-------------------------------------------------------------------------------
local VERSION = "1.3.3"
local SCRIPT = "/opt/bin/skeen-api"
local LUA_BIN = "/opt/bin/lua"
local PID_FILE = "/tmp/run/skeen-api.pid"
local SKEEN_RAM_SCRIPT = "/tmp/.skeen/skeen.sh"
local SKEEN_OPT_SCRIPT = "/opt/bin/skeen"
local REPO_BASE_URL = "https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/static/"
local VERSION_URL = REPO_BASE_URL .. "api-version"
local SCRIPT_URL = REPO_BASE_URL .. "skeen-api"
local DEVELOPMENT = false

-- Function for safely escaping arguments to pass them into the command line
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- Helper function to resolve the target skeen executable (prefers memory-cached tmpfs script)
local function get_skeen_cmd(args)
  local script_path = SKEEN_OPT_SCRIPT
  local f = io.open(SKEEN_RAM_SCRIPT, "r")
  if f then
    f:close()
    script_path = SKEEN_RAM_SCRIPT
  end
  return shell_quote(script_path) .. (args and (" " .. args) or "")
end

-- Function to read a text file from a given path
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()
  return content
end

-- Function to execute a system command with completion status checking
local function run_command(command)
  local ok, _, code = os.execute(command)

  if ok == true or ok == 0 then
    return true
  end

  return false, code or ok
end

-- Start the daemon (background process of the API server)
local function daemon_start()
  local pid = tonumber((read_file(PID_FILE) or ""):match("^%s*(%d+)"))
  if pid and read_file("/proc/" .. pid .. "/stat") then
    print("[OK] Already running")
    return
  end

  os.remove(PID_FILE)

  local command = table.concat({
    "start-stop-daemon -S -b -m",
    "-p", shell_quote(PID_FILE),
    "-x", shell_quote(LUA_BIN),
    "--", shell_quote(SCRIPT), "run",
    ">/dev/null 2>&1"
  }, " ")

  if not run_command(command) then
    io.stderr:write("[ERROR] Failed to start the service\n")
    os.exit(1)
  end

  print("[OK] Started")
end

-- Stop the daemon
local function daemon_stop()
  local pid = tonumber((read_file(PID_FILE) or ""):match("^%s*(%d+)"))
  if not pid or not read_file("/proc/" .. pid .. "/stat") then
    os.remove(PID_FILE)
    print("[OK] Already stopped")
    return
  end

  local command = "start-stop-daemon -K -p " ..
      shell_quote(PID_FILE) .. " >/dev/null 2>&1"

  if not run_command(command) then
    io.stderr:write("[ERROR] Failed to stop the service\n")
    os.exit(1)
  end

  os.remove(PID_FILE)
  print("[OK] Stopped")
end

-- Restart the daemon (stop + start)
local function daemon_restart()
  local pid = tonumber((read_file(PID_FILE) or ""):match("^%s*(%d+)"))
  if pid and read_file("/proc/" .. pid .. "/stat") then
    local command = "start-stop-daemon -K -p " ..
        shell_quote(PID_FILE) .. " >/dev/null 2>&1"

    if not run_command(command) then
      io.stderr:write("[ERROR] Failed to stop the service; restart aborted\n")
      os.exit(1)
    end
  end

  os.remove(PID_FILE)

  local start_command = table.concat({
    "start-stop-daemon -S -b -m",
    "-p", shell_quote(PID_FILE),
    "-x", shell_quote(LUA_BIN),
    "--", shell_quote(SCRIPT), "run",
    ">/dev/null 2>&1"
  }, " ")

  if not run_command(start_command) then
    io.stderr:write("[ERROR] Failed to start the service\n")
    os.exit(1)
  end

  print("[OK] Restarted")
end

-- Get process memory usage information by its PID
local function get_memory(pid)
  local content = read_file("/proc/" .. pid .. "/status")
  if not content then
    return nil, nil
  end

  local rss = tonumber(content:match("\nVmRSS:%s+(%d+)"))
  local peak = tonumber(content:match("\nVmHWM:%s+(%d+)"))

  return rss, peak
end

-- Calculate process uptime in seconds
local function get_uptime(pid)
  local stat = read_file("/proc/" .. pid .. "/stat")
  local system_uptime = read_file("/proc/uptime")

  if not stat or not system_uptime then
    return nil
  end

  -- Fields after the process name start from the 3rd field (state).
  local fields = stat:match("^%d+ %b() (.*)$")
  if not fields then
    return nil
  end

  local start_ticks
  local index = 0

  for value in fields:gmatch("%S+") do
    index = index + 1

    -- starttime (process start time) is located at the 20th position (22nd field in /proc/[pid]/stat).
    if index == 20 then
      start_ticks = tonumber(value)
      break
    end
  end

  local uptime = tonumber(system_uptime:match("^(%d+%.?%d*)"))
  if not start_ticks or not uptime then
    return nil
  end

  -- Standard CLK_TCK value for Linux 100 (getconf CLK_TCK)
  return math.max(0, math.floor(uptime - start_ticks / 100))
end

-- Pretty format seconds into days, hours, and minutes
local function format_uptime(seconds)
  local days = math.floor(seconds / 86400)
  local hours = math.floor(seconds % 86400 / 3600)
  local minutes = math.floor(seconds % 3600 / 60)

  return string.format("%dd %dh %dm", days, hours, minutes)
end

-- Format memory size from kilobytes to megabytes
local function format_memory(kb)
  if not kb then
    return "N/A"
  end

  return math.floor(kb / 1024 + 0.5) .. " MB"
end

-- Print current service status to the console
local function daemon_status()
  local pid = tonumber(
    (read_file(PID_FILE) or ""):match("^%s*(%d+)")
  )

  if not pid or not read_file("/proc/" .. pid .. "/stat") then
    print("Status: stopped")
    os.exit(1)
  end

  local uptime = get_uptime(pid)
  local rss, peak = get_memory(pid)

  print("Status: running")
  print("PID: " .. pid)
  print("Uptime: " .. (uptime and format_uptime(uptime) or "N/A"))
  print("Memory: " .. format_memory(rss) ..
    " (peak: " .. format_memory(peak) .. ")")
end

-- Function to check and automatically update the API script from a remote repository
local function update_script()
  local version_tmp = SCRIPT .. ".version.tmp"
  local script_tmp = SCRIPT .. ".update.tmp"

  local function cleanup()
    os.remove(version_tmp)
    os.remove(script_tmp)
  end

  local function download(url, path)
    return run_command(
      "curl -fsSL --connect-timeout 5 --max-time 30 -o " ..
      shell_quote(path) .. " " .. shell_quote(url) ..
      " >/dev/null 2>&1"
    )
  end

  if not download(VERSION_URL, version_tmp) then
    cleanup()
    io.stderr:write("[ERROR] Failed to check for API updates; using current version\n")
    return false
  end

  local file = io.open(version_tmp, "r")
  if not file then
    cleanup()
    io.stderr:write("[ERROR] Failed to read the remote API version\n")
    return false
  end

  local remote_version = file:read("*a")
  file:close()

  remote_version = remote_version:match("^%s*(.-)%s*$")
  remote_version = remote_version:gsub("^v", "")

  if not remote_version:match("^%d+%.%d+%.%d+[%w%.%-]*$") then
    cleanup()
    io.stderr:write("[ERROR] Invalid remote API version\n")
    return false
  end

  if remote_version == VERSION then
    cleanup()
    print("[OK] API script is already up to date (v" .. VERSION .. ")")
    return false
  end

  print("Updating API script: v" .. VERSION .. " -> v" .. remote_version)

  if not download(SCRIPT_URL, script_tmp) then
    cleanup()
    io.stderr:write("[ERROR] Failed to download the API script; using current version\n")
    return false
  end

  if not run_command(
        "chmod 755 " .. shell_quote(script_tmp) .. " >/dev/null 2>&1"
      ) then
    cleanup()
    io.stderr:write("Failed to set API script permissions\n")
    return false
  end

  if not run_command(
        "mv -f " .. shell_quote(script_tmp) .. " " .. shell_quote(SCRIPT) ..
        " >/dev/null 2>&1"
      ) then
    cleanup()
    io.stderr:write("[ERROR] Failed to install the API script update\n")
    return false
  end

  cleanup()
  print("[OK] API script updated to v" .. remote_version)
  return true
end

-- Process command line arguments upon script invocation
local command = arg and arg[1]

if command == "version" or command == "-v" then
  print("v" .. VERSION)
  os.exit(0)
elseif command == "start" then
  daemon_start()
  os.exit(0)
elseif command == "stop" then
  daemon_stop()
  os.exit(0)
elseif command == "restart" then
  daemon_restart()
  os.exit(0)
elseif command == "status" then
  daemon_status()
  os.exit(0)
elseif command == "update" then
  if not update_script() then
    os.exit(1)
  end
  os.exit(0)
elseif command ~= "run" then
  io.stderr:write(
    "Usage: skeen-api {start|stop|restart|run|status|update|version}\n"
  )
  os.exit(1)
end

-------------------------------------------------------------------------------
-- 1. CONSTANTS AND DEFAULT SETTINGS
-------------------------------------------------------------------------------

-- Base path for the SKeen configuration directory
local SKEEN_DIR = "/opt/etc/skeen/"

-- Default configuration file names
local DEFAULT_FILES = {
  skeen     = "skeen.json",
  singbox   = "config.json",
  pure_cidr = "pure_cidr.list"
}

-- Decode Base64 once during startup.
local function base64_decode(data)
  if type(data) ~= "string" then
    return nil, "Invalid Base64 data"
  end

  if #data % 4 ~= 0 then
    return nil, "Invalid Base64 length"
  end

  local alphabet =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

  local lookup = {}

  for i = 1, #alphabet do
    lookup[alphabet:sub(i, i)] = i - 1
  end

  local result = {}

  for i = 1, #data, 4 do
    local a = lookup[data:sub(i, i)]
    local b = lookup[data:sub(i + 1, i + 1)]
    local c_char = data:sub(i + 2, i + 2)
    local d_char = data:sub(i + 3, i + 3)
    local c = lookup[c_char]
    local d = lookup[d_char]

    local is_last = i + 3 == #data

    if a == nil or b == nil then
      return nil, "Invalid Base64 data"
    end

    local byte1 = a * 4 + math.floor(b / 16)

    if c_char == "=" then
      if not is_last or d_char ~= "=" then
        return nil, "Invalid Base64 padding"
      end

      if b % 16 ~= 0 then
        return nil, "Invalid Base64 padding bits"
      end

      result[#result + 1] = string.char(byte1)
    elseif d_char == "=" then
      if not is_last or c == nil then
        return nil, "Invalid Base64 padding"
      end

      if c % 4 ~= 0 then
        return nil, "Invalid Base64 padding bits"
      end

      result[#result + 1] = string.char(
        byte1,
        (b % 16) * 16 + math.floor(c / 4)
      )
    else
      if c == nil or d == nil then
        return nil, "Invalid Base64 data"
      end

      result[#result + 1] = string.char(
        byte1,
        (b % 16) * 16 + math.floor(c / 4),
        (c % 4) * 64 + d
      )
    end
  end

  return table.concat(result)
end

-- Determine the source of the panel HTML (in development mode, read from disk).
local SCRIPT_PATH = arg[0]
local SCRIPT_DIR = SCRIPT_PATH:match("^(.*)/[^/]+$") or "."

-- Return the dashboard HTML from disk when running in development mode.
-- In production, the pre-compressed HTML is served directly from EMBEDDED_HTML_GZIP.
local function get_dashboard_html()
  local f = io.open(SCRIPT_DIR .. "/index.html", "rb")
  if not f then return nil end

  local content = f:read("*a")
  f:close()
  return content
end

-- Check whether the client explicitly accepts gzip content encoding.
local function accepts_gzip(accept_encoding)
  if type(accept_encoding) ~= "string" then return false end

  local gzip_quality, wildcard_quality

  for item in accept_encoding:gmatch("[^,]+") do
    local coding, params = item:match("^%s*([^;%s]+)%s*(.-)%s*$")
    if coding then
      local quality_text = params:match(";%s*q%s*=%s*([^;%s]+)")
      local quality = 1

      if quality_text then
        local parsed = tonumber(quality_text)
        if parsed and parsed >= 0 and parsed <= 1 then
          quality = parsed
        else
          quality = 0
        end
      end

      coding = coding:lower()
      if coding == "gzip" then
        gzip_quality = quality
      elseif coding == "*" then
        wildcard_quality = quality
      end
    end
  end

  if gzip_quality ~= nil then return gzip_quality > 0 end
  return wildcard_quality ~= nil and wildcard_quality > 0 or false
end

-- Strict security check: validation of allowed SKeen CLI command line parameters.
-- Keep the allowlist intentionally narrow while still accepting common, non-shell-safe URL
-- formats used for config sync tasks. The shell command is always built via shell_quote(),
-- so we reject metacharacters that could escape the single-quoted argument boundary.
local function is_valid_sync_url(value)
  if type(value) ~= "string" then return false end
  if not value:match("^https?://") then return false end
  if value == "" or value:find("%s") then return false end

  for i = 1, #value do
    local c = value:sub(i, i)

    if c:match("%c") then
      return false
    end

    if c == '"' or c == "'" or c == '`' or c == '$' or c == '\\' or
        c == ';' or c == '|' or c == '<' or c == '>' or c == '(' or c == ')' or
        c == '{' or c == '}' or c == '[' or c == ']' then
      return false
    end

    if not c:match("[%w%-%._~:/?%#%@!%*+,=%&%[%]]") then
      return false
    end
  end

  return true
end

-- Validate that a CLI parameter is on the allowlist and contains no shell metacharacters
local function is_allowed_param(param)
  if not param or type(param) ~= "string" then return false end
  local exact_allowed = {
    ["start"]    = true,
    ["stop"]     = true,
    ["restart"]  = true,
    ["reload"]   = true,
    ["kill"]     = true,
    ["status"]   = true,
    ["version"]  = true,
    ["help"]     = false,
    ["iface"]    = true,
    ["connstat"] = true,
    ["update"]   = false,
    ["test"]     = true,
    ["deps"]     = true,
    ["check"]    = true,
    ["format"]   = true,
    ["api"]      = false,
    ["dash"]     = true,
    ["backup"]   = true,
    ["backups"]  = true,
    ["reset"]    = false,
    ["clean"]    = true,
    ["sync"]     = true,
    ["headers"]  = true,
    ["areload"]  = true,
    ["aupdate"]  = true
  }
  if exact_allowed[param] then return true end

  if param:match("^restore%s+[%w%-_%.]+$") then return true end
  if param:match("^sync%s+") and is_valid_sync_url(param:match("^sync%s+(.-)$")) then return true end
  if param:match("^tun%s+list$") then return true end
  if param:match("^tun%s+create%s+[%d%.]+%s+[%w%-_]+$") then return true end
  if param:match("^tun%s+delete%s+[%w%-_]+$") then return true end

  return false
end

-------------------------------------------------------------------------------
-- 2. JSON MODULE (KEY ORDERING, COMMENT REMOVAL, AND FORMATTING)
-------------------------------------------------------------------------------

-- Function to remove comments (C++, JS, and # styles) from JSON configurations
local function strip_json_comments(str)
  local result = {}
  local i = 1
  local len = #str
  local in_string = false
  local escape = false

  while i <= len do
    local c = str:sub(i, i)
    local c2 = str:sub(i, i + 1)

    if in_string then
      if escape then
        escape = false
      elseif c == '\\' then
        escape = true
      elseif c == '"' then
        in_string = false
      end
      table.insert(result, c)
      i = i + 1
    else
      if c == '"' then
        in_string = true
        table.insert(result, c)
        i = i + 1
      elseif c2 == '//' then
        while i <= len and str:sub(i, i) ~= '\n' do i = i + 1 end
      elseif c2 == '/*' then
        i = i + 2
        while i <= len and str:sub(i, i + 1) ~= '*/' do i = i + 1 end
        i = i + 2
      elseif c == '#' then
        while i <= len and str:sub(i, i) ~= '\n' do i = i + 1 end
      else
        table.insert(result, c)
        i = i + 1
      end
    end
  end
  return table.concat(result)
end

-- Self-contained JSON parser and encoder with support for preserving key order
local json = (function()
  local json = { _version = "0.1.3" }
  local encode

  local escape_char_map = {
    ["\\"] = "\\",
    ["\""] = "\"",
    ["\b"] = "b",
    ["\f"] = "f",
    ["\n"] = "n",
    ["\r"] = "r",
    ["\t"] = "t",
  }
  local escape_char_map_inv = { ["/"] = "/" }
  for k, v in pairs(escape_char_map) do escape_char_map_inv[v] = k end

  local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
  end

  local function encode_nil(val) return "null" end

  local function encode_table(val, stack, indent, pretty)
    local res = {}
    stack = stack or {}
    if stack[val] then error("circular reference") end
    stack[val] = true

    local next_indent = pretty and (indent .. "  ") or nil
    local newline = pretty and "\n" or ""
    local space = pretty and " " or ""
    local comma_sep = pretty and ",\n" or ","

    if rawget(val, 1) ~= nil or next(val) == nil then
      local n = 0
      for k in pairs(val) do
        if k ~= "__order" then
          if type(k) ~= "number" then error("invalid table: mixed or invalid key types") end
          n = n + 1
        end
      end
      if n ~= #val then error("invalid table: sparse array") end
      for i, v in ipairs(val) do
        table.insert(res, (pretty and next_indent or "") .. encode(v, stack, next_indent, pretty))
      end
      stack[val] = nil
      if #res == 0 then return "[]" end
      return "[" ..
          newline .. table.concat(res, comma_sep) .. newline .. (pretty and indent or "") .. "]"
    else
      local keys = rawget(val, "__order")
      if not keys then
        keys = {}
        for k in pairs(val) do
          if k ~= "__order" then
            if type(k) ~= "string" then error("invalid table: mixed or invalid key types") end
            table.insert(keys, k)
          end
        end
        table.sort(keys)
      end

      for _, k in ipairs(keys) do
        local v = val[k]
        if v ~= nil then
          local encoded_key = encode(k, stack, next_indent, pretty)
          local encoded_val = encode(v, stack, next_indent, pretty)
          table.insert(res,
            (pretty and next_indent or "") .. encoded_key .. ":" .. space .. encoded_val)
        end
      end
      stack[val] = nil
      if #res == 0 then return "{}" end
      return "{" ..
          newline .. table.concat(res, comma_sep) .. newline .. (pretty and indent or "") .. "}"
    end
  end

  local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
  end

  local function encode_number(val)
    if val ~= val or val <= -math.huge or val >= math.huge then
      error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
  end

  local type_func_map = {
    ["nil"] = encode_nil,
    ["string"] = encode_string,
    ["number"] = encode_number,
    ["boolean"] = tostring,
  }

  encode = function(val, stack, indent, pretty)
    local t = type(val)
    if t == "table" then return encode_table(val, stack, indent, pretty) end
    local f = type_func_map[t]
    if f then return f(val) end
    error("unexpected type '" .. t .. "'")
  end

  function json.encode(val, pretty) return (encode(val, nil, "", pretty)) end

  local parse
  local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do res[select(i, ...)] = true end
    return res
  end

  local space_chars  = create_set(" ", "\t", "\r", "\n")
  local delim_chars  = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
  local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
  local literals     = create_set("true", "false", "null")
  local literal_map  = { ["true"] = true, ["false"] = false, ["null"] = nil }

  local function next_char(str, idx, set, negate)
    for i = idx, #str do
      if set[str:sub(i, i)] ~= negate then return i end
    end
    return #str + 1
  end

  local function decode_error(str, idx, msg)
    local line_count, col_count = 1, 1
    for i = 1, idx - 1 do
      col_count = col_count + 1
      if str:sub(i, i) == "\n" then line_count, col_count = line_count + 1, 1 end
    end
    error(string.format("%s at line %d col %d", msg, line_count, col_count))
  end

  local function codepoint_to_utf8(n)
    local f = math.floor
    if n <= 0x7f then
      return string.char(n)
    elseif n <= 0x7ff then
      return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
      return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
      return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128,
        n % 64 + 128)
    end
    error(string.format("invalid unicode codepoint '%x'", n))
  end

  local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16)
    local n2 = tonumber(s:sub(7, 10), 16)
    if n2 then
      return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
      return codepoint_to_utf8(n1)
    end
  end

  local function parse_string(str, i)
    local res, j, k = "", i + 1, i + 1
    while j <= #str do
      local x = str:byte(j)
      if x < 32 then
        decode_error(str, j, "control character in string")
      elseif x == 92 then
        res = res .. str:sub(k, j - 1)
        j = j + 1
        local c = str:sub(j, j)
        if c == "u" then
          local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1) or
              str:match("^%x%x%x%x", j + 1) or
              decode_error(str, j - 1, "invalid unicode escape in string")
          res = res .. parse_unicode_escape(hex)
          j = j + #hex
        else
          if not escape_chars[c] then
            decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
          end
          res = res .. escape_char_map_inv[c]
        end
        k = j + 1
      elseif x == 34 then
        res = res .. str:sub(k, j - 1)
        return res, j + 1
      end
      j = j + 1
    end
    decode_error(str, i, "expected closing quote for string")
  end

  local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then decode_error(str, i, "invalid number '" .. s .. "'") end
    return n, x
  end

  local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then decode_error(str, i, "invalid literal '" .. word .. "'") end
    return literal_map[word], x
  end

  local function parse_array(str, i)
    local res, n = {}, 1
    i = i + 1
    while true do
      local x
      i = next_char(str, i, space_chars, true)
      if str:sub(i, i) == "]" then
        i = i + 1; break
      end
      x, i = parse(str, i)
      res[n] = x
      n = n + 1
      i = next_char(str, i, space_chars, true)
      local chr = str:sub(i, i)
      i = i + 1
      if chr == "]" then break end
      if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
    end
    return res, i
  end

  local function parse_object(str, i)
    local res = {}
    local keys = {}
    i = i + 1
    while true do
      local key, val
      i = next_char(str, i, space_chars, true)
      if str:sub(i, i) == "}" then
        i = i + 1; break
      end
      if str:sub(i, i) ~= '"' then decode_error(str, i, "expected string for key") end
      key, i = parse(str, i)
      i = next_char(str, i, space_chars, true)
      if str:sub(i, i) ~= ":" then decode_error(str, i, "expected ':' after key") end
      i = next_char(str, i + 1, space_chars, true)
      val, i = parse(str, i)
      res[key] = val
      table.insert(keys, key)
      i = next_char(str, i, space_chars, true)
      local chr = str:sub(i, i)
      i = i + 1
      if chr == "}" then break end
      if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
    end
    res.__order = keys
    return res, i
  end

  local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object,
  }

  parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then return f(str, idx) end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
  end

  function json.decode(str)
    if type(str) ~= "string" then error("expected string, got " .. type(str)) end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then decode_error(str, idx, "trailing garbage") end
    return res
  end

  return json
end)()

-------------------------------------------------------------------------------
-- 3. HELPER FUNCTIONS (FILES, STATUS, AND API CONFIGURATION)
-------------------------------------------------------------------------------

-- Function for safe atomic file writing (via a temporary file with subsequent replacement)
local function write_raw_file(filepath, content)
  local tmp_path = filepath .. ".tmp"
  local f = io.open(tmp_path, "w")
  if not f then return false end

  f:write(content)
  f:close()

  os.remove(filepath)
  local ok = os.rename(tmp_path, filepath)
  return ok ~= nil
end

-- Build a map of configuration files available for reading/editing via the API
local function get_allowed_files_map()
  local default_path = SKEEN_DIR .. DEFAULT_FILES.singbox
  local map = {
    ["skeen"]     = { path = SKEEN_DIR .. DEFAULT_FILES.skeen, type = "json", name = DEFAULT_FILES.skeen },
    ["pure_cidr"] = { path = SKEEN_DIR .. DEFAULT_FILES.pure_cidr, type = "text", name = DEFAULT_FILES.pure_cidr }
  }

  local cmd = get_skeen_cmd("get_singbox_config --json 2>/dev/null")
  local handle = io.popen(cmd)
  local result_str = handle and handle:read("*a") or ""
  if handle then handle:close() end

  local ok, cfg_info = pcall(json.decode, result_str)
  local path = (ok and cfg_info and cfg_info.path) or default_path
  local is_dir = (ok and cfg_info and cfg_info.is_dir) or false

  if is_dir then
    local files = {}
    local parent_dir = path:match("([^/]+)$") or "config"

    local handle_ls = io.popen(string.format("ls -1 %s 2>/dev/null", path))
    if handle_ls then
      for file in handle_ls:lines() do
        if file and file ~= "" and file:match("%.json$") then
          local full_path = path .. "/" .. file
          local f_check = io.open(full_path, "r")
          if f_check then
            f_check:close()
            table.insert(files, { path = full_path, name = parent_dir .. "/" .. file })
          end
        end
      end
      handle_ls:close()
    end

    table.sort(files, function(a, b) return a.name < b.name end)

    for idx, item in ipairs(files) do
      map["sb_file_" .. (idx - 1)] = { path = item.path, type = "json", name = item.name }
    end
  else
    local filename = path:match("([^/]+)$") or "config.json"
    map["singbox"] = { path = path, type = "json", name = filename }
  end

  return map
end

-- Get the device model from /proc/device-tree/model, or return "Unknown" if unavailable
local function get_device_model()
  local f = io.open("/proc/device-tree/model", "r")
  if not f then return "Unknown" end
  local model = f:read("*all")
  f:close()

  if model then
    -- Remove null bytes and trim whitespace from the model strings
    model = model:gsub("%z", ""):match("^%s*(.-)%s*$")
  end

  return (model and model ~= "") and model or "Unknown"
end

-- Cache for CPU delta calculation
local cpu_cache = { total = 0, idle = 0 }

-- Read and calculate CPU load percentage from /proc/stat
local function get_cpuload()
  local f = io.open("/proc/stat", "r")
  if not f then return 0 end
  local line = f:read("*line")
  f:close()

  if not line or not line:match("^cpu%s") then return 0 end

  local fields = {}
  for val in line:gmatch("%d+") do
    table.insert(fields, tonumber(val))
  end

  if #fields < 4 then return 0 end

  local total = 0
  for i = 1, #fields do
    total = total + fields[i]
  end
  local current_idle = fields[4] + fields[5]

  local cpuload = 0
  if cpu_cache.total > 0 then
    local dt = total - cpu_cache.total
    local di = current_idle - cpu_cache.idle
    if dt > 0 then
      cpuload = math.floor(100 * (dt - di) / dt + 0.5)
    end
  end

  cpu_cache.total = total
  cpu_cache.idle = current_idle

  return math.max(0, math.min(100, cpuload))
end

-- Get CPU temperature in Celsius (if available)
local function get_cpu_temp()
  local f = io.open("/sys/class/thermal/thermal_zone0/temp", "r")
  if not f then return nil end

  local temp_str = f:read("*all")
  f:close()

  local temp_c = tonumber(temp_str) or nil
  if temp_c then
    temp_c = math.floor(temp_c / 1000 + 0.5)
  end

  return temp_c
end

-- Resolve default network interface
local function get_default_interface()
  local handle = io.popen("ip route show default 2>/dev/null")
  if handle then
    local result = handle:read("*line")
    handle:close()
    if result then
      local iface = result:match("dev%s+(%S+)")
      if iface and iface ~= "" then
        return iface
      end
    end
  end
  return "br0"
end

-- Cache for network RX/TX speed calculation
local net_cache = { time = 0, rx = 0, tx = 0 }

-- Read RX/TX byte counters for a network interface
local function get_rtx_speed(iface)
  iface = iface or "br0"

  local function read_num(path)
    local f = io.open(path, "r")
    if not f then return 0 end
    local val = tonumber(f:read("*all"))
    f:close()
    return val or 0
  end

  local rx = read_num("/sys/class/net/" .. iface .. "/statistics/rx_bytes")
  local tx = read_num("/sys/class/net/" .. iface .. "/statistics/tx_bytes")
  local time_now = os.time()

  local rx_speed, tx_speed = 0, 0

  if net_cache.time > 0 then
    local dt = time_now - net_cache.time
    if dt <= 0 then dt = 1 end

    if rx >= net_cache.rx and tx >= net_cache.tx then
      rx_speed = math.floor((rx - net_cache.rx) / dt)
      tx_speed = math.floor((tx - net_cache.tx) / dt)
    end
  end

  net_cache.time = time_now
  net_cache.rx = rx
  net_cache.tx = tx

  return rx_speed, tx_speed
end

-- Get active netfilter connection tracking count
local function get_connections_count()
  local f = io.open("/proc/net/nf_conntrack", "r")
  if not f then return 0 end

  local count = 0
  for _ in f:lines() do
    count = count + 1
  end
  f:close()
  return count
end

-- Get system uptime in seconds
local function get_sys_uptime()
  local f = io.open("/proc/uptime", "r")
  if not f then return 0 end
  local line = f:read("*line")
  f:close()

  if not line then return 0 end

  local uptime_sec = math.floor(tonumber(line:match("^(%S+)")) or 0)
  return uptime_sec or 0
end


-- Get the number of CPU cores from /proc/cpuinfo
local function get_cpu_cores()
  local count = 0
  local f = io.open("/proc/cpuinfo", "r")
  if f then
    for line in f:lines() do
      if line:match("^processor") then
        count = count + 1
      end
    end
    f:close()
  end
  return count > 0 and count or 1
end

local cpu_cores = get_cpu_cores()

-- Get system load averages (1, 5, 15 minutes in percentage of CPU cores)
local function get_loadavg_pct()
  local f = io.open("/proc/loadavg", "r")
  if not f then return 0, 0, 0 end
  local line = f:read("*line")
  f:close()

  if not line then return 0, 0, 0 end

  local l1, l2, l3 = line:match("^(%S+)%s+(%S+)%s+(%S+)")
  if not l1 then return 0, 0, 0 end

  local pct1 = math.floor(((tonumber(l1) or 0) / cpu_cores) * 100 + 0.5)
  local pct2 = math.floor(((tonumber(l2) or 0) / cpu_cores) * 100 + 0.5)
  local pct3 = math.floor(((tonumber(l3) or 0) / cpu_cores) * 100 + 0.5)

  return pct1, pct2, pct3
end

-- Get system RAM usage (in kB)
local function get_memory_info()
  local f = io.open("/proc/meminfo", "r")
  if not f then return 0, 0 end
  local content = f:read("*all")
  f:close()

  local total = tonumber(content:match("MemTotal:%s+(%d+)")) or 0
  local available = tonumber(content:match("MemAvailable:%s+(%d+)")) or 0
  local used = total - available
  if used < 0 then used = 0 end

  return used, total
end

-- Get SWAP memory usage (in kB)
local function get_swap_info()
  local f = io.open("/proc/swaps", "r")
  if not f then return 0, 0 end

  local used_total, size_total = 0, 0
  local header = true
  for line in f:lines() do
    if header then
      header = false
    else
      local _, _, size, used = line:match("(%S+)%s+(%S+)%s+(%d+)%s+(%d+)")
      if size and used then
        size_total = size_total + tonumber(size)
        used_total = used_total + tonumber(used)
      end
    end
  end
  f:close()
  return used_total, size_total
end

-- Retrieve /opt disk usage information in kilobytes (KB)
local function get_opt_disk_info()
  -- Execute df command for /opt with 1K blocks, suppressing errors
  local handle = io.popen("df -k /opt 2>/dev/null")
  if not handle then return 0, 0 end

  local output = handle:read("*all")
  handle:close()

  -- Split the command output into lines
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  -- Parse the data line (skipping the header)
  if #lines >= 2 then
    -- Extract total KB and used KB from the second line
    local total_kb, used_kb = lines[2]:match("^%S+%s+(%d+)%s+(%d+)")
    if total_kb and used_kb then
      return tonumber(used_kb) or 0, tonumber(total_kb) or 0
    end
  end

  return 0, 0
end

-- Get the real working status of SKeen
local function get_skeen_status()
  -- Resolve command line targeting memory-cached local script or fallback to global CLI
  local cmd = get_skeen_cmd("status --json 2>&1")

  local handle = io.popen(cmd)
  local out = ""
  if handle then
    out = handle:read("*a") or ""
    handle:close()
  end

  local success, data = pcall(json.decode, out)
  if success and type(data) == "table" then
    data.__order = nil
    return data
  end

  -- Safe default value in case status retrieval fails
  return {
    running = false,
    version = "unknown",
    mode = "unknown",
    sb_version = "unknown"
  }
end

-- Cache for SKeen status to reduce router CPU load during frequent requests
local skeen_status_cache = { data = nil, expire = 0 }

-- Return cached SKeen service status, refreshing when stale
local function get_cached_skeen_status()
  local now = os.time()
  if skeen_status_cache.data and now < skeen_status_cache.expire then
    return skeen_status_cache.data
  end

  -- Retrieve base status from SKeen CLI / memory script
  local st = get_skeen_status()

  st.api_version = VERSION

  skeen_status_cache.data = st
  skeen_status_cache.expire = now + 3 -- Cache the result for 3 seconds
  return st
end

-- Cache for System status to reduce router CPU load during frequent requests
local system_status_cache = { data = nil, expire = 0 }

-- Return cached system status, refreshing when stale
local function get_cached_system_status()
  local now = os.time()
  if system_status_cache.data and now < system_status_cache.expire then
    return system_status_cache.data
  end

  -- Collect system metrics with safety fallbacks
  local def_iface = get_default_interface() or "br0"
  local rx_sp, tx_sp = get_rtx_speed(def_iface)
  local mem_used, mem_total = get_memory_info()
  local swap_used, swap_total = get_swap_info()
  local opt_used, opt_total = get_opt_disk_info()

  local sys_st = {
    device     = get_device_model() or "Unknown",
    cpu_load   = get_cpuload() or 0,
    cpu_temp   = get_cpu_temp() or 0,
    mem_used   = mem_used or 0,
    mem_total  = mem_total or 0,
    swap_used  = swap_used or 0,
    swap_total = swap_total or 0,
    opt_used   = opt_used or 0,
    opt_total  = opt_total or 0,
    uptime     = get_sys_uptime() or 0,
    loadavg    = { get_loadavg_pct() },
    def_iface  = def_iface,
    rx_speed   = rx_sp or 0,
    tx_speed   = tx_sp or 0,
    conn_cnt   = get_connections_count() or 0
  }

  -- Cache the enriched result for 2 seconds to reduce CPU overhead
  system_status_cache.data = sys_st
  system_status_cache.expire = now + 2
  return sys_st
end

-- Load the configuration of the API server itself (port, secret key, CORS, and rate limit)
local function load_api_config()
  local cmd = get_skeen_cmd("get_api_config 2>&1")
  local handle = io.popen(cmd)
  local out = ""
  if handle then
    out = handle:read("*a") or ""
    handle:close()
  end

  local success, data = pcall(json.decode, out)
  if success and type(data) == "table" then
    return data
  end

  return {
    port = 3000,
    secret = "",
    cors_origin = { "*" },
    dashboard = 1
  }
end

-- Match incoming Origin header against allowed CORS policies
local function get_matched_cors(request_origin, allowed_config)
  if not allowed_config then return "" end

  if type(allowed_config) == "string" then
    return allowed_config
  end

  if type(allowed_config) == "table" then
    for _, allowed in ipairs(allowed_config) do
      if allowed == "*" then
        return "*"
      end
      if request_origin and allowed == request_origin then
        return request_origin
      end
    end
    return ""
  end

  return ""
end

-------------------------------------------------------------------------------
-- 4. MAIN SERVER LOOP
-------------------------------------------------------------------------------

local api_config = load_api_config()

local PORT = tonumber(api_config.port) or 3000
local SECRET = api_config.secret or ""
local DASHBOARD = (api_config.dashboard == 1)

local MAX_BODY_SIZE = 1024 * 1024 -- Hard limit for incoming HTTP request body size: 1 MB
local MAX_HEADERS_COUNT = 50      -- Maximum allowed number of header lines
-- Rate limits: 100 req/min for authorized clients, 5 req/min for unauthorized ones
local RATE_LIMIT_AUTH = 100
local RATE_LIMIT_UNAUTH = 5
local RATE_LIMIT_WINDOW = 60

-- The build script replaces the placeholder during packaging.
local EMBEDDED_HTML_GZIP

if DASHBOARD then
  -- The build script replaces the placeholder with the compressed HTML during packaging.
  ---@type string?
  local EMBEDDED_HTML_GZIP_BASE64 = "__HTML_GZIP_PLACEHOLDER__"

  -- Decode the embedded dashboard and release the Base64 string.
  EMBEDDED_HTML_GZIP = assert(
    base64_decode(EMBEDDED_HTML_GZIP_BASE64)
  )
  EMBEDDED_HTML_GZIP_BASE64 = nil
end

-- Create a new rate limiter bucket with the given per-minute limit
local function new_limiter(limit)
  return { limit = limit, window = RATE_LIMIT_WINDOW, reqs = {}, head = 1, tail = 0 }
end

local rate_limit_auth = new_limiter(RATE_LIMIT_AUTH)
local rate_limit_unauth = new_limiter(RATE_LIMIT_UNAUTH)

-- Preliminary check: whether the port is already occupied by another process
local check_cmd = string.format("netstat -tuln 2>/dev/null | grep -q ':%d'", PORT)
if os.execute(check_cmd) == 0 then
  io.stderr:write(string.format("[ERROR] Port %d is already in use by another process!\n", PORT))
  os.exit(1)
end

-- Bind the socket to the interface and port
local server = assert(socket.bind("0.0.0.0", PORT))
print("API server started on port " .. PORT)

-- Encode data as JSON and return body, status and content type
local function json_response(data, status)
  return json.encode(data), status or "200 OK", "application/json"
end

-- Send a fully formed HTTP response, optionally including Retry-After header
local function send_http_response(client, response_body, status, content_type, current_cors,
                                  retry_after,
                                  extra_headers)
  client:send("HTTP/1.1 " .. status .. "\r\n")
  if current_cors ~= "" then
    client:send("Access-Control-Allow-Origin: " .. current_cors .. "\r\n")
    client:send("Vary: Origin\r\n")
  end
  client:send("Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n")
  client:send("Access-Control-Allow-Headers: X-API-Key, Content-Type\r\n")
  client:send("X-Content-Type-Options: nosniff\r\n")
  client:send("X-Frame-Options: SAMEORIGIN\r\n")
  client:send("Content-Type: " .. content_type .. "\r\n")
  if extra_headers then
    for name, value in pairs(extra_headers) do
      client:send(name .. ": " .. value .. "\r\n")
    end
  end
  client:send("Cache-Control: no-store, no-cache, must-revalidate\r\n")
  client:send("Content-Length: " .. #response_body .. "\r\n")
  if retry_after then
    client:send("Retry-After: " .. retry_after .. "\r\n")
    client:send("Access-Control-Expose-Headers: Retry-After\r\n")
  end
  client:send("Connection: close\r\n\r\n")
  client:send(response_body)
end

-- Consume one request from the given limiter bucket; returns false and retry-after when exceeded
local function consume_rate_limit(limiter, now)
  local reqs = limiter.reqs
  while limiter.head <= limiter.tail and
    reqs[limiter.head] <= now - limiter.window do
    reqs[limiter.head] = nil
    limiter.head = limiter.head + 1
  end

  local request_count = limiter.tail - limiter.head + 1
  if request_count >= limiter.limit then
    return false, math.max(1, reqs[limiter.head] + limiter.window - now)
  end

  limiter.tail = limiter.tail + 1
  reqs[limiter.tail] = now

  if limiter.head > limiter.limit then
    local active_requests = {}
    for index = limiter.head, limiter.tail do
      active_requests[#active_requests + 1] = reqs[index]
    end
    limiter.reqs = active_requests
    limiter.head = 1
    limiter.tail = #active_requests
  end

  return true
end

-- Handle file read/write API requests
local function handle_file_request(method, path, body)
  if method == "GET" then
    local file_key = path:match("[?&]name=([^&]+)") or "skeen"
    local target = get_allowed_files_map()[file_key]
    if not target then
      return json_response({ error = "Invalid file target" }, "400 Bad Request")
    end

    local content = read_file(target.path) or ""
    if target.type == "json" then
      if file_key == "skeen" then
        content = strip_json_comments(content)
        local success, data = pcall(json.decode, content)
        return json_response({ success = true, content = success and data or {} })
      end
      return '{"success":true,"content":' .. content .. '}', "200 OK", "application/json"
    end

    local escaped_content = content:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub(
      '\r', '\\r')
    return '{"success":true,"content":"' .. escaped_content .. '"}', "200 OK", "application/json"
  end

  local success, req_json = pcall(json.decode, body)
  local file_key = req_json and req_json.name
  local target = get_allowed_files_map()[file_key]
  if not success or not target then
    return json_response({ error = "Invalid request or file target" }, "400 Bad Request")
  end

  local write_success = false
  if target.type == "json" then
    local ok_enc, encoded_json = pcall(json.encode, req_json.content, true)
    if ok_enc then
      write_success = write_raw_file(target.path, encoded_json)
    end
  else
    write_success = write_raw_file(target.path, tostring(req_json.content))
  end

  if write_success then
    return json_response({ success = true, message = "File updated" })
  end
  return json_response({ error = "Failed to write file" }, "500 Internal Server Error")
end

-- Handle command execution API requests
local function handle_exec_request(body)
  local success, req_json = pcall(json.decode, body)
  local param = ""
  if success and type(req_json) == "table" and req_json.param then
    param = tostring(req_json.param)
  end

  if not success or type(req_json) ~= "table" or not is_allowed_param(param) then
    return json_response({ error = "Invalid or unauthorized parameter" }, "400 Bad Request")
  end

  local response_data
  if param == "areload" then
    -- Restart in the background so the current request can return first.
    os.execute('(sleep 2 && "' .. SCRIPT .. '" restart) >/dev/null 2>&1 &')
    response_data = {
      success = true,
      stdout = "API reload initiated, restarting in 2 seconds..."
    }
  elseif param == "aupdate" then
    local log_buffer = {}
    local old_print = _G.print
    _G.print = function(...)
      table.insert(log_buffer, table.concat({ ... }, "\t"))
    end

    local success_pcall, did_update = pcall(update_script)
    _G.print = old_print

    local result = table.concat(log_buffer, "\n")
    if not success_pcall then
      result = result .. "\nError: " .. tostring(did_update)
    end
    if success_pcall and did_update == true then
      os.execute('(sleep 2 && "' .. SCRIPT .. '" restart) >/dev/null 2>&1 &')
    end

    response_data = {
      success = success_pcall,
      updated = success_pcall and did_update == true,
      stdout = result ~= "" and result or ""
    }
  else
    local command_args = param
    local sync_url = param:match("^sync%s+(https?://.+)$")
    if sync_url then
      command_args = "sync " .. shell_quote(sync_url)
    end
    local cmd = "FORCE_COLOR=1 " .. get_skeen_cmd(command_args)

    local actions = { start = true, stop = true, restart = true, reload = true, kill = true }
    if actions[param] then
      skeen_status_cache.expire = 0
    end

    local handle = io.popen(cmd .. " 2>&1")
    local stdout = ""
    if handle then
      stdout = handle:read("*a")
      handle:close()
    else
      stdout = "Error: failed to open process"
    end
    response_data = { success = true, stdout = stdout }
  end

  return json_response(response_data)
end

-- Route an incoming HTTP request to the appropriate handler
local function route_request(method, path, body, request_headers)
  -- DEBUG: Print incoming HTTP request headers.
  -- for name, value in pairs(request_headers or {}) do
  --   print("HTTP Header: " .. name .. " = " .. tostring(value))
  -- end

  if path == "/" then
    if DASHBOARD then
      -- Development mode: prefer the local dashboard file.
      if DEVELOPMENT then
        local dashboard_html = get_dashboard_html()
        if dashboard_html then
          return dashboard_html, "200 OK", "text/html; charset=utf-8"
        end
      end

      -- Production mode: serve the embedded gzip dashboard.
      if accepts_gzip(request_headers and request_headers["accept-encoding"]) then
        return EMBEDDED_HTML_GZIP, "200 OK", "text/html; charset=utf-8", {
          ["Content-Encoding"] = "gzip",
          ["Vary"] = "Accept-Encoding"
        }
      end

      return "This dashboard requires a client that supports gzip content encoding.",
          "406 Not Acceptable", "text/plain; charset=utf-8", {
            ["Vary"] = "Accept-Encoding"
          }
    end

    return json_response({ error = "Not found" }, "404 Not Found")
  elseif path == "/api/ping" and method == "GET" then
    return json_response({ status = "ok", message = "pong" })
  elseif path == "/api/dash" and method == "GET" then
    local cmd = get_skeen_cmd("dash --json 2>/dev/null")
    local handle = io.popen(cmd)
    local out = handle and handle:read("*a") or "[]"
    if handle then handle:close() end
    local success, data = pcall(json.decode, out)
    if success and type(data) == "table" then
      return json_response({ success = true, data = data })
    end
    return json_response({ success = false, data = {} })
  elseif path:find("^/api/status") and method == "GET" then
    local status = get_cached_skeen_status()
    status.success = true
    return json_response(status)
  elseif path:find("^/api/system/status") and method == "GET" then
    local status = get_cached_system_status()
    status.success = true
    return json_response(status)
  elseif path == "/api/files-list" and method == "GET" then
    local files_list = {}
    for id, target in pairs(get_allowed_files_map()) do
      table.insert(files_list, { id = id, name = target.name })
    end
    table.sort(files_list, function(a, b) return a.id < b.id end)
    return json_response(files_list)
  elseif (path:find("^/api/file") and method == "GET") or
      (path == "/api/file" and method == "POST") then
    return handle_file_request(method, path, body)
  elseif path == "/api/exec" and method == "POST" then
    return handle_exec_request(body)
  end

  return json_response({ error = "Not found" }, "404 Not Found")
end

-- Function for safely processing an individual client connection
local function handle_client(client)
  client:settimeout(30) -- Set a 30-second timeout on socket operations

  -- Read the first line of the HTTP request (request line: method and path)
  local request = client:receive("*l")
  if not request then return end

  local method, path = request:match("^(%a+)%s+(%S+)")
  if not method or not path then
    client:send("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n")
    return
  end

  local headers = {}
  local headers_count = 0

  -- Read headers line by line with protection against Slowloris attacks (line count limit)
  while true do
    local line = client:receive("*l")
    if not line or line == "" then break end

    headers_count = headers_count + 1
    if headers_count > MAX_HEADERS_COUNT then
      client:send("HTTP/1.1 431 Request Header Fields Too Large\r\nConnection: close\r\n\r\n")
      return
    end

    local key, value = line:match("^([^:]+):%s*(.*)$")
    if key then headers[key:lower()] = value end
  end

  -- Handle CORS policies based on the Origin header
  local req_origin = headers["origin"]
  local current_cors = get_matched_cors(req_origin, api_config.cors_origin)

  -- Preflight OPTIONS request
  if method == "OPTIONS" then
    client:send("HTTP/1.1 204 No Content\r\n")
    if current_cors ~= "" then
      client:send("Access-Control-Allow-Origin: " .. current_cors .. "\r\n")
      client:send("Vary: Origin\r\n")
    end
    client:send("Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n")
    client:send("Access-Control-Allow-Headers: X-API-Key, Content-Type\r\n")
    client:send("X-Content-Type-Options: nosniff\r\n")
    client:send("X-Frame-Options: SAMEORIGIN\r\n")
    client:send("Connection: close\r\n\r\n")
    return
  end

  -- Apply a separate rolling rate limit depending on authorization status
  if path:find("^/api/") then
    local is_authorized = true
    if SECRET ~= "" then
      is_authorized = headers["x-api-key"] == SECRET
    end
    local limiter = is_authorized and rate_limit_auth or rate_limit_unauth
    local allowed, retry_after = consume_rate_limit(limiter, os.time())
    if not allowed then
      local response_body, status, content_type =
          json_response({ error = "Too many requests" }, "429 Too Many Requests")
      send_http_response(client, response_body, status, content_type, current_cors, retry_after)
      return
    end
  end

  -- Read the request body (if present) with a preliminary hard size limit check
  local body = ""
  local content_length = tonumber(headers["content-length"] or 0)
  if content_length > 0 then
    if content_length > MAX_BODY_SIZE then
      client:send("HTTP/1.1 413 Payload Too Large\r\nConnection: close\r\n\r\n")
      return
    end

    body = client:receive(content_length)
    if not body or #body < content_length then
      client:send("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n")
      return
    end
  end

  local response_body, status, content_type, extra_headers
  local authorized = true

  -- Keep the configured optional-auth behavior for API routes.
  if SECRET ~= "" and path:find("^/api/") then
    authorized = headers["x-api-key"] == SECRET
  end

  if authorized then
    response_body, status, content_type, extra_headers = route_request(method, path, body, headers)
  else
    response_body, status, content_type =
        json_response({ error = "Unauthorized: Invalid or missing API key" }, "401 Unauthorized")
  end

  send_http_response(client, response_body, status, content_type, current_cors, nil, extra_headers)
end

-- Infinite main server loop to accept incoming connections
while true do
  local client = server:accept()
  if client then
    -- Protected client processing execution via pcall with guaranteed socket closure
    pcall(handle_client, client)
    client:close()
  end
end

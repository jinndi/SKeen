#!/opt/bin/lua

local socket = require("socket")

-------------------------------------------------------------------------------
-- 0. VERSION AND COMMAND LINE ARGUMENT (CLI) HANDLING
-------------------------------------------------------------------------------
local VERSION = "1.0.3"
local SCRIPT = "/opt/bin/skeen-api"
local LUA_BIN = "/opt/bin/lua"
local PID_FILE = "/tmp/run/skeen-api.pid"
local REPO_BASE_URL = "https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/static/"
local VERSION_URL = REPO_BASE_URL .. "api-version"
local SCRIPT_URL = REPO_BASE_URL .. "skeen-api"

-- Function for safely escaping arguments to pass them into the command line
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
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

  local ticks_file = io.popen("getconf CLK_TCK 2>/dev/null")
  local ticks = ticks_file and tonumber(ticks_file:read("*l"))

  if ticks_file then
    ticks_file:close()
  end

  ticks = ticks or 100

  return math.max(0, math.floor(uptime - start_ticks / ticks))
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

-- Embedded control panel HTML template (replaced during package build/packing)
local EMBEDDED_HTML = [==[__HTML_PLACEHOLDER__]==]

-- Determine the source of the panel HTML (in development mode, read from disk; in production, use the embedded template)
local SCRIPT_PATH = arg[0]
local SCRIPT_DIR = SCRIPT_PATH:match("^(.*)/[^/]+$") or "."

local function get_dashboard_html()
  local f = io.open(SCRIPT_DIR .. "/index.html", "r")
  if f then
    local content = f:read("*all")
    f:close()
    return content
  end
  return EMBEDDED_HTML
end

-- Strict security check: validation of allowed SKeen CLI command line parameters
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
    ["help"]     = true,
    ["iface"]    = true,
    ["connstat"] = true,
    ["update"]   = false,
    ["test"]     = true,
    ["deps"]     = true,
    ["check"]    = true,
    ["format"]   = true,
    ["api"]      = false,
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
  if param:match("^sync%s+https?://[%w%-_%.%:/%?&=]+$") then return true end
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

  local handle = io.popen("skeen get_singbox_config --json 2>/dev/null")
  local result_str = handle and handle:read("*a") or ""
  if handle then handle:close() end

  local ok, cfg_info = pcall(json.decode, result_str)
  local path = (ok and cfg_info and cfg_info.path) or default_path
  local is_dir = (ok and cfg_info and cfg_info.is_dir) or false

  if is_dir then
    local safe_path = path:gsub("'", "'\\''")
    local cmd = string.format("find '%s' -maxdepth 1 -name '*.json' | sort", safe_path)

    local p_find = io.popen(cmd)
    if p_find then
      local idx = 0
      for file_full_path in p_find:lines() do
        if file_full_path ~= "" then
          local parent, filename = file_full_path:match("([^/]+)/([^/]+)$")
          local display_name = (parent and filename) and (parent .. "/" .. filename) or
              (file_full_path:match("^.+/(.+)$") or file_full_path)

          map["sb_file_" .. idx] = { path = file_full_path, type = "json", name = display_name }
          idx = idx + 1
        end
      end
      p_find:close()
    end
  else
    local filename = path:match("^.+/(.+)$") or "config.json"
    map["singbox"] = { path = path, type = "json", name = filename }
  end

  return map
end

-- Get the real working status of SKeen by invoking the CLI utility
local function get_skeen_status()
  local handle = io.popen("skeen status --json 2>&1")
  local out = ""
  if handle then
    out = handle:read("*a") or ""
    handle:close()
  end

  local success, data = pcall(json.decode, out)
  if success and type(data) == "table" then
    data.success = true
    data.api_version = VERSION
    data.__order = nil
    return data
  end

  -- Safe default value in case status retrieval fails
  return {
    success = false,
    running = false,
    version = "unknown",
    mode = "unknown",
    sb_version = "unknown",
    api_version = VERSION
  }
end

-- Cache for SKeen status to reduce router CPU load during frequent requests
local status_cache = { data = nil, expire = 0 }

local function get_cached_skeen_status()
  local now = os.time()
  if status_cache.data and now < status_cache.expire then
    return status_cache.data
  end

  local st = get_skeen_status()
  status_cache.data = st
  status_cache.expire = now + 3 -- Cache the result for 3 seconds
  return st
end

-- Load the configuration of the API server itself (port, secret key, CORS)
local function load_api_config()
  local handle = io.popen("skeen get_api_config 2>&1")
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

-- Preliminary check: whether the port is already occupied by another process
local check_cmd = string.format("netstat -tuln 2>/dev/null | grep -q ':%d'", PORT)
if os.execute(check_cmd) == 0 then
  io.stderr:write(string.format("[ERROR] Port %d is already in use by another process!\n", PORT))
  os.exit(1)
end

-- Bind the socket to the interface and port
local server = assert(socket.bind("0.0.0.0", PORT))
print("API server started on port " .. PORT)

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

  local response_body, status, content_type
  local authorized = true

  -- Check for the presence and validity of the secret API key for paths starting with /api/
  if SECRET ~= "" and path:find("^/api/") then
    local client_key = headers["x-api-key"]
    if client_key ~= SECRET then authorized = false end
  end

  if not authorized then
    response_body = json.encode({ error = "Unauthorized: Invalid or missing API key" })
    status = "401 Unauthorized"
    content_type = "application/json"
  else
    -- API request routing
    if path == "/" then
      if DASHBOARD then
        response_body = get_dashboard_html()
        status = "200 OK"
        content_type = "text/html; charset=utf-8"
      else
        response_body = json.encode({ error = "Not found" })
        status = "404 Not Found"
        content_type = "application/json"
      end
    elseif path == "/api/ping" and method == "GET" then
      response_body = json.encode({ status = "ok", message = "pong" })
      status = "200 OK"
      content_type = "application/json"
    elseif path:find("^/api/status") and method == "GET" then
      local st = get_cached_skeen_status()
      st.success = true
      response_body = json.encode(st)
      status = "200 OK"
      content_type = "application/json"
    elseif path == "/api/files-list" and method == "GET" then
      local map = get_allowed_files_map()
      local files_list = {}

      for id, target in pairs(map) do
        table.insert(files_list, { id = id, name = target.name })
      end

      table.sort(files_list, function(a, b) return a.id < b.id end)
      response_body = json.encode(files_list)
      status = "200 OK"
      content_type = "application/json"
    elseif path:find("^/api/file") and method == "GET" then
      local file_key = path:match("[?&]name=([^&]+)") or "skeen"
      local ALLOWED_FILES = get_allowed_files_map()
      local target = ALLOWED_FILES[file_key]

      if not target then
        response_body = json.encode({ error = "Invalid file target" })
        status = "400 Bad Request"
        content_type = "application/json"
      else
        local f = io.open(target.path, "r")
        local content = ""
        if f then
          content = f:read("*a")
          f:close()
        end

        if target.type == "json" then
          if file_key == "skeen" then
            content = strip_json_comments(content)
            local success, data = pcall(json.decode, content)
            response_body = json.encode({ success = true, content = success and data or {} })
          else
            response_body = '{"success":true,"content":' .. content .. '}'
          end
        else
          local escaped_content = content:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub(
            '\r', '\\r')
          response_body = '{"success":true,"content":"' .. escaped_content .. '"}'
        end
        status = "200 OK"
        content_type = "application/json"
      end
    elseif path == "/api/file" and method == "POST" then
      local success, req_json = pcall(json.decode, body)
      local file_key = req_json and req_json.name
      local ALLOWED_FILES = get_allowed_files_map()
      local target = ALLOWED_FILES[file_key]

      if not success or not target then
        response_body = json.encode({ error = "Invalid request or file target" })
        status = "400 Bad Request"
        content_type = "application/json"
      else
        local raw_content = req_json.content
        local write_success = false

        if target.type == "json" then
          local ok_enc, encoded_json = pcall(json.encode, raw_content, true)
          if ok_enc then
            write_success = write_raw_file(target.path, encoded_json)
          end
        else
          write_success = write_raw_file(target.path, tostring(raw_content))
        end

        if write_success then
          response_body = json.encode({ success = true, message = "File updated" })
          status = "200 OK"
        else
          response_body = json.encode({ error = "Failed to write file" })
          status = "500 Internal Server Error"
        end
        content_type = "application/json"
      end
    elseif path == "/api/exec" and method == "POST" then
      local success, req_json = pcall(json.decode, body)
      local param = ""
      if success and type(req_json) == "table" and req_json.param then
        param = tostring(req_json.param)
      end

      local response_data
      if success and type(req_json) == "table" and is_allowed_param(param) then
        if param == "areload" then
          -- Restart is executed in the background with a 2-second delay
          -- so that the current HTTP request has time to return a 200 OK status to the browser
          os.execute('(sleep 2 && "' .. SCRIPT .. '" restart) >/dev/null 2>&1 &')
          response_data = {
            success = true,
            stdout = "API reload initiated, restarting in 2 seconds..."
          }
        elseif param == "aupdate" then
          local log_buffer = {}

          -- Intercept print to collect all function output into an array
          local old_print = _G.print
          _G.print = function(...)
            table.insert(log_buffer, table.concat({...}, "\t"))
          end

          -- Safely call the update function via pcall (to prevent crashing the server on error)
          local success_pcall, did_update = pcall(update_script)

          -- Restore the standard print
          _G.print = old_print

          local result = table.concat(log_buffer, "\n")
          if not success_pcall then
            result = result .. "\nError: " .. tostring(did_update)
          end

          -- If everything succeeded, schedule a restart
          if success_pcall and did_update == true then
            os.execute('(sleep 2 && "' .. SCRIPT .. '" restart) >/dev/null 2>&1 &')
          end

          response_data = {
            success = success_pcall,
            stdout = result ~= "" and result or ""
          }
        else
          local command = "FORCE_COLOR=1 skeen " .. param
          local handle = io.popen(command .. " 2>&1")
          local stdout = ""
          if handle then
            stdout = handle:read("*a")
            handle:close()
          else
            stdout = "Error: failed to open process"
          end
          response_data = { success = true, stdout = stdout }
        end
        status = "200 OK"
      else
        response_data = { error = "Invalid or unauthorized parameter" }
        status = "400 Bad Request"
      end
      response_body = json.encode(response_data)
      content_type = "application/json"
    else
      response_body = json.encode({ error = "Not found" })
      status = "404 Not Found"
      content_type = "application/json"
    end
  end

  -- Form and send the HTTP response to the client
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
  client:send("Content-Length: " .. string.len(response_body) .. "\r\n")
  client:send("Connection: close\r\n\r\n")
  client:send(response_body)
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

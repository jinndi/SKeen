#!/opt/bin/lua

local socket = require("socket")

-------------------------------------------------------------------------------
-- 0. VERSION & CLI ARGUMENTS HANDLING
-------------------------------------------------------------------------------
local VERSION = "1.0.0"

-- Check for version flag passed via console (e.g., skeen-api version or -v)
for _, v in ipairs(arg or {}) do
  if v == "version" or v == "-v" then
    print("v" .. VERSION)
    os.exit(0)
  end
end

-------------------------------------------------------------------------------
-- 1. CONSTANTS & CONFIGURATION DEFAULTS
-------------------------------------------------------------------------------

-- Base path to configuration directory
local SKEEN_DIR = "/opt/etc/skeen/"

-- Default configuration file names
local DEFAULT_FILES = {
  skeen     = "skeen.json",
  singbox   = "config.json",
  pure_cidr = "pure_cidr.list"
}

-- Embedded HTML placeholder substituted during build/packaging
local EMBEDDED_HTML = [==[__HTML_PLACEHOLDER__]==]

-- Determines dashboard HTML source (Development mode reads from disk, Production uses embedded payload)
local function get_dashboard_html()
  local f = io.open("index.html", "r")
  if f then
    local content = f:read("*all")
    f:close()
    return content
  end
  return EMBEDDED_HTML
end

-- Validates allowed SKeen CLI command parameters securely
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
    ["headers"]  = true
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
-- 2. JSON MODULE (KEY ORDERING, COMMENT STRIPPING, & FORMATTING)
-------------------------------------------------------------------------------
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
      return "[" .. newline .. table.concat(res, comma_sep) .. newline .. (pretty and indent or "") .. "]"
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
          table.insert(res, (pretty and next_indent or "") .. encoded_key .. ":" .. space .. encoded_val)
        end
      end
      stack[val] = nil
      if #res == 0 then return "{}" end
      return "{" .. newline .. table.concat(res, comma_sep) .. newline .. (pretty and indent or "") .. "}"
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
      return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
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
-- 3. UTILITY HELPERS (FILES, STATUS, & API CONFIGURATION)
-------------------------------------------------------------------------------

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

local function is_directory(path)
  if not path then return false end
  local p = io.popen(string.format("[ -d '%s' ] && echo 'yes' || echo 'no'", path:gsub("'", "'\\''")))
  if not p then return false end
  local res = p:read("*l")
  p:close()
  return res == "yes"
end

local function resolve_path(path)
  if not path then return "" end
  if path:match("^/") then
    return path
  else
    return SKEEN_DIR .. path
  end
end

local function get_allowed_files_map()
  local skeen_path = resolve_path(DEFAULT_FILES.skeen)
  local map = {
    ["skeen"] = { path = skeen_path, type = "json" }
  }

  local pure_cidr_path = resolve_path(DEFAULT_FILES.pure_cidr)
  local sb_cfg_path = resolve_path(DEFAULT_FILES.singbox)

  local f = io.open(skeen_path, "r")
  if f then
    local content = f:read("*a")
    f:close()
    content = strip_json_comments(content)
    local ok, skeen_config = pcall(json.decode, content)
    if ok and skeen_config then
      if skeen_config.firewall and skeen_config.firewall.intercept and
          skeen_config.firewall.intercept.fakeip and
          skeen_config.firewall.intercept.fakeip.include then
        local inc = skeen_config.firewall.intercept.fakeip.include
        if inc ~= "" and not inc:match("%${") then
          pure_cidr_path = resolve_path(inc)
        end
      end

      if skeen_config.singbox then
        local sb = skeen_config.singbox
        local cfg_path = DEFAULT_FILES.singbox

        if sb.config and sb.config.path and sb.config.path ~= "" then
          cfg_path = sb.config.path
        end

        if sb.external and sb.external.enabled == 1 and sb.external.config and sb.external.config.path and sb.external.config.path ~= "" then
          cfg_path = sb.external.config.path
        end

        if not cfg_path:match("%${") then
          sb_cfg_path = resolve_path(cfg_path)
        end
      end
    end
  end

  map["pure_cidr"] = { path = pure_cidr_path, type = "text" }

  if is_directory(sb_cfg_path) then
    local p_find = io.popen(string.format("find '%s' -maxdepth 2 -name '*.json' | sort", sb_cfg_path:gsub("'", "'\\''")))
    if p_find then
      local idx = 0
      for file_full_path in p_find:lines() do
        local key = "sb_file_" .. idx
        map[key] = { path = file_full_path, type = "json" }
        idx = idx + 1
      end
      p_find:close()
    end
  else
    map["singbox"] = { path = sb_cfg_path, type = "json" }
  end

  return map
end

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

  -- Safe fallback option on failure
  return {
    success = false,
    running = false,
    version = "unknown",
    mode = "unknown",
    sb_version = "unknown",
    api_version = VERSION
  }
end

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

local check_cmd = string.format("netstat -tuln 2>/dev/null | grep -q ':%d'", PORT)
if os.execute(check_cmd) == 0 then
  io.stderr:write(string.format("Error: Port %d is already in use by another process!\n", PORT))
  os.exit(1)
end

local server = assert(socket.bind("0.0.0.0", PORT))
print("API server started on port " .. PORT)

while true do
  local client = server:accept()
  client:settimeout(10)

  local request = client:receive("*l")
  if request then
    local method, path = request:match("^(%a+)%s+(%S+)")

    if not method or not path then
      client:send("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n")
    else
      local headers = {}
      while true do
        local line = client:receive("*l")
        if not line or line == "" then break end
        local key, value = line:match("^([^:]+):%s*(.*)$")
        if key then headers[key:lower()] = value end
      end

      local body = ""
      local content_length = tonumber(headers["content-length"] or 0)
      if content_length > 0 then
        body = client:receive(content_length)
      end

      local req_origin = headers["origin"]
      local current_cors = get_matched_cors(req_origin, api_config.cors_origin)

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
      else
        local response_body, status, content_type
        local authorized = true

        if SECRET ~= "" and path:find("^/api/") then
          local client_key = headers["x-api-key"]
          if client_key ~= SECRET then authorized = false end
        end

        if not authorized then
          response_body = json.encode({ error = "Unauthorized: Invalid or missing API key" })
          status = "401 Unauthorized"
          content_type = "application/json"
        else
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
            local st = get_skeen_status()
            st.success = true
            response_body = json.encode(st)
            status = "200 OK"
            content_type = "application/json"
          elseif path == "/api/files-list" and method == "GET" then
            local map = get_allowed_files_map()
            local files_list = {}

            for id, target in pairs(map) do
              local name = target.path:match("^.+/(.+)$") or target.path
              if id == "skeen" then
                name = "skeen.json"
              elseif id == "pure_cidr" then
                name = target.path:match("^.+/(.+)$") or "pure_cidr.list"
              elseif id == "singbox" then
                name = target.path:match("^.+/(.+)$") or "config.json"
              elseif id:match("^sb_file_") then
                local parent = target.path:match("([^/]+/[^/]+)$")
                name = parent or name
              end
              table.insert(files_list, { id = id, name = name })
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
                content = strip_json_comments(content)
                local success, data = pcall(json.decode, content)
                response_body = json.encode({ success = true, content = success and data or {} })
              else
                response_body = json.encode({ success = true, content = content })
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
    end
  end
  client:close()
end

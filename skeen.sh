#!/bin/sh
# shellcheck disable=SC3043
#
# https://github.com/jinndi/SKeen
#
# Copyright (c) 2026 Jinndi <alncores@gmail.ru>
#
# Released under the MIT License, see the accompanying file LICENSE
# or https://opensource.org/licenses/MIT

# exit on error or unset variable
# set -e -u

PATH="/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ACTION="${1:-}"
CALLER="${2:-}"

[ -z "$CALLER" ] && CALLER="cli"
[ -z "$ACTION" ] && CALLER="menu"

readonly DEPENDENCIES="lua luasocket skeen-api iptables ip-full ipset net-tools conntrack curl tar jsonfilter logger"

readonly ENTWARE_DIR="/opt"
readonly WORK_DIR="${ENTWARE_DIR}/etc/skeen"
readonly TMP_DIR="${ENTWARE_DIR}/tmp"
readonly RUN_DIR="/tmp/.skeen"
readonly NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
readonly MODULES_OS_DIR="/lib/modules"
readonly MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"
readonly CURL_RESOLVE_FIX="--resolve release-assets.githubusercontent.com:443:185.199.108.133"
readonly REPO_REFS_BASE_URL="https://raw.githubusercontent.com/jinndi/SKeen/refs/heads"

readonly SKEEN_NAME="SKeen"
readonly SKEEN_VERSION="5.17.0"
readonly SKEEN_PROC="skeen"
readonly SKEEN_SCRIPT="${ENTWARE_DIR}/bin/${SKEEN_PROC}"
readonly SKEEN_RUN_SCRIPT="${RUN_DIR}/${SKEEN_PROC}.sh"
readonly SKEEN_API_URL="https://github.com/jinndi/SKeen/releases/latest"
readonly SKEEN_CONFIG="${WORK_DIR}/${SKEEN_PROC}.json"
readonly SKEEN_RUN_CONFIG="${RUN_DIR}/${SKEEN_PROC}.json"
readonly SKEEN_AUTOSTART_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"
readonly SKEEN_SCRIPT_URL="--SKEEN_API_URL_DOWNLOAD_SKEEN--"
readonly SKEEN_CONFIG_DOC_URL="--CONFIGURATION_DOCUMENTATION_URL--"

readonly SERVICE_API_PROC="skeen-api"
readonly SERVICE_API_SCRIPT="${ENTWARE_DIR}/bin/${SERVICE_API_PROC}"

readonly SINGBOX_NAME="Sing-box"
readonly SINGBOX_PID_FILE="/tmp/run/skeen.pid"
readonly SINGBOX_RUN_VERSION="${RUN_DIR}/version"
readonly SINGBOX_BIN_PATH="${ENTWARE_DIR}/bin/skeen-box"
readonly SINGBOX_CONFIG_PATH="${WORK_DIR}/config.json"
readonly SINGBOX_CONFIG_DIR_PATH="${WORK_DIR}/config"
readonly SINGBOX_CONFIG_MERGED_PATH="${WORK_DIR}/.config_merged.json"
readonly SINGBOX_CONFIG_EXT_PATH="${WORK_DIR}/config_ext.json"
readonly SINGBOX_CONFIG_EXT_DIR_PATH="${WORK_DIR}/config_ext"
readonly SINGBOX_CONFIG_EXT_MERGED_PATH="${WORK_DIR}/.config_merged_ext.json"
readonly SINGBOX_REPO="SagerNet/sing-box"
readonly FORK_SKB_REPO="jinndi/skeen-box"
readonly FORK_PDK_REPO="podkop-net/podkop-engine"
readonly FORK_LX_REPO="Leadaxe/sing-box-lx"

readonly FIREWALL_HOOK_FILE="${NETFILTER_DIR}/${SKEEN_PROC}_firewall.sh"
readonly WAIT_ROUTE_FILE="/tmp/${SKEEN_PROC}_wait_route"
readonly NET_EXCLUDE_SET="skeen_exclude_net"
readonly PORT_EXCLUDE_SET="skeen_exclude_port"
readonly FAKEIP_INTERCEPT_SET="skeen_fakeip_net"
readonly FAKEIP_INTERCEPT_FILE="${WORK_DIR}/pure_cidr.list"
readonly FAKEIP_CLIENTS_SRC_SET="skeen_fakeip_src"
readonly CHAIN_PREROUTING="skeen"
readonly CHAIN_OUTPUT="skeen_mask"
readonly CHAIN_DIVERT="skeen_divert"
readonly CHAIN_TUN="skeen_tun"
readonly CHAIN_DNS="_NDM_HOTSPOT_DNSREDIR"
readonly CHAIN_DNS_OUT="skeen_dns_out"
readonly TABLE_REDIRECT="nat"
readonly TABLE_TPROXY="mangle"
readonly TABLE_MARK="0x12"
readonly TABLE_ID="12"
readonly DNS_PORT=53

# IETF/IANA IPv4 Special-Purpose Address Registry
# https://www.iana.org/assignments/iana-ipv4-special-registry/
readonly RESERVED_IPV4="
0.0.0.0/8          # 'This host on this network' (RFC 1122)
10.0.0.0/8         # Private-Use (RFC 1918)
100.64.0.0/10      # Shared Address Space (RFC 6598)
127.0.0.0/8        # Loopback (RFC 1122)
169.254.0.0/16     # Link Local (RFC 3927)
172.16.0.0/12      # Private-Use (RFC 1918)
192.0.0.0/24       # IETF Protocol Assignments (RFC 6890)
192.0.2.0/24       # Documentation (TEST-NET-1) (RFC 5737)
192.31.196.0/24    # AS112-v4 (RFC7535)
192.52.193.0/24    # AMT (RFC7450)
192.88.99.0/24     # 6to4 Relay Anycast (RFC 3068, deprecated)
192.168.0.0/16     # Private-Use (RFC 1918)
# 198.18.0.0/15      # Benchmarking (RFC 2544) + sing-box fakeip
198.51.100.0/24    # Documentation (TEST-NET-2) (RFC 5737)
203.0.113.0/24     # Documentation (TEST-NET-3) (RFC 5737)
224.0.0.0/4        # Multicast (RFC 5771)
240.0.0.0/4        # Reserved for Future Use (RFC 1112)
255.255.255.255/32 # Direct Delegation AS112 Service (RFC7534)
78.47.125.180/32   # KeenDNS
"

# IETF/IANA IPv6 Special-Purpose Address Registry
# https://www.iana.org/assignments/iana-ipv6-special-registry/
readonly RESERVED_IPV6="
::/128             # Unspecified Address (RFC 4291)
::1/128            # Loopback Address (RFC 4291)
::/96              # Zero-prefix / IPv4-compatible (RFC 4291, best practice)
::ffff:0:0/96      # IPv4-mapped Address (RFC 4291)
64:ff9b::/96       # IPv4-IPv6 Translation (RFC 6052) – (for NAT64)
64:ff9b:1::/48     # IPv4-IPv6 Translation (RFC 8215)
100::/64           # Discard-Only Address Block (RFC 6666)
100:0:0:1::/64     # Dummy IPv6 Prefix (RFC 9780)
2001::/23          # IETF Protocol Assignments (RFC 2928)
2001::/32          # TEREDO (RFC 4380) – (tunnel)
2001:2::/48        # Benchmarking (RFC 5180)
2001:20::/28       # ORCHIDv2 (RFC 7343)
2001:db8::/32      # Documentation (RFC 3849)
2002::/16          # 6to4 (RFC 3056, deprecated)
3fff::/20          # Documentation (RFC 9637)
# fc00::/7           # Unique Local Addresses (RFC 4193) – include fd00::/8 + sing-box fakeip
fe80::/10          # Link-Local Unicast (RFC 4291)
ff00::/8           # Multicast (RFC 4291)
"

readonly DELIMETER="------------------------------------------------"

is_tty() {
  [ "${FORCE_COLOR:-0}" = "1" ] || [ -t 1 ] || [ -t 2 ]; ret=$?
  is_tty() { return "$ret"; }
  return "$ret"
}

color() {
  local code="${1:-}" text="${2:-}"
  if is_tty; then printf '\033[%sm%s\033[0m\n' "$code" "$text"; else printf '%s\n' "$text"; fi
}

cyan()      { color 36 "$1"; }
cyan_bold() { color '1;38;5;30' "$1"; }
red()       { color 31 "$1"; }
green()     { color 32 "$1"; }
yellow()    { color 33 "$1"; }

echomsg()  { cyan "[INFO] $1"; }
echook()   { green "[OK] $1"; }
echowarn() { yellow "[WARN] $1"; }
echoerr()  { red "[ERROR] $1"; }
exiterr()  { red "[FATAL] $1"; exit 1; }

check_tty() { is_tty || { echoerr "--COMMAND_SUPPORTS_ONLY_TTY--"; exit 1; }; }

log_message() { logger -p "$1" -t "$SKEEN_NAME" "$2"; }
logger_notice()  { log_message notice "$1"; }
logger_warning() { log_message warning "$1"; }
logger_error()   { log_message error "$1"; }

log_firewall_update() {
  local type="${1:-unknown}" table="${2:-unknown}"
  [ "$CALLER" = "netfilter" ] && logger_notice "--LOGGER_P_NOTICE_T_SKEEN_NAME_UPDATING_RULES--" || true
}

if is_tty; then
  cleanup() { { stty sane </dev/tty; } 2>/dev/null || true; }
  trap cleanup EXIT; trap 'exit 143' TERM
  trap 'printf "\n"; exit 130' INT
fi

create_run_dir() { if [ ! -d "$RUN_DIR" ]; then mkdir -p "$RUN_DIR" && chmod 700 "$RUN_DIR"; fi }

create_skeen_config() {
  if [ "$1" = "force" ]; then
    rm -f "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG"
  elif [ -f "$SKEEN_CONFIG" ]; then
    echomsg "--CONFIGURATION_FILE_SKEEN_NAME_ALREADY_EX--"
    return
  fi

  echomsg "--CREATING_CONFIGURATION_FILE_SKEEN_NAME--"

  mkdir -p "$(dirname "$SKEEN_CONFIG")"

  cat <<EOF >"$SKEEN_CONFIG"
// $SKEEN_CONFIG_DOC_URL
{
  "auto_start": {
    "enabled": 1
  },
  "policy": {
    "enabled": 0,
    "segment": "br1"
  },
  "network": {
    "ipv6": 1,
    "tuning": 0
  },
  "singbox": {
    "config": {
      "use_dir": 0,
      "url": "",
      "split": 1
    },
    "api": {
      "url": "http://127.0.0.1:9999",
      "secret": ""
    },
    "external": {
      "enabled": ${EXTERNAL_ENABLED:-0},
      "path": "",
      "config": {
        "use_dir": 0,
        "url": "",
        "split": 1
      },
      "api": {
        "url": "",
        "secret": ""
      }
    }
  },
  "services": {
    "api": {
      "auto_start": 1,
      "port": 3000,
      "secret": "",
      "cors_origin": ["*"],
      "dashboard": 1
    },
    "proxy": {
      "enabled": 0,
      "port": "",
      "user": "",
      "pass": ""
    }
  },
  "firewall": {
    "intercept": {
      "dns": 1,
      "fakeip": {
        "enabled": 0,
        "clients": []
      }
    },
    "exclude": {
      "port": ["137:139", 445, 500, 1900, 4500],
      "ipv4_cidr": [],
      "ipv6_cidr": []
    },
    "redirect_dns": {
      "enabled": 0,
      "to_port": "",
      "use_policy": 1
    },
    "proxy_router": 1
  },
  "update": {
    "singbox": {
      "enabled": 1,
      "beta": ${BETA_ENABLED:-0},
      "channel": "${FORK_CHANNEL:-official}"
    },
    "skeen": {
      "enabled": 1,
      "api": 1
    }
  }
}
EOF

  cp -fp "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG" >/dev/null 2>&1

  [ ! -f "$SKEEN_AUTOSTART_SCRIPT" ] && create_autostart_script >/dev/null 2>&1

  echook "--CONFIGURATION_FILE_SKEEN_NAME_CREATED_SU--"
}

get_skeen_config_path() {
  if [ -f "${SKEEN_RUN_CONFIG:-}" ]; then
    echo "$SKEEN_RUN_CONFIG"
  elif [ -f "${SKEEN_CONFIG:-}" ]; then
    echo "$SKEEN_CONFIG"
  fi
}

json_get_array() {
  local path="${1:-}"
  local arr config_path

  config_path="$(get_skeen_config_path)"

  arr="$(jsonfilter -i "$config_path" -e "${path}[*]")"

  if [ -n "$arr" ]; then printf '%s\n' "$arr"; return 0; fi

  arr="$(jsonfilter -i "$config_path" -e "$path")" || return 0

  case "$arr" in
    '[ ]'|'[]'|'') return 0 ;;
    *) printf '%s\n' "$arr" ;;
  esac
}

files_differ() { [ "$(sha256sum "$1" | cut -d ' ' -f 1)" != "$(sha256sum "$2" | cut -d ' ' -f 1)" ]; }

check_and_create_or_sync_skeen_config() {
  [ ! -f "$SKEEN_CONFIG" ] && create_skeen_config

  if [ ! -f "$SKEEN_RUN_CONFIG" ] || files_differ "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG"; then
    if create_run_dir && cp -fp "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG"; then
      chmod 700 "$SKEEN_RUN_CONFIG"
    else
      exiterr "--FAILED_TO_SYNCHRONIZE_SKEEN_CONFIG_TO_ME--"
    fi
  fi
}

check_and_kill_old_singbox_proc() {
  local sing_pid sing_path kill_old=0

  if [ -f "$SINGBOX_PID_FILE" ]; then
    read -r sing_pid < "$SINGBOX_PID_FILE"
    if [ -n "$sing_pid" ] && [ -d "/proc/$sing_pid" ]; then
      sing_path="$(readlink -f "/proc/$sing_pid/exe" 2>/dev/null)"
    fi
  fi

  case "$sing_path" in "" | "$SINGBOX_BIN") ;; *) kill_old=1 ;; esac

  if [ "$kill_old" = "0" ] && [ -n "$sing_pid" ] && [ -d "/proc/$sing_pid" ]; then
    [ ! -f "$SINGBOX_BIN" ] && kill_old=1
  fi

  if [ "$kill_old" = "1" ] && kill -0 "$sing_pid" 2>/dev/null; then
    echomsg "--TERMINATING_SINGBOX_NAME_PID_SING_PID--"
    kill -9 "$sing_pid"; clean_firewall; rm -f "$SINGBOX_PID_FILE"
  fi

  if [ -f "$SINGBOX_BIN" ] && [ ! -x "$SINGBOX_BIN" ]; then
    chmod +x "$SINGBOX_BIN" 2>/dev/null || true
  fi
}

get_auto_start_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" -e AUTO_START_ENABLED='@.auto_start.enabled'
  )"
  : "${AUTO_START_ENABLED:=1}"
}

get_network_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e NETWORK_IPV6='@.network.ipv6' \
      -e NETWORK_TUNING='@.network.tuning'
  )"

  : "${NETWORK_IPV6:=1}"
  : "${NETWORK_TUNING:=0}"
}

get_singbox_config() {
  local mode="${1:-}" config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e sing_config_use_dir='@.singbox.config.use_dir' \
      -e sing_config_url='@.singbox.config.url' \
      -e sing_config_split='@.singbox.config.split' \
      -e sing_api_url='@.singbox.api.url' \
      -e sing_api_secret='@.singbox.api.secret' \
      -e SINGBOX_EXTERNAL_ENABLED='@.singbox.external.enabled' \
      -e sing_external_path='@.singbox.external.path' \
      -e sing_external_config_use_dir='@.singbox.external.config.use_dir' \
      -e sing_external_config_url='@.singbox.external.config.url' \
      -e sing_external_config_split='@.singbox.external.config.split' \
      -e sing_external_api_url='@.singbox.external.api.url' \
      -e sing_external_api_secret='@.singbox.external.api.secret'
  )"

  : "${sing_config_use_dir:=0}"
  : "${sing_config_url:=}"
  : "${sing_config_split:=1}"
  : "${sing_api_url:=http://127.0.0.1:9999}"
  : "${sing_api_secret:=}"
  : "${SINGBOX_EXTERNAL_ENABLED:=0}"
  : "${sing_external_path:=/opt/bin/sing-box}"
  : "${sing_external_config_use_dir:=$sing_config_use_dir}"
  : "${sing_external_config_url:=$sing_config_url}"
  : "${sing_external_config_split:=$sing_config_split}"
  : "${sing_external_api_url:=$sing_api_url}"
  : "${sing_external_api_secret:=$sing_api_secret}"

  _init_box_target() {
    local use_dir="${1:-0}" dir_path="${2:-}" file_path="${3:-}" src
    if [ "$use_dir" = "1" ]; then
      mkdir -p "$dir_path"
      if [ -z "$(ls -A "$dir_path")" ]; then
        if [ -f "$file_path" ] && [ "$SINGBOX_CONFIG_SPLIT" = "1" ]; then
          split_singbox_config "$file_path" "$dir_path" || echo '{}' > "$dir_path/config.json"
        else
          echo '{}' > "$dir_path/config.json"
        fi
      fi

      if [ "$SINGBOX_EXTERNAL_ENABLED" = "1" ]; then
        SINGBOX_CONFIG="$SINGBOX_CONFIG_EXT_MERGED_PATH"
      else
        SINGBOX_CONFIG="$SINGBOX_CONFIG_MERGED_PATH"
      fi
      SINGBOX_CONFIG_DIR="$dir_path"
    else
      if [ ! -f "$file_path" ]; then
        if [ -d "$dir_path" ] && [ -n "$(ls -A "$dir_path")" ]; then
          "$SINGBOX_BIN" merge "$file_path" -C "$dir_path" >/dev/null 2>&1 || echo '{}' > "$file_path"
        elif src="${SINGBOX_CONFIG_PATH}"; [ -f "$src" ] || { src="${SINGBOX_CONFIG_EXT_PATH}"; [ -f "$src" ]; }; then
          cp -f "$src" "$file_path"
        else
          echo '{}' > "$file_path"
        fi
      fi
      SINGBOX_CONFIG="$file_path"
    fi
  }

  SINGBOX_CONFIG_DIR=""

  if [ "$SINGBOX_EXTERNAL_ENABLED" = "1" ]; then
    [ -f "$sing_external_path" ] || sing_external_path="$(command -v "$sing_external_path")"
    SINGBOX_BIN="$sing_external_path"
    SINGBOX_CONFIG_URL="$sing_external_config_url"
    SINGBOX_CONFIG_SPLIT="$sing_external_config_split"
    _init_box_target "$sing_external_config_use_dir" "$SINGBOX_CONFIG_EXT_DIR_PATH" "$SINGBOX_CONFIG_EXT_PATH"
    export BOX_API_URL="$sing_external_api_url"
    export BOX_API_SECRET="$sing_external_api_secret"
  else
    SINGBOX_BIN="$SINGBOX_BIN_PATH"
    SINGBOX_CONFIG_URL="$sing_config_url"
    SINGBOX_CONFIG_SPLIT="$sing_config_split"
    _init_box_target "$sing_config_use_dir" "$SINGBOX_CONFIG_DIR_PATH" "$SINGBOX_CONFIG_PATH"
    export BOX_API_URL="$sing_api_url"
    export BOX_API_SECRET="$sing_api_secret"
  fi

  if [ "$mode" = "--json" ] && [ -z "$SINGBOX_CONFIG_DIR" ]; then
    printf '{"path":"%s","is_dir":%s}\n' "$SINGBOX_CONFIG" "false"; return 0
  fi

  if [ -n "$SINGBOX_CONFIG_DIR" ]; then
    if [ "$mode" = "--json" ]; then
      printf '{"path":"%s","is_dir":%s}\n' "$SINGBOX_CONFIG_DIR" "true"; return 0
    fi

    if [ ! -f "$SINGBOX_CONFIG" ] ||
      [ -n "$(find "$SINGBOX_CONFIG_DIR" -mindepth 1 -newer "$SINGBOX_CONFIG" -print -quit)" ];
    then
      if ! "$SINGBOX_BIN" merge "$SINGBOX_CONFIG" -C "$SINGBOX_CONFIG_DIR" >/dev/null 2>&1; then
        echoerr "--FAILED_TO_MERGE_SINGBOX_NAME_CONFIGURATI--"
      fi
    fi
  fi

  check_and_kill_old_singbox_proc
}

get_service_api_config() {
  local mode="${1:-}" config_path

  config_path="$(get_skeen_config_path)"

  if [ -n "$config_path" ]; then
    eval "$(
      jsonfilter -i "$config_path" \
        -e SERVICE_API_AUTO_START='@.services.api.auto_start' \
        -e SERVICE_API_PORT='@.services.api.port' \
        -e SERVICE_API_SECRET='@.services.api.secret' \
        -e SERVICE_API_DASHBOARD='@.services.api.dashboard'
    )"
    [ "$mode" = "--json" ] &&
      SERVICE_API_CORS_ORIGIN="$(jsonfilter -i "$config_path" -e '@.services.api.cors_origin' 2>/dev/null)"
  fi

  : "${SERVICE_API_AUTO_START:=1}"
  : "${SERVICE_API_PORT:=3000}"
  : "${SERVICE_API_SECRET:=}"
  : "${SERVICE_API_CORS_ORIGIN:='["*"]'}"
  : "${SERVICE_API_DASHBOARD:=1}"

  if [ "$mode" = "--json" ]; then
    printf '{"port":%s,"secret":"%s","cors_origin":%s,"dashboard":%s}\n' \
      "$SERVICE_API_PORT" "$SERVICE_API_SECRET" "$SERVICE_API_CORS_ORIGIN" "$SERVICE_API_DASHBOARD"
  fi
}

get_service_proxy_config() {
  local config_path

  if command -v jsonfilter >/dev/null 2>&1; then
    config_path="$(get_skeen_config_path)"

    [ -n "$config_path" ] && eval "$(
      jsonfilter -i "$config_path" \
        -e SERVICE_PROXY_ENABLED='@.services.proxy.enabled' \
        -e SERVICE_PROXY_PORT='@.services.proxy.port' \
        -e SERVICE_PROXY_USER='@.services.proxy.user' \
        -e SERVICE_PROXY_PASS='@.services.proxy.pass' \
        2>/dev/null
    )"
  fi

  : "${SERVICE_PROXY_ENABLED:=0}"
  : "${SERVICE_PROXY_PORT:=}"
  : "${SERVICE_PROXY_USER:=}"
  : "${SERVICE_PROXY_PASS:=}"
}

get_firewall_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  get_network_config

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e POLICY_ENABLED='@.policy.enabled' \
      -e POLICY_SEGMENT='@.policy.segment' \
      -e FIREWALL_INTERCEPT_DNS='@.firewall.intercept.dns' \
      -e FIREWALL_INTERCEPT_FAKEIP='@.firewall.intercept.fakeip.enabled' \
      -e FIREWALL_REDIRECT_DNS_ENABLED='@.firewall.redirect_dns.enabled' \
      -e FIREWALL_REDIRECT_DNS_PORT='@.firewall.redirect_dns.to_port' \
      -e FIREWALL_REDIRECT_DNS_USE_POLICY='@.firewall.redirect_dns.use_policy' \
      -e FIREWALL_PROXY_ROUTER='@.firewall.proxy_router'
  )"

  : "${POLICY_ENABLED:=0}"
  : "${POLICY_SEGMENT:=br1}"
  : "${FIREWALL_INTERCEPT_DNS:=1}"
  : "${FIREWALL_INTERCEPT_FAKEIP:=0}"
  : "${FIREWALL_REDIRECT_DNS_ENABLED:=0}"
  : "${FIREWALL_REDIRECT_DNS_PORT:=}"
  : "${FIREWALL_REDIRECT_DNS_USE_POLICY:=1}"
  : "${FIREWALL_PROXY_ROUTER:=0}"
}

get_update_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e UPDATE_SINGBOX_ENABLED='@.update.singbox.enabled' \
      -e UPDATE_SINGBOX_BETA='@.update.singbox.beta' \
      -e UPDATE_SINGBOX_CHANNEL='@.update.singbox.channel' \
      -e UPDATE_SKEEN_ENABLED='@.update.skeen.enabled' \
      -e UPDATE_SKEEN_API='@.update.skeen.api'
  )"

  : "${UPDATE_SINGBOX_ENABLED:=1}"
  : "${UPDATE_SINGBOX_BETA:=0}"
  : "${UPDATE_SINGBOX_CHANNEL:=}"
  : "${UPDATE_SKEEN_ENABLED:=1}"
  : "${UPDATE_SKEEN_API:=0}"
}

run_curl() {
  local proxy_opts=""
  # Referenced by the error-message translations.
  # shellcheck disable=SC2034
  local err_template="--SERVICE_PROXY_IS_ENABLED_BUT--"

  get_service_proxy_config

  if [ -n "$SERVICE_PROXY_ENABLED" ] && [ "$SERVICE_PROXY_ENABLED" = "1" ]; then
    if [ -z "$SERVICE_PROXY_PORT" ]; then
      echoerr "--ERR_TEMPLATE_SERVICE_PROXY_PORT_IS_NOT_S--" && return 1
    elif ! is_running; then
      echoerr "--ERR_TEMPLATE_SINGBOX_NAME_IS_NOT_RUNNING--" && return 1
    elif ! netstat -tuln 2>/dev/null | grep -q ":${SERVICE_PROXY_PORT}"; then
      echoerr "--ERR_TEMPLATE_NO_PROCESS_IS_LISTENING_ON--" && return 1
    else
      proxy_opts="--socks5-hostname 127.0.0.1:${SERVICE_PROXY_PORT}"
      if [ -n "$SERVICE_PROXY_USER" ] && [ -n "$SERVICE_PROXY_PASS" ]; then
        proxy_opts="$proxy_opts --proxy-user ${SERVICE_PROXY_USER}:${SERVICE_PROXY_PASS}"
      fi
    fi
  fi

  # shellcheck disable=SC2086
  curl -fL --connect-timeout 5 --speed-limit 1000 --speed-time 15 $proxy_opts "$@"
}

get_current_version() {
  local proc="${1:-}"

  case "$proc" in
  "sing")
    if [ -f "$SINGBOX_BIN" ]; then
      local c_path="" c_size="" c_mtime="" c_inode="" c_hash="" c_ver=""
      local file_metadata hash_output binary_hash ver raw_output

      if [ -f "$SINGBOX_RUN_VERSION" ]; then
        IFS='|' read -r c_path c_size c_mtime c_inode c_hash c_ver < "$SINGBOX_RUN_VERSION" 2>/dev/null
      fi

      file_metadata="$(stat -L -t "$SINGBOX_BIN" 2>/dev/null | awk 'NF >= 15 { print $(NF - 13) "|" $(NF - 2) "|" $(NF - 7) }')"

      if [ -n "$file_metadata" ] && [ "$c_path" = "$SINGBOX_BIN" ] &&
        [ "$c_size|$c_mtime|$c_inode" = "$file_metadata" ]; then
        echo "$c_ver"
        return 0
      fi

      hash_output="$(sha256sum "$SINGBOX_BIN" 2>/dev/null)"
      binary_hash="${hash_output%% *}"

      if [ -n "$binary_hash" ] && [ "$c_hash" = "$binary_hash" ]; then
        if [ -n "$file_metadata" ] && create_run_dir; then
          echo "${SINGBOX_BIN}|${file_metadata}|${binary_hash}|${c_ver}" > "$SINGBOX_RUN_VERSION"
        fi
        echo "$c_ver"
        return 0
      fi

      raw_output="$("$SINGBOX_BIN" version 2>/dev/null)"
      # shellcheck disable=SC2086
      set -- $raw_output
      ver="${3:-unknown}"

      if [ -n "$file_metadata" ] && [ -n "$binary_hash" ] && create_run_dir; then
        echo "${SINGBOX_BIN}|${file_metadata}|${binary_hash}|${ver}" > "$SINGBOX_RUN_VERSION"
      fi
      echo "$ver"
    fi
    ;;
  "skeen") echo "$SKEEN_VERSION" ;;
  "skeen-api") [ -f "$SERVICE_API_SCRIPT" ] && "$SERVICE_API_SCRIPT" -v ;;
  esac
}

get_latest_version() {
  local api_url="${1:-}" sing_beta="${2:-}" latest_release tag

  if [ "$sing_beta" = "1" ]; then
    latest_release="$(run_curl -s --max-time 10 "$api_url")"
    tag="$(echo "$latest_release" | grep -oE '<title>[^<]+' | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?' | head -n 1 | sed 's/^v//')"
  else
    latest_release="$(run_curl -sI --max-time 10 -H "Cache-Control: no-cache" "${api_url}?$(date +%s)")"
    tag="$(echo "$latest_release" | grep -i "^location:" | sed -E 's/.*tag\/(.*)/\1/' | tr -d '\r' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?')"
  fi

  [ -z "$tag" ] && return 1

  echo "$tag"
}

show_header() {
  cyan "
░█▀▀▀█ ░█ ▄▀ █▀▀ █▀▀ █▀▀▄
─▀▀▀▄▄ ░█▀▄  █▀▀ █▀▀ █  █
░█▄▄▄█ ░█ ░█ ▀▀▀ ▀▀▀ ▀  ▀"
}

check_free_space() {
  local required_mb="${1:-120}"
  local path="${2:-$ENTWARE_DIR}"
  local free_mb free_mb_display

  free_mb="$(df -Pm "$path" 2>/dev/null | awk 'NR == 2 {print $4}')"
  # Referenced by the free-space message translations.
  # shellcheck disable=SC2034
  free_mb_display="${free_mb:-0}"

  case "$free_mb" in ''|*[!0-9]*) echowarn "--UNABLE_TO_DETERMINE_FREE_SPACE_ON_PATH_F--"; return 0 ;; esac

  if [ "$free_mb" -lt "$required_mb" ]; then
    exiterr "--INSUFFICIENT_FREE_SPACE_ON_PATH_REQUIRED--"
  fi

  return 0
}

get_os_release() {
  if [ "$(command -v opkg 2>/dev/null || true)" != "/opt/bin/opkg" ]; then
    exiterr "--UNSUPPORTED_THE_SYSTEM_OS--"
  else
    PKG_OS="openwrt"
    PKG_SUFFIX=".ipk"
  fi
}

ask_install_singbox() {
  local opt channel auto_opt="${AUTO:-}" auto_fork=""

  case "$auto_opt" in
    "") : ;; [1-4]) : ;; 4-[1-9]|4-10) auto_fork=${auto_opt#4-}; auto_opt=4 ;;
    *) exiterr "--AUTO_VALUE_OUT_OF_ALLOWED_VALUES--" ;;
  esac

  while :; do
    if [ -n "$auto_opt" ]; then
      opt="$auto_opt"; auto_opt=""
    else
      check_tty; show_header; printf "\n"

      cyan "--SINGBOX_NAME_INSTALLATION_OPTIONS--"
      # shellcheck disable=SC3045
      printf "--SINGBOX_INSTALLATION_OPTIONS_LIST--"

      while :; do
        # shellcheck disable=SC3045
        printf "--SELECT_AN_OPTION_1_4--" >/dev/tty
        read -r opt </dev/tty

        opt=${opt:-1}
        case "$opt" in
          1|2|3|4) break ;;
          *) echoerr "--ENTER_1_2_3_OR_4--"; printf "\\n" ;;
        esac
      done
    fi

    if [ "$opt" = "4" ]; then
      if [ -n "$auto_fork" ]; then
        opt="$auto_fork"; auto_fork=""
      else
        printf '\n'; cyan "--FORK_CHANNEL_OPTIONS_HEADER--"; echo
        local gh="https://github.com/"
        # shellcheck disable=SC3045
        printf "--FORK_CHANNEL_OPTIONS--"
        while :; do
          # shellcheck disable=SC3045
          printf "--SELECT_A_FORK_OPTION_0_10--" >/dev/tty
          read -r opt </dev/tty
          case "${opt:-}" in [0-9]|10) break ;; *) echoerr "--ENTER_0_TO_10--" ;; esac
        done
      fi
      if [ "$opt" = "0" ]; then continue; fi
      case "$opt" in
        1|2) channel="skb" ;; 3|4)  channel="skb-upx" ;;
        5)   channel="pdk" ;; 6)    channel="pdk-full" ;;
        7|8) channel="lx"  ;; 9|10) channel="lx-upx" ;;
      esac
      case "$opt" in 2|4|8|10) BETA_ENABLED=1 ;; esac
      FORK_CHANNEL="$channel"
    else
      case "$opt" in 1) : ;; 2) BETA_ENABLED=1 ;; 3) EXTERNAL_ENABLED=1 ;; esac
      FORK_CHANNEL="official"
    fi
    break
  done

  echomsg "--SELECTED_CHANNEL_INSTALLATION_OPTION_FOR--"
}

arch_elf() {
  local bin="/opt/bin/opkg"
  local base="mips"
  local b5 b6

  b5=$(hexdump -s 4 -n 1 -e '1/1 "%d"' "$bin" 2>/dev/null)
  b6=$(hexdump -s 5 -n 1 -e '1/1 "%d"' "$bin" 2>/dev/null)

  [ -z "$b5" ] || [ -z "$b6" ] && echo "" && return

  [ "$b5" -eq 2 ] && base="${base}64" # 64-bit
  [ "$b6" -eq 1 ] && base="${base}el" # Little-Endian

  echo "$base"
}

get_architecture() {
  local opkg_arch
  local ARCH
  local cpu_info

  opkg_arch=$(opkg print-architecture 2>/dev/null | tr '[:upper:]' '[:lower:]')

  case "$opkg_arch" in
  *aarch64* | *arm64* | *armv8*) ARCH="aarch64" ;;
  *mips*) ARCH="$(arch_elf)" ;;
  *) ARCH="" ;;
  esac

  [ -z "$ARCH" ] && exiterr "--UNSUPPORTED_CPU_ARCHITECTURE--"

  cpu_info=$(tr '[:upper:]' '[:lower:]' </proc/cpuinfo | tr -d '[:space:]')

  case "$ARCH" in
  aarch64)
    case "$cpu_info" in
    *0xd03*) PKG_ARCH="${ARCH}_cortex-a53" ;;
    *0xd08*) PKG_ARCH="${ARCH}_cortex-a72" ;;
    *0xd0b*) PKG_ARCH="${ARCH}_cortex-a76" ;;
    *) PKG_ARCH="${ARCH}_generic" ;; # fallback ...
    esac
    ;;
  mipsel)
    case "$cpu_info" in
    *74k*) PKG_ARCH="${ARCH}_74kc" ;;
    *24kf* | *fpu:yes* | *fpuexception:yes*) PKG_ARCH="${ARCH}_24kc_24kf" ;;
    *24k* | *34k* | *1004k* | *interaptiv*) PKG_ARCH="${ARCH}_24kc" ;;
    *) PKG_ARCH="${ARCH}_mips32" ;; # fallback ...
    esac
    ;;
  mips)
    case "$cpu_info" in
    *24k*) PKG_ARCH="${ARCH}_24kc" ;;
    *4kec*) PKG_ARCH="${ARCH}_4kec" ;;
    *) PKG_ARCH="${ARCH}_mips32" ;; # fallback ...
    esac
    ;;
  mips64el)
    PKG_ARCH="${ARCH}_mips64r2"
    ;;
  mips64)
    if echo "$cpu_info" | grep -qi octeon; then
      PKG_ARCH="${ARCH}_octeonplus"
    else
      PKG_ARCH="${ARCH}_mips64r2"
    fi
    ;;
  esac

  local arch_display
  # Referenced by the detected-architecture translation.
  # shellcheck disable=SC2034
  arch_display="$(green "$PKG_ARCH")"
  echomsg "--DETECTED_CPU_ARCHITECTURE--"
}

wait_input() {
  local oldstty
  oldstty=$(stty -g </dev/tty)
  stty -icanon -echo min 1 time 0 </dev/tty
  dd bs=1 count=1 </dev/tty 2>/dev/null
  stty "$oldstty" </dev/tty
  echo >/dev/tty
}

install_dependency() {
  pkg_name="${1:-lua}"

  if {
    if [ "$pkg_name" = "$SERVICE_API_PROC" ]; then
      if [ ! -f "$SERVICE_API_SCRIPT" ]; then
        local url="${REPO_REFS_BASE_URL}/static/${SERVICE_API_PROC}"
        run_curl -s --max-time 10 -o "$SERVICE_API_SCRIPT" "$url" && chmod +x "$SERVICE_API_SCRIPT"
      fi
    else
      opkg install "$pkg_name" >/dev/null 2>&1
    fi
  }; then
    echook "--INSTALLED--"
  else
    echoerr "--INSTALLATION_FAILED--"
  fi
}

install_dependencies() {
  echomsg "--CHECKING_DEPENDENCIES--"

  opkg update >/dev/null 2>&1 || true

  for pkg_name in $DEPENDENCIES; do
    printf "[%s] " "$pkg_name"
    install_dependency "$pkg_name"
  done

  echook "--DEPENDENCY_CHECK_COMPLETED--"
}

download_singbox() {
  local beta="${1:-}" version="${2:-$latest_version}"
  local channel="${FORK_CHANNEL:-official}" variant="official" repo="$SINGBOX_REPO" api_url suffix
  local required_mb=120 reserve_mb=2 tmp_free_mb opt_free_mb old_binary_kb=0 old_binary_mb path free_mb
  local dl_pkg_path="" dl_active=0

  cleanup_download() { if [ "${dl_active:-0}" = "1" ] && [ -n "${dl_pkg_path:-}" ]; then rm -f "$dl_pkg_path"; fi }
  on_download_interrupt() { cleanup_download; trap - INT TERM HUP; exit 130; }

  PKG_TMP_DIR="$TMP_DIR"

  case "$channel" in
    skb|skb-upx) repo="$FORK_SKB_REPO"; variant="skb"; required_mb=80 ;;
    pdk|pdk-full) repo="$FORK_PDK_REPO"; variant="pdk"; required_mb=55 ;;
    lx|lx-upx) repo="$FORK_LX_REPO"; variant="lx" ;;
  esac

  api_url="https://github.com/${repo}/releases/latest"
  [ "$beta" = "1" ] && api_url="https://github.com/${repo}/releases.atom"

  if [ -z "$version" ]; then
    echomsg "--FETCHING_THE_LATEST_VERSION--"
    version="$(get_latest_version "$api_url" "$beta")"
    [ -z "$version" ] && echoerr "--FAILED_TO_FETCH_VERSION--" && exit 1
    reserve_mb=20
    echook "--LATEST_VERSION_IS_VERSION--"
  fi

  case "$variant:$PKG_ARCH" in
    official:*) PKG_FORMAT="ipk"; PKG_NAME="sing-box_${version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}" ;;
    skb:aarch64_*) PKG_FORMAT="binary"; suffix="arm64_naive"; PKG_NAME="sing-box_${version}_linux_${suffix}" ;;
    skb:mipsel_*) PKG_FORMAT="binary"; suffix="mipsle_naive"; PKG_NAME="sing-box_${version}_linux_${suffix}" ;;
    skb:mips_*) PKG_FORMAT="binary"; suffix="mips"; PKG_NAME="sing-box_${version}_linux_${suffix}" ;;
    pdk:*) PKG_FORMAT="ipk"; suffix="${PKG_OS}_${PKG_ARCH}"; PKG_NAME="podkop-engine_${version}_${suffix}${PKG_SUFFIX}" ;;
    lx:aarch64_*) PKG_FORMAT="tar.gz"; suffix="linux-arm64"; PKG_NAME="sing-box-${version}-${suffix}.tar.gz" ;;
    lx:mipsel_*) PKG_FORMAT="tar.gz"; suffix="linux-mipsle-softfloat"; PKG_NAME="sing-box-${version}-${suffix}.tar.gz" ;;
    lx:mips_*) PKG_FORMAT="tar.gz"; suffix="linux-mips-softfloat"; PKG_NAME="sing-box-${version}-${suffix}.tar.gz" ;;
    *) echoerr "--UNSUPPORTED_CPU_ARCHITECTURE--"; return 1 ;;
  esac

  case "$channel:$PKG_ARCH" in
    skb-upx:*) PKG_NAME="${PKG_NAME}_upx"; required_mb=40 ;;
    pdk-full:*) PKG_NAME="podkop-engine-full_${version}_${suffix}${PKG_SUFFIX}"; required_mb=70 ;;
    lx-upx:aarch64_*|lx-upx:mipsel_*) PKG_NAME="${PKG_NAME%.tar.gz}.upx.tar.gz"; required_mb=40 ;;
  esac

  tmp_free_mb="$(df -Pm /tmp 2>/dev/null | awk 'NR == 2 {print $4}')"
  case "$tmp_free_mb" in ''|*[!0-9]*) ;;
    *) if [ "$tmp_free_mb" -ge "$required_mb" ]; then PKG_TMP_DIR="/tmp"; fi ;;
  esac

  opt_free_mb="$(df -Pm "$ENTWARE_DIR" 2>/dev/null | awk 'NR == 2 {print $4}')"
  if [ -f "$SINGBOX_BIN_PATH" ]; then
    old_binary_kb="$(du -k "$SINGBOX_BIN_PATH" 2>/dev/null | awk 'NR == 1 {print $1}')"
    case "$old_binary_kb" in ''|*[!0-9]*) old_binary_kb=0 ;; esac
  fi

  case "$opt_free_mb" in
  ''|*[!0-9]*) ;; *) old_binary_mb=$(((old_binary_kb + 1023) / 1024))
  free_mb="$((opt_free_mb + old_binary_mb + reserve_mb))"
  if [ "$free_mb" -lt "$required_mb" ]; then
    path="$ENTWARE_DIR"; echoerr "--INSUFFICIENT_FREE_SPACE_ON_PATH_REQUIRED--"
    [ -n "$latest_version" ] && return 1; exit 1
  fi ;; esac

  dl_pkg_path="${PKG_TMP_DIR}/${PKG_NAME}"; dl_active=1

  echomsg "--DOWNLOADING_PKG_NAME--"
  mkdir -p "$PKG_TMP_DIR"
  trap on_download_interrupt INT TERM HUP

  # shellcheck disable=SC2086
  if run_curl --max-time 1800 -o "$dl_pkg_path" $CURL_RESOLVE_FIX \
    "https://github.com/${repo}/releases/download/v${version}/${PKG_NAME}"; then
    dl_active=0; trap - INT TERM HUP
    echook "--DOWNLOADED_PKG_NAME_SUCCESSFULLY--"
    return 0
  fi

  trap - INT TERM HUP; cleanup_download; dl_active=0
  echoerr "--FAILED_TO_DOWNLOAD_PKG_NAME--"
  [ -n "$latest_version" ] && return 1; exit 1
}

install_singbox() {
  local tmp_unpack_dir="" binary_path=""
  local base_tmp_dir="${PKG_TMP_DIR:-$TMP_DIR}"
  local pkg_path="${base_tmp_dir}/${PKG_NAME}"

  cleanup_install() { [ -n "$tmp_unpack_dir" ] && rm -rf "$tmp_unpack_dir"; rm -f "$pkg_path"; }
  on_interrupt() { cleanup_install; trap - INT TERM HUP; exit 130; }
  finish_install() { cleanup_install; trap - INT TERM HUP; }
  trap on_interrupt INT TERM HUP

  if [ "${PKG_FORMAT:-}" = "binary" ]; then
    binary_path="$pkg_path"
  else
    tmp_unpack_dir="$(mktemp -d "${base_tmp_dir}/sing-box-unpack.XXXXXX")" || {
      echoerr "--FAILED_TO_CREATE_TEMPORARY_DIRECTORY_FOR--"; finish_install; return 1
    }

    echomsg "--EXTRACTING_PKG_NAME--"
    if ! {
      tar -xzf "$pkg_path" -C "$tmp_unpack_dir" &&
      { [ "${PKG_FORMAT:-}" = "tar.gz" ] || { [ -f "$tmp_unpack_dir/data.tar.gz" ] &&
        tar -xzf "$tmp_unpack_dir/data.tar.gz" -C "$tmp_unpack_dir"; }; }
    }; then
      echoerr "--EXTRACTION_ERROR_FOR_PKG_NAME--"; finish_install; return 1
    fi
    binary_path="$(find "$tmp_unpack_dir" -type f -size +5M ! -name '*.*' -print 2>/dev/null | sed -n '1p')"
  fi

  if [ ! -f "$binary_path" ]; then
    echoerr "--BINARY_FILE_SING_BOX_NOT_FOUND_INSIDE_TH--"; finish_install; return 1
  fi
  echook "--EXTRACTION_COMPLETED--"

  echomsg "--INSTALLING_SINGBOX_NAME_TO_SINGBOX_BIN_P--"
  rm -f "$SINGBOX_BIN_PATH"; mv -f "$binary_path" "$SINGBOX_BIN_PATH"
  chmod 755 "$SINGBOX_BIN_PATH"; rm -f "$SINGBOX_RUN_VERSION"

  echook "--SINGBOX_NAME_SUCCESSFULLY_INSTALLED--"; finish_install; return 0
}

download_singbox_config() {
  local beta="${1:-}" action="${2:-}"

  get_singbox_config
  local backup_config="${SINGBOX_CONFIG}.bak"

  if [ "$action" != "force" ] && [ -f "$SINGBOX_CONFIG" ] && [ "$(wc -c < "$SINGBOX_CONFIG")" -gt 3 ]; then
    echomsg "--CONFIGURATION_SINGBOX_NAME_FOUND_SKIPPIN--"
    return
  fi

  echomsg "--DOWNLOADING_SINGBOX_NAME_CONFIGURATION--"

  mkdir -p "$(dirname "$SINGBOX_CONFIG")"

  [ -f "$SINGBOX_CONFIG" ] && mv -f "$SINGBOX_CONFIG" "$backup_config"

  local arch beta_part config_name

  case "$(uname -m)" in
    aarch64|arm*) arch="" ;;
    *)            arch="_lite" ;;
  esac
  beta_part="$([ "$beta" = "1" ] && echo "_beta" || echo "")"
  config_name="config${beta_part}${arch}.json"

  if ! run_curl --max-time 10 -o "$SINGBOX_CONFIG" "${REPO_REFS_BASE_URL}/main/configs/${config_name}"; then
    [ -f "$backup_config" ] && mv -f "$backup_config" "$SINGBOX_CONFIG"
    echoerr "--FAILED_TO_DOWNLOAD_SINGBOX_NAME_CONFIGUR--"
    return 1
  fi

  rm -f "$backup_config"

  echook "--SINGBOX_NAME_CONFIGURATION_DOWNLOADED_SU--"
}

download_initial_ruleset() {
  local ruleset_url="https://github.com/jinndi/singbox_ruleset/raw/refs/heads/main/ruleset.tar.gz"
  local ruleset_path="${WORK_DIR}/ruleset"
  local tar_file="${ruleset_path}.tar.gz"
  local bak_path="${ruleset_path}_bak"

  mkdir -p "$WORK_DIR"

  if [ -d "$ruleset_path" ]; then
    rm -rf "$bak_path"; mv -f "$ruleset_path" "$bak_path"
  fi

  echomsg "--DOWNLOADING_INITIAL_RULESET--"

  if ! run_curl --max-time 120 -o "$tar_file" "$ruleset_url"; then
    rm -f "$tar_file"; rm -rf "$ruleset_path"
    [ -d "$bak_path" ] && mv -f "$bak_path" "$ruleset_path"
    echoerr "--FAILED_TO_DOWNLOAD_INITIAL_RULESET--"; return 1
  fi

  if ! tar -tzf "$tar_file" >/dev/null 2>&1 || ! tar -xzf "$tar_file" -C "$WORK_DIR" >/dev/null 2>&1; then
    rm -f "$tar_file"; rm -rf "$ruleset_path"
    [ -d "$bak_path" ] && mv -f "$bak_path" "$ruleset_path"
    echoerr "--FAILED_TO_EXTRACT_RULESET_ARCHIVE_OR_IT--"; return 1
  fi

  rm -f "$tar_file"; rm -rf "$bak_path"
  echook "--INITIAL_RULESET_DOWNLOADED_SUCCESSFULLY--"
}

create_autostart_script() {
  echomsg "--CREATE_SKEEN_NAME_AUTOSTART_SCRIPT--"

  [ -f "$SKEEN_AUTOSTART_SCRIPT" ] && rm -f "$SKEEN_AUTOSTART_SCRIPT"

  mkdir -p "$(dirname "$SKEEN_AUTOSTART_SCRIPT")"

  {
    echo "#!/bin/sh"
    echo "PATH=$PATH"
    echo "$SKEEN_PROC start init"
  } >"$SKEEN_AUTOSTART_SCRIPT"

  chmod 755 "$SKEEN_AUTOSTART_SCRIPT"
  chmod +x "$SKEEN_AUTOSTART_SCRIPT"

  echook "--AUTOSTART_SCRIPT_CREATED_SUCCESSFULLY--"
}

get_free_gid() {
  local group_file="${1:-}"
  local gid="${2:-1000}"
  local max=65535

  while [ "$gid" -le "$max" ]; do
    if ! grep -q ":$gid:[^:]*$" "$group_file" 2>/dev/null; then
      echo "$gid"
      return 0
    fi
    gid=$((gid + 1))
  done

  exiterr "--NO_FREE_GID_AVAILABLE--"
}

create_skeen_group() {
  local name="$SKEEN_PROC"
  local group_file="${ENTWARE_DIR}/etc/group"
  local gid_num

  if ! grep -q "^${name}:" "$group_file" 2>/dev/null; then
    gid_num=$(get_free_gid "$group_file" 1000)

    echomsg "--CREATING_GROUP_NAME_WITH_GID_GID_NUM--"
    addgroup -g "$gid_num" "$name" >/dev/null 2>&1 ||
      exiterr "--FAILED_TO_CREATE_GROUP_NAME--"
    echook "--GROUP_NAME_CREATED_SUCCESSFULLY--"
    return 2
  else
    return 0
  fi
}

download_skeen_script() {
  local action="${1:-}"
  local backup_script="${SKEEN_SCRIPT}.bak"
  local script_url="$SKEEN_SCRIPT_URL $CURL_RESOLVE_FIX"
  local current_script="${0:-}"
  local install_script_tmp="${SKEEN_SCRIPT}.tmp.$$"

  if [ "$action" != "update" ] && [ -f "$current_script" ] && [ -r "$current_script" ] && [ "$current_script" != "$SKEEN_SCRIPT" ]; then
    echomsg "--INSTALLING_CURRENT_SKEEN_SCRIPT_AT_SKEEN_S--"
    if cp "$current_script" "$install_script_tmp" && chmod 755 "$install_script_tmp" && mv -f "$install_script_tmp" "$SKEEN_SCRIPT"; then
      echook "--CURRENT_SKEEN_SCRIPT_INSTALLED_SUCCESSFULL--"
      return 0
    fi
    rm -f "$install_script_tmp"
  fi

  echomsg "--DOWNLOADING_SKEEN_NAME_SCRIPT_AT_SKEEN_S--"

  [ -f "$SKEEN_SCRIPT" ] && mv -f "$SKEEN_SCRIPT" "$backup_script"

  # shellcheck disable=SC2086
  if ! run_curl --max-time 120 -o "$SKEEN_SCRIPT" $script_url; then
    [ -f "$backup_script" ] && mv -f "$backup_script" "$SKEEN_SCRIPT"
    echoerr "--FAILED_TO_DOWNLOAD_SKEEN_NAME_SCRIPT--"
    [ "$action" != "update" ] && exit 1
    return 1
  fi

  chmod 755 "$SKEEN_SCRIPT"; chmod +x "$SKEEN_SCRIPT"

  [ -f "$backup_script" ] && rm -f "$backup_script"

  echook "--SKEEN_NAME_SCRIPT_DOWNLOADED_SUCCESSFULL--"
  return 0
}

press_any_key_to_menu() {
  local exit_code="${1:-0}"
  local action="${2:-}"

  if [ "$CALLER" = "init" ] || [ "$CALLER" = "netfilter" ]; then
    exit 0
  elif [ "$CALLER" != "menu" ]; then
    exit "$exit_code"
  fi

  echo "$DELIMETER"

  # shellcheck disable=SC3045
  printf "--PRESS_ANY_KEY_TO_OPEN_MENU--" >/dev/tty
  wait_input

  if [ "$action" = "reload" ]; then
    exec sh "$SKEEN_SCRIPT"
  else
    show_menu
  fi
}

is_running() {
  start-stop-daemon -K -t -p "$SINGBOX_PID_FILE" >/dev/null 2>&1
}

install() {
  AUTO="${AUTO:-}"; BETA_ENABLED=0; EXTERNAL_ENABLED=0

  get_os_release
  ask_install_singbox
  if [ "$EXTERNAL_ENABLED" != "1" ]; then
    get_architecture
    download_singbox "$BETA_ENABLED"
    install_singbox
  fi
  install_dependencies
  create_skeen_config
  download_singbox_config "$BETA_ENABLED"
  download_initial_ruleset
  create_autostart_script
  create_skeen_group
  download_skeen_script

  if [ "$EXTERNAL_ENABLED" != "1" ]; then
    "$SINGBOX_BIN_PATH" version
  elif [ ! -f /opt/bin/sing-box ]; then
    echomsg "--SET_THE_SINGBOX_NAME_BINARY_PATH_IN_SKEE--"
  fi

  echomsg "--CONFIGURE_SINGBOX_NAME_BY_EDITING_CONFIG--"
  echomsg "--CONFIGURE_SKEEN_NAME_BY_EDITING_SKEEN_CO--"
  echook "--INSTALLATION_COMPLETED--"

  if [ -z "$AUTO" ]; then press_any_key_to_menu; fi
}

uninstall() {
  echomsg "--UNINSTALLING_SKEEN_NAME--"

  is_running && stop

  echomsg "--REMOVING_AUTO_START_SCRIPT--"
  rm -f "$SKEEN_AUTOSTART_SCRIPT"

  echomsg "--REMOVING_FIREWALL_HOOK_SCRIPT--"
  rm -f "$FIREWALL_HOOK_FILE"

  echomsg "--REMOVING_SKEEN_NAME_SCRIPT--"
  rm -f "$SKEEN_SCRIPT"

  echomsg "--REMOVING_SKEEN_NAME_CACHES--"
  rm -rf "$RUN_DIR"

  echomsg "--DELETE_GROUP_SKEEN_PROC--"
  delgroup "$SKEEN_PROC"

  if [ -f "$SINGBOX_BIN_PATH" ]; then
    while :; do
      # Translation placeholders supply the format specifiers at build time.
      # shellcheck disable=SC3045,SC2182
      printf "--DELETE_S_Y_N--" "$SINGBOX_NAME" >/dev/tty
      read -r opt </dev/tty
      opt=${opt:-n}
      case $opt in
      y | Y) echomsg "--REMOVING_SINGBOX_NAME_BINARY--"; rm -f "$SINGBOX_BIN_PATH"; break ;;
      n | N) echomsg "--FILE_SINGBOX_BIN_PATH_KEPT--"; break ;;
      *) echoerr "--PLEASE_ENTER_Y_YES_OR_N_NO--" ;;
      esac
    done
  fi

  if [ -f "$SERVICE_API_SCRIPT" ] && "$SERVICE_API_SCRIPT" stop; then
    echomsg "--REMOVING_SKEEN_NAME_API_SCRIPT--"; rm -f "$SERVICE_API_SCRIPT"
  fi

  if [ -d "$WORK_DIR" ]; then
    echowarn "--CONFIGURATION_DIRECTORY_WORK_DIR_IS_RETA--"
    echowarn "--IF_YOU_WANT_TO_REMOVE_IT_MANUALLY_RUN_RM--"
  fi
  echook "--SKEEN_NAME_HAS_BEEN_UNINSTALLED_SUCCESSF--"
  echo "$DELIMETER"
  cyan "--FOR_REINSTALLATION_USE--"
  green "--CURL_LS_HTTPS_GITHUB_COM_JINNDI_SKEEN_RE--"
  exit 0
}

accept_uninstall() {
  local max_attempts=3
  local attempt=0
  local option

  while [ $attempt -lt $max_attempts ]; do
    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--UNINSTALL_S_Y_N--" "$SKEEN_NAME" >/dev/tty
    read -r option </dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
    y | Y) uninstall ;;
    n | N) break ;;
    *)
      echoerr "--INVALID_OPTION--"
      attempt=$((attempt + 1))
      ;;
    esac
  done

  show_menu
}

get_fw_mode_data() {
  local type="${1:-}"
  local has_opkgtun port network

  if [ "$type" = "tun" ]; then
    has_opkgtun=$(jsonfilter -i "$SINGBOX_CONFIG" -e '@.inbounds[@.type="'"$type"'"].interface_name' | grep ^opkgtun)
    [ -z "$has_opkgtun" ] && return 0
    echo "tun"
    return 0
  fi

  port=$(jsonfilter -i "$SINGBOX_CONFIG" -e '@.inbounds[@.type="'"$type"'"].listen_port' | head -n1 2>/dev/null)

  [ -z "$port" ] && return 0

  if [ "$type" = "redirect" ]; then
    echo "${port}|tcp"
    return 0
  fi

  network=$(jsonfilter -i "$SINGBOX_CONFIG" -e '@.inbounds[@.type="'"$type"'"].network' | head -n1 2>/dev/null)

  if [ -n "$network" ]; then
    echo "${port}|${network}"
  else
    echo "${port}|tcpudp"
  fi

  return 0
}

has_dns_servers() {
  if jsonfilter -i "$SINGBOX_CONFIG" -e '@.dns.servers[0]' >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

check_port() {
  local port="${1:-}"
  local msg_err

  if [ -n "$port" ]; then
    if netstat -lnt 2>/dev/null | grep -q ":$port\s"; then
      msg_err="--PORT_PORT_IS_IN_USE_FREE_IT_AND_TRY_RUNN--"
      echoerr "$msg_err"; logger_error "$msg_err"
      press_any_key_to_menu 1
    fi
  fi

  return 0
}

load_module() {
  local module="${1:-}"
  local modname="${module%.ko}"

  [ -d "/sys/module/$modname" ] && return 0

  local path_os="${MODULES_OS_DIR}/${KERNEL_OS_V}/${module}"
  local path_entware="${MODULES_ENTWARE_DIR}/${module}"
  local target_path=""

  if [ -f "$path_os" ]; then
    target_path="$path_os"

    if [ ! -f "$path_entware" ]; then
      mkdir -p "$MODULES_ENTWARE_DIR"
      cp "$path_os" "$path_entware" 2>/dev/null
    fi
  elif [ -f "$path_entware" ]; then
    target_path="$path_entware"
  fi

  if [ -n "$target_path" ]; then
    if insmod "$target_path" >/dev/null 2>&1; then
      return 0
    fi
  elif [ "$module" = "xt_owner.ko" ]; then
    return 0
  fi

  echoerr "--MODULE_MODULE_NOT_FOUND_OR_FAILED_TO_LOA--"
  return 1
}

loading_modules() {
  local modules="${1:-xt_TPROXY.ko xt_socket.ko xt_owner.ko xt_comment.ko ip_set_bitmap_port.ko}"
  local err_msg="--PLEASE_INSTALL_ROUTER_COMPONENT_KERNEL_M--"

  KERNEL_OS_V="$(uname -r)"

  for module in $modules; do
    if ! load_module "$module"; then
      echoerr "$err_msg"; logger_error "$err_msg"
      press_any_key_to_menu 1
    fi
  done
}

get_iptables_list() {
  local ipt_list=""

  if command -v iptables >/dev/null 2>&1 &&
     ip -4 addr show scope global | grep -q "inet "; then
    ipt_list="iptables"
  fi

  local v6_disabled=1
  if [ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]; then
    read -r v6_disabled < /proc/sys/net/ipv6/conf/all/disable_ipv6
  fi

  if [ "$v6_disabled" = "0" ] && command -v ip6tables >/dev/null 2>&1; then
    local real_v6
    real_v6=$(ip -6 addr show scope global 2>/dev/null | \
      grep -i 'inet6 [23]' | \
      grep -ivE '2001:db8|2002:|2001:[0-3][0-9a-f]:')

    if [ -n "$real_v6" ] && ip -6 route show default | grep -q "."; then
      ipt_list="${ipt_list:+$ipt_list }ip6tables"
    else
      echowarn "--IPV6_IS_ENABLED_IN_THE_SKEEN_NAME_CONFIG--" >&2
    fi
  fi

  echo "$ipt_list"
}

wait_for_hotspot_prerouting_mangl_chain() {
  local chain="_NDM_HOTSPOT_PREROUTING_MANGL" attempt=1 max_attempts=30

  if iptables -w -t mangle -S "$chain" >/dev/null 2>&1; then
    return 0
  fi

  while [ "$attempt" -le "$max_attempts" ]; do
    logger_notice "--WAITING_FOR_HOTSPOT_CHAIN_ATTEMPT_OF_MAX--"

    if iptables -w -t mangle -S "$chain" >/dev/null 2>&1; then
      logger_notice "--CHAIN_CHAIN_FOUND--"
      return 0
    fi

    [ "$attempt" -eq "$max_attempts" ] && break
    sleep 1
    attempt=$((attempt + 1))
  done

  local err_msg="--CHAIN_CHAIN_DID_NOT_APPEAR_WITHIN_30_CHE--"
  logger_error "$err_msg"; exiterr "$err_msg"
}

get_mark_policy() {
  local mark="" seg=""

  if [ "$POLICY_ENABLED" = "1" ] && [ -n "$POLICY_SEGMENT" ]; then
    seg="$(echo "$POLICY_SEGMENT" | tr '[:upper:]' '[:lower:]')"
    case "$seg" in
      br[0-9]|br[0-9][0-9])
        mark=$(iptables -t mangle -L -v -n | awk -v iface="$seg" '$0 ~ iface && /MARK set/ {print $NF}')
        ;;
      *)
        local err_msg="--SEGMENT_NAME_MUST_START_WITH_BR_FOLLOWED--"
        logger_error "$err_msg"; echowarn "$err_msg" >&2;
      ;;
    esac
  fi

  echo "$mark"
}

check_and_set_route_rules() {
  check_default_route() {
    local target="1.1.1.1"
    [ "$IP_VERSION" = "6" ] && target="2606:4700:4700::1111"

    if [ "$IP_VERSION" = "6" ] && ! ip -6 route show default 2>/dev/null | grep -q .; then
      return 0
    fi

    local mark_arg=""
    [ -n "$SKEEN_MARK_POLICY" ] && mark_arg="mark $SKEEN_MARK_POLICY"
    # shellcheck disable=SC2086
    ip -"$IP_VERSION" route get "$target" $mark_arg 2>/dev/null | grep -Eq "via|dev"
  }

  if ! check_default_route; then
    [ -f "$WAIT_ROUTE_FILE" ] || touch "$WAIT_ROUTE_FILE"

    local msg="--CHECK_YOUR_INTERNET_CONNECTION--"
    # Referenced by the segment-specific error translation.
    # shellcheck disable=SC2034
    local policy_segment_display="${SKEEN_POLICY_SEGMENT:-unknown}"
    [ -n "$SKEEN_MARK_POLICY" ] && msg="--MSG_FOR_SEGMENT_SKEEN_POLICY_SEGMENT--"

    echoerr "$msg"

    press_any_key_to_menu 1
  fi

  case "$SKEEN_FIREWALL_MODE" in
    redirect|tun|dns|none) return 0 ;;
  esac

  ip -"$IP_VERSION" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1 || true
  ip -"$IP_VERSION" rule add fwmark "$TABLE_MARK" lookup "$TABLE_ID" pref "$TABLE_ID" || {
    msg="--FAILED_TO_ADD_IP_RULE_FOR_FAMILY_IP_VERS--"
    echoerr "$msg"; logger_error "$msg"
    press_any_key_to_menu 1
  }
  ip -"$IP_VERSION" route replace local default dev lo table "$TABLE_ID" || {
    msg="--FAILED_TO_REPLACE_LOCAL_ROUTE_IN_TABLE_T--"
    echoerr "$msg"; logger_error "$msg"
    press_any_key_to_menu 1
  }
}

is_valid_ipv4() {
  local addr="${1:-}"
  local ip cidr o1 o2 o3 o4 o

  ip="${addr%%/*}"
  cidr="${addr#*/}"

  IFS=. read -r o1 o2 o3 o4 <<EOF
$ip
EOF

  [ "$o1" ] && [ "$o2" ] && [ "$o3" ] && [ "$o4" ] || return 1

  for o in $o1 $o2 $o3 $o4; do
    [ "$o" -ge 0 ] 2>/dev/null || return 1
    [ "$o" -le 255 ] 2>/dev/null || return 1
  done

  if [ "$ip" != "$addr" ]; then
    case "$cidr" in '' | [0-9] | [1-2][0-9] | 3[0-2]) ;; *) return 1 ;; esac
  fi
}

is_valid_ipv6() {
  local addr="${1:-}"
  local ip_only cidr

  ip_only="${addr%%/*}"
  cidr="${addr#*/}"

  ip -6 route get "$ip_only" >/dev/null 2>&1 || return 1

  if [ "$ip_only" != "$addr" ]; then
    case "$cidr" in
    '' | [0-9] | [1-9][0-9] | 1[0-2][0-8]) ;;
    *) return 1 ;;
    esac
  fi
}

get_validate_ports() {
  local label="${1:-}"
  local input="${2:-}"
  local valid_ports invalid_ports start end p

  input=$(printf '%s' "$input" | tr ',\r' '  ')

  for p in $input; do
    [ -z "$p" ] && continue

    case "$p" in
      *-*) start="${p%-*}"; end="${p#*-}" ;;
      *:*) start="${p%:*}"; end="${p#*:}" ;;
      *)   start="$p";      end="$p"      ;;
    esac

    start=$(printf '%s' "$start" | tr -cd '0-9')
    end=$(printf '%s' "$end" | tr -cd '0-9')

    if [ -z "$start" ] || [ -z "$end" ]; then
      invalid_ports="${invalid_ports:+$invalid_ports }$p"
      continue
    fi

    if [ "$start" -lt 1 ] || [ "$end" -gt 65535 ] || [ "$start" -gt "$end" ]; then
      invalid_ports="${invalid_ports:+$invalid_ports }$p"
    else
      if [ "$start" -eq "$end" ]; then
        valid_ports="${valid_ports:+$valid_ports }$start"
      else
        valid_ports="${valid_ports:+$valid_ports }$start-$end"
      fi
    fi
  done

  if [ -n "$invalid_ports" ]; then
    local msg="--INVALID_LABEL_PORT_S_INVALID_PORTS--"
    logger_warning "$msg"; is_tty && echowarn "$msg" >&2
  fi

  printf '%s' "$valid_ports"
}

get_all_wan_ips() {
  local version="${1:-}"
  local prefix_length="32"
  [ "$version" = "6" ] && prefix_length="128"

  local interfaces
  interfaces=$(ip -"$version" route show table all 2>/dev/null | \
    awk '/default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | sort -u)

  [ -z "$interfaces" ] && return 0

  local result
  result=$(echo "$interfaces" | while read -r dev; do
    [ -z "$dev" ] && continue
    ip -"$version" addr show "$dev" scope global 2>/dev/null | \
      awk -v pref="$prefix_length" '/inet/ {split($2,a,"/"); print a[1] "/" pref}'
  done | sort -u | tr '\n' ' ')

  echo "$result" | xargs
}

get_exclude_addresses() {
  local ip_v="${1:-}"
  local reserved_subnets user_exclude prefix_length_default
  local all_list line subnet invalid_list addr validator

  [ "$ip_v" = "4" ] && prefix_length_default="32" || prefix_length_default="128"

  if [ "$ip_v" = "4" ]; then
    reserved_subnets="$RESERVED_IPV4"
    user_exclude="$(json_get_array '@.firewall.exclude.ipv4_cidr')"
  else
    reserved_subnets="$RESERVED_IPV6"
    user_exclude="$(json_get_array '@.firewall.exclude.ipv6_cidr')"
  fi

  all_list="$(get_all_wan_ips "$ip_v")"

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in
    \#*) continue ;;
    esac
    subnet=$(echo "$line" | cut -d ' ' -f1)
    all_list="$all_list $subnet"
  done <<EOF
$reserved_subnets
EOF

  invalid_list=""

  for addr in $user_exclude; do
    [ -z "$addr" ] && continue
    [ "${addr#*/}" = "$addr" ] && addr="$addr/$prefix_length_default"

    case "$ip_v" in
    4) validator=is_valid_ipv4 ;;
    6) validator=is_valid_ipv6 ;;
    esac

    if $validator "$addr"; then
      all_list="$all_list $addr"
    else
      invalid_list="$invalid_list $addr"
    fi
  done

  [ -n "$invalid_list" ] && {
    is_tty && echowarn "--INVALID_IPV_IP_V_EXCLUDE_INVALID_LIST--"
    logger_warning "--INVALID_IPV_IP_V_EXCLUDE_INVALID_LIST--"
  }

  echo "$all_list" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

add_rule() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  shift 3

  $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
}

get_protocols() {
  local table="${1:-}"

  if [ "$table" = "nat" ]; then
    echo "tcp"
  elif [ "$table" = "mangle" ]; then
    if [ "$SKEEN_TPROXY_NETWORK" = "udp" ]; then
      echo "udp"
    else
      echo "tcp udp"
    fi
  fi
}

chain_exists() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"

  $iptables -w -t "$table" -S "$chain" >/dev/null 2>&1
}

ensure_chain() {
  local iptables="${1:-}" table="${2:-}" chain="${3:-}" flush="${4:-0}"

  if chain_exists "$iptables" "$table" "$chain"; then
    [ "$flush" = "1" ] || return 1
    $iptables -w -t "$table" -F "$chain" 2>/dev/null
  else
    $iptables -w -t "$table" -N "$chain" 2>/dev/null
  fi
}

check_and_create_chain() { ensure_chain "$1" "$2" "$3"; }
create_or_flush_chain() { ensure_chain "$1" "$2" "$3" 1; }

add_skeen_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local type="${4:-}"
  local protocols="${5:-}"
  local connmark_match_opt=""

  add_conntrack_mark() {
    local chain="${1:-}"

    connmark_match_opt="-m connmark --mark $TABLE_MARK"

    add_rule "$iptables" "$table" "$chain" \
      -p tcp -m conntrack --ctstate NEW -j CONNMARK --set-mark "$TABLE_MARK"
  }

  get_connmark_match_opt() {
    local proto="${1:-}"
    if [ -n "$connmark_match_opt" ] && [ "$proto" = "tcp" ]; then
      echo "$connmark_match_opt"
    fi
  }

  case "$type" in
  "ctdir_reply")
    add_rule "$iptables" "$table" "$chain" -m conntrack --ctdir REPLY -j ACCEPT
    ;;

  "socket")
    if printf '%s\n' "$protocols" | grep -q "tcp"; then
      create_or_flush_chain "$iptables" "$table" "$CHAIN_DIVERT" || return 0
      add_rule "$iptables" "$table" "$CHAIN_DIVERT" -j MARK --set-mark "$TABLE_MARK"
      add_rule "$iptables" "$table" "$CHAIN_DIVERT" -j ACCEPT
      add_rule "$iptables" "$table" "$chain" -p tcp -m socket --transparent -g "$CHAIN_DIVERT"
    fi
    ;;

  "intercept_dns")
    for proto in $protocols; do
      if [ "$SKEEN_INTERCEPT_DNS_ENABLED" = "1" ]; then
        # shellcheck disable=SC2086
        add_rule "$iptables" "$table" "$chain" \
          -p "$proto" --dport "$DNS_PORT" -j TPROXY --on-ip "$PROXY_IP" \
          --on-port "$SKEEN_TPROXY_PORT" --tproxy-mark "$TABLE_MARK"
      else
        add_rule "$iptables" "$table" "$chain" -p "$proto" --dport "$DNS_PORT" -j ACCEPT
      fi
    done
    ;;

  "exclude_set")
    if [ "$SKEEN_EXCLUDE_PORT" = "1" ]; then
      for proto in $protocols; do
        add_rule "$iptables" "$table" "$chain" \
          -p "$proto" -m set --match-set "$PORT_EXCLUDE_SET" dst -j ACCEPT
      done
    fi

    add_rule "$iptables" "$table" "$chain" \
      -m set --match-set "${NET_EXCLUDE_SET}${IP_VERSION}" dst -j ACCEPT
    ;;

  "intercept_fakeip")
    if [ "$SKEEN_INTERCEPT_FAKEIP" = "1" ]; then
      add_rule "$iptables" "$table" "$chain" \
        -m set ! --match-set "$FAKEIP_INTERCEPT_SET${IP_VERSION}" dst -j ACCEPT
    elif [ "$SKEEN_INTERCEPT_FAKEIP" = "2" ]; then
      add_rule "$iptables" "$table" "$chain" \
        -m set --match-set "$FAKEIP_CLIENTS_SRC_SET" src \
        -m set ! --match-set "$FAKEIP_INTERCEPT_SET${IP_VERSION}" dst -j ACCEPT
    fi
    ;;

  "tproxy")
    printf '%s\n' "$protocols" | grep -q "tcp" && add_conntrack_mark "$chain"

    for proto in $protocols; do
      # shellcheck disable=SC2046
      add_rule "$iptables" "$table" "$chain" \
        -p "$proto" $(get_connmark_match_opt "$proto") -j TPROXY --on-ip "$PROXY_IP" \
        --on-port "$SKEEN_TPROXY_PORT" --tproxy-mark "$TABLE_MARK"
    done
    ;;

  "keendns_accept")
    local k_port

    k_port=$($iptables -t mangle -L INPUT -v -n | awk '/_NDM_HTTP_INPUT_TLS_/ {split($NF, a, ":"); print a[2]}')
    [ -z "$k_port" ] && return 0

    local rule="-m mark --mark $TABLE_MARK -j ACCEPT -m comment --comment skeen_keendns"

    for proto in $protocols; do
      # shellcheck disable=SC2086
      if ! $iptables -w -t "$table" -C "$chain" -p "$proto" --dport "$k_port" $rule >/dev/null 2>&1; then
        $iptables -w -t "$table" -I "$chain" -p "$proto" --dport "$k_port" $rule
      fi
    done
    ;;

  "redirect")
    add_conntrack_mark "$chain"
    # shellcheck disable=SC2046
    add_rule "$iptables" "$table" "$chain" \
      -p "$protocols" $(get_connmark_match_opt "$protocols") -j REDIRECT --to-port "$SKEEN_REDIRECT_PORT"
    ;;

  "proxy_router_dns")
    if [ "$SKEEN_REDIRECT_DNS_ENABLED" != "1" ]; then
      create_or_flush_chain "$iptables" "$table" "$CHAIN_DNS_OUT" || return 0
      # shellcheck disable=SC2086
      add_rule "$iptables" "$table" "$CHAIN_DNS_OUT" -j MARK --set-mark "$TABLE_MARK"

      for proto in $protocols; do
        add_rule "$iptables" "$table" "$chain" -p "$proto" --dport "$DNS_PORT" -g "$CHAIN_DNS_OUT"
      done
      chain="$CHAIN_DNS_OUT"
    fi
    add_rule "$iptables" "$table" "$chain" -j ACCEPT
    ;;

  "proxy_router_mark")
    for proto in $protocols; do
      add_rule "$iptables" "$table" "$chain" -p "$proto" -j MARK --set-mark "$TABLE_MARK"
    done
    add_rule "$iptables" "$table" "$chain" -j ACCEPT
    ;;
  esac
}

set_chain_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local protocols="${4:-}"

  case "$chain" in
  "$CHAIN_PREROUTING")
    if [ "$table" = "mangle" ]; then
      add_skeen_rules "$iptables" "$table" "$chain" "ctdir_reply" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "socket" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "intercept_dns" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "exclude_set" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "intercept_fakeip" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "tproxy" "$protocols"
      add_skeen_rules "$iptables" "$table" "INPUT" "keendns_accept" "$protocols"
    elif [ "$table" = "nat" ]; then
      add_skeen_rules "$iptables" "$table" "$chain" "ctdir_reply" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "exclude_set" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "intercept_fakeip" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "redirect" "$protocols"
    fi
    ;;

  "$CHAIN_OUTPUT")
    add_skeen_rules "$iptables" "$table" "$chain" "ctdir_reply" "$protocols"

    if [ "$table" = "mangle" ]; then
      add_skeen_rules "$iptables" "$table" "$chain" "proxy_router_dns" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "exclude_set" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "proxy_router_mark" "$protocols"
    elif [ "$table" = "nat" ]; then
      add_skeen_rules "$iptables" "$table" "$chain" "exclude_set" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "redirect" "$protocols"
    fi
    ;;
  esac
}

goto_chain_rules() {
  local iptables="${1:-}" table="${2:-}" chain="${3:-}" target_chain="${4:-}"
  local base="-m conntrack ! --ctstate INVALID -g $target_chain"
  local r1="$base" r2=""

  # shellcheck disable=SC2086
  $iptables -w -t "$table" -S "$target_chain" >/dev/null 2>&1 || return 0

  case "$chain" in
    PREROUTING)
      if [ -n "$SKEEN_MARK_POLICY" ]; then
        r1="-m connmark --mark $SKEEN_MARK_POLICY $base"
        [ "$table" != "$TABLE_REDIRECT" ] && [ "$SKEEN_PROXY_ROUTER" = "1" ] && r2="-m mark --mark $TABLE_MARK $base"
      fi
    ;;
    OUTPUT) r1="-m owner ! --gid-owner $SKEEN_PROC $base" ;;
  esac

  for r in "$r1" "$r2"; do
    [ -z "$r" ] && continue

    # shellcheck disable=SC2086
    $iptables -w -t "$table" -C "$chain" $r >/dev/null 2>&1 || \
    $iptables -w -t "$table" -A "$chain" $r
  done
}

set_proxy_router_rules()  {
  local iptables="${1:-}"
  local table="${2:-}"
  local protocols="${3:-}"

  check_and_create_chain "$iptables" "$table" "$CHAIN_OUTPUT" || return 0
  set_chain_rules "$iptables" "$table" "$CHAIN_OUTPUT" "$protocols"
  goto_chain_rules "$iptables" "$table" OUTPUT "$CHAIN_OUTPUT"
}

release_version_ge5() {
  local major
  major="$(ndmc -c "show version" | awk '/release:/ {print $2}' | cut -d'.' -f1)"

  if [ "$major" -lt 5 ]; then
    echoerr "--RELEASE_VERSION_KEENETICOS_IS_LOWER_THAN--" && return 1
  fi
}

tun_create() {
  local opkgtun_ip="${1:-}"
  local opkgtun_desc="${2:-}"
  local opkgtun_name="OpkgTun0"
  local inface_list opkgtun_ids opkgtun_name_lower

  if [ -z "$opkgtun_ip" ] || [ -z "$opkgtun_desc" ]; then
    echomsg "--USE_THE_FOLLOWING_FORMAT_TO_CREATE_AN_OP--"
    echomsg "--SKEEN_TUN_CREATE_IPV4_NAME--"
    return
  fi

  case "$opkgtun_desc" in
  [!A-Za-z0-9_-]*)
    exiterr "--INVALID_NAME_ALLOWED_CHARACTERS_A_Z_A_Z--"
    ;;
  esac

  if ! is_valid_ipv4 "$opkgtun_ip"; then
    echoerr "--INVALID_IPV4_ADDRESS_SPECIFIED--"
    return
  fi
  opkgtun_ip="${opkgtun_ip%%/*}"

  inface_list="$(ndmc -c show interface)"

  if echo "$inface_list" |
    grep -q "^[[:space:]]*description:[[:space:]]*$opkgtun_desc$"; then
    echoerr "--INTERFACE_NAMED_OPKGTUN_DESC_ALREADY_EXI--"
    return
  fi

  if echo "$inface_list" |
    awk -v ip="$opkgtun_ip" '/^[[:space:]]*address:/ {
        sub(/.*: */, "", $0)
        if ($0 == ip) found=1
    }
    END { exit !found }'; then
    exiterr "--IP_ADDRESS_OPKGTUN_IP_IS_ALREADY_IN_USE--"
  fi

  opkgtun_ids="$(echo "$inface_list" |
    grep 'id:[[:space:]]*OpkgTun' |
    awk -F'OpkgTun' '{print $2}')"

  if [ -n "$opkgtun_ids" ]; then
    local i=0
    while printf '%s\n' "$opkgtun_ids" | grep -qx "$i"; do
      i=$((i + 1))
    done
    opkgtun_name="OpkgTun${i}"
  fi

  opkgtun_name_lower=$(echo "$opkgtun_name" | tr '[:upper:]' '[:lower:]')

  tun_delete_msg() {
    tun_delete "$opkgtun_desc"
    exiterr "--FAILED_TO_SET_1_THE_INTERFACE--"
  }

  ndmc -c interface "$opkgtun_name" || { echoerr "--FAILED_TO_CREATE_THE_INTERFACE--" && return; }
  ndmc -c interface "$opkgtun_name" description "$opkgtun_desc" || tun_delete_msg "description"
  ndmc -c interface "$opkgtun_name" ip address "${opkgtun_ip}/32" || tun_delete_msg "ip address"
  ndmc -c interface "$opkgtun_name" ip tcp adjust-mss pmtu || tun_delete_msg "ip tcp adjust-mss pmtu"
  ndmc -c ip route default "$opkgtun_ip" "$opkgtun_name" || tun_delete_msg "ip route default"
  ndmc -c interface "$opkgtun_name" ip global auto || tun_delete_msg "ip global auto"
  ndmc -c interface "$opkgtun_name" up && ndmc -c system configuration save

  echook "--OPKGTUN_INTERFACE_NAMED_OPKGTUN_DESC_WAS--"
  local opkgtun_name_display interface_name_display
  # Referenced by the interface-instructions translation.
  # shellcheck disable=SC2034
  opkgtun_name_display="$(green "\"$opkgtun_name_lower\"")"
  # Referenced by the interface-instructions translation.
  # shellcheck disable=SC2034
  interface_name_display="$(yellow "\"interface_name\"")"
  echo "--OPKGTUN_INTERFACE_NAME_INSTRUCTIONS--"
}

tun_delete() {
  local opkgtun_desc="${1:-}"
  local opkgtun_name

  if [ -z "$opkgtun_desc" ]; then
    echoerr "--PLEASE_SPECIFY_THE_NAME_OF_THE_OPKGTUN_I--"
    echomsg "--SKEEN_TUN_DELETE_NAME--"
    return
  fi

  if ndmc -c show interface |
    grep -q "^[[:space:]]*description:[[:space:]]*$opkgtun_desc$"; then
    opkgtun_name=$(ndmc -c show interface | awk -v d="$opkgtun_desc" '
      /^[[:space:]]*interface-name:/ { iface=$0; sub(/.*: */, "", iface) }
      /^[[:space:]]*description:/   { desc=$0; sub(/.*: */, "", desc); if(desc==d){print iface; exit} }')

    case "$opkgtun_name" in
    OpkgTun[0-9]*)
      ndmc -c no interface "$opkgtun_name" || { echoerr "Failed to delete the interface" && return; }
      ndmc -c system configuration save
      echook "--INTERFACE_OPKGTUN_NAME_HAS_BEEN_SUCCESSF--"
      ;;
    *)
      echoerr "--INTERFACE_NAME_OPKGTUN_NAME_NOT_OPKGTUN--"
      echoerr "--YOU_CAN_ONLY_DELETE_AN_OPKGTUN_INTERFACE--"
      ;;
    esac
  else
    echoerr "--INTERFACE_NAMED_OPKGTUN_DESC_DOES_NOT_EX--"
  fi
}

tun_list() {
  local opkgtun_list
  opkgtun_list="$(ndmc -c show interface | awk '/^Interface, name = "OpkgTun/ {p=1} /^Interface, name =/ && !/^Interface, name = "OpkgTun/ {p=0} p')"
  [ -z "$opkgtun_list" ] && echomsg "--NO_OPKGTUN_INTERFACES_FOUND--" || echo "$opkgtun_list"
}

set_tun_rules() {
  iptables -w -t filter -S "$CHAIN_TUN" >/dev/null 2>&1 && return 1
  iptables -w -t filter -N "$CHAIN_TUN" 2>/dev/null
  iptables -w -t filter -F "$CHAIN_TUN" 2>/dev/null
  iptables -w -t filter -A "$CHAIN_TUN" -i opkgtun+ -j ACCEPT
  iptables -w -t filter -A "$CHAIN_TUN" -o opkgtun+ -j ACCEPT
  iptables -w -t filter -A INPUT -i opkgtun+ -j "$CHAIN_TUN"
  iptables -w -t filter -A OUTPUT -o opkgtun+ -j "$CHAIN_TUN"
  return 0
}

get_skeen_run_script_cmd() {
  local script="$SKEEN_SCRIPT"

  if [ ! -f "$SKEEN_RUN_SCRIPT" ] || files_differ "$SKEEN_SCRIPT" "$SKEEN_RUN_SCRIPT"; then
    if create_run_dir && cp -fp "$SKEEN_SCRIPT" "$SKEEN_RUN_SCRIPT"; then
      chmod 700 "$SKEEN_RUN_SCRIPT"
      script=$SKEEN_RUN_SCRIPT
    fi
  elif [ -f "$SKEEN_RUN_SCRIPT" ]; then
    script="$SKEEN_RUN_SCRIPT"
  fi

  printf '%s apply_firewall netfilter "$%s"\n' "$script" 'table'
}

write_firewall_hook_header() {
  local iptables_list="${1:-}" tables="${2:-}" skip="${3:-0}"

  echo "#!/bin/sh"; echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"
  printf '%s\n' "printf '%s\\n' \"$iptables_list\" | grep -q \"\$type\" || exit 0"
  if [ "$skip" = "1" ]; then echo "exit 0"; else
    printf '%s\n' "printf '%s\\n' \"$tables\" | grep -q \"\$table\" || exit 0"
  fi
}

prepare_firewall() {
  local complete_msg redirect_data tproxy_data has_opkgtun route_all exclude_ports

  echomsg "--PREPARING_A_FIREWALL--"

  complete_msg="--FIREWALL_PREPARATION_IS_COMPLETE--"

  get_singbox_config

  redirect_data="$(get_fw_mode_data "redirect")"
  SKEEN_REDIRECT_PORT="$(echo "$redirect_data" | cut -d'|' -f1)"

  tproxy_data="$(get_fw_mode_data "tproxy")"
  SKEEN_TPROXY_PORT="$(echo "$tproxy_data" | cut -d'|' -f1)"
  SKEEN_TPROXY_NETWORK="$(echo "$tproxy_data" | cut -d'|' -f2)"

  for port in $SKEEN_REDIRECT_PORT $SKEEN_TPROXY_PORT; do check_port "$port"; done

  has_opkgtun="$(get_fw_mode_data "tun")"
  SKEEN_TUN_ENABLED="0"
  if [ -n "$has_opkgtun" ]; then
    SKEEN_TUN_ENABLED="1"
    for i in /sys/class/net/opkgtun*; do
      [ -e "$i" ] || continue
      ip link set dev "${i##*/}" txqueuelen 2000
    done
  fi

  if [ -n "$SKEEN_TPROXY_PORT" ] && [ "$SKEEN_TPROXY_NETWORK" = "tcpudp" ]; then
    SKEEN_FIREWALL_MODE="tproxy"
    SKEEN_TPROXY_NETWORK="tcp udp"
  elif [ -n "$SKEEN_REDIRECT_PORT" ] && [ -n "$SKEEN_TPROXY_PORT" ] && [ "$SKEEN_TPROXY_NETWORK" != "tcp" ]; then
    SKEEN_FIREWALL_MODE="hybrid"
  elif [ -n "$SKEEN_REDIRECT_PORT" ]; then
    SKEEN_FIREWALL_MODE="redirect"
  elif [ -n "$has_opkgtun" ]; then
    SKEEN_FIREWALL_MODE="tun"
  else
    SKEEN_FIREWALL_MODE="none"
  fi

  [ "$SKEEN_FIREWALL_MODE" != "none" ] && wait_for_hotspot_prerouting_mangl_chain

  cyan "--DETECTED_FIREWALL_MODE_SKEEN_FIREWALL_MO--"

  get_firewall_config

  SKEEN_INTERCEPT_DNS_ENABLED="0"
  SKEEN_REDIRECT_DNS_ENABLED="0"
  SKEEN_REDIRECT_DNS_PORT=""

  if has_dns_servers; then
    local msg_dns_detect="--DETECTED_DNS_CONFIGURATION--"
    if [ "$FIREWALL_REDIRECT_DNS_ENABLED" = "1" ]; then
      if [ -z "$FIREWALL_REDIRECT_DNS_PORT" ]; then
        local msg_err="--DNS_REDIRECT_ENABLED_BUT_PORT_IS_MISSING--"
        echoerr "$msg_err"; logger_error "$msg_err"
        press_any_key_to_menu 1
      fi
      check_port "$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_ENABLED="1"
      SKEEN_REDIRECT_DNS_PORT="$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_USE_POLICY="$FIREWALL_REDIRECT_DNS_USE_POLICY"
      [ "$SKEEN_FIREWALL_MODE" = "none" ] && SKEEN_FIREWALL_MODE="dns"
      cyan "$msg_dns_detect redirect"
    fi

    if [ "$FIREWALL_REDIRECT_DNS_ENABLED" = "1" ] && [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      echowarn "--DNS_REDIRECT_INTERCEPT_CONFLICT_USING_RE--"
    elif [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      case "$SKEEN_FIREWALL_MODE" in
      tproxy | hybrid)
        SKEEN_INTERCEPT_DNS_ENABLED="1"
        cyan "$msg_dns_detect intercept"
      ;;
      *) echowarn "--DNS_INTERCEPT_DOES_NOT_WORK_IN_SKEEN_FIR--" ;;
      esac
    fi
  elif [ "$FIREWALL_REDIRECT_DNS_ENABLED" = "1" ] || [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
    echowarn "--DNS_SETTINGS_PROVIDED_IN_SKEEN_NAME_BUT--"
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ] || [ "$SKEEN_FIREWALL_MODE" = "dns" ]; then
    {
      local tables="filter"
      if [ "$SKEEN_FIREWALL_MODE" = "dns" ]; then
        tables="nat"
        SKEEN_IPTABLES_LIST="$(get_iptables_list)"
      else
        SKEEN_IPTABLES_LIST="iptables"
      fi

      write_firewall_hook_header "$SKEEN_IPTABLES_LIST" "$tables"

      echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""

      [ "$SKEEN_FIREWALL_MODE" = "tun" ] &&
        echo "export SKEEN_TUN_ENABLED=\"$SKEEN_TUN_ENABLED\""

      echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""

      if [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
        loading_modules xt_comment.ko
        [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] && SKEEN_MARK_POLICY="$(get_mark_policy)"
        echo "export SKEEN_REDIRECT_DNS_ENABLED=\"$SKEEN_REDIRECT_DNS_ENABLED\""
        echo "export SKEEN_REDIRECT_DNS_PORT=\"$SKEEN_REDIRECT_DNS_PORT\""
        echo "export SKEEN_REDIRECT_DNS_USE_POLICY=\"$SKEEN_REDIRECT_DNS_USE_POLICY\""
        echo "export SKEEN_MARK_POLICY=\"${SKEEN_MARK_POLICY:-}\""
      fi

      get_skeen_run_script_cmd
    } >"$FIREWALL_HOOK_FILE"

    chmod +x "$FIREWALL_HOOK_FILE"
    echook "$complete_msg"
    return 0
  elif [ "$SKEEN_FIREWALL_MODE" = "none" ]; then
    echook "$complete_msg"
    return 0
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "redirect" ]; then
    SKEEN_FIREWALL_NETWORK="tcp"
  else
    SKEEN_FIREWALL_NETWORK="tcp udp"
  fi

  cyan "--CHECKING_AND_LOADING_MODULES--"
  loading_modules

  SKEEN_MARK_POLICY="$(get_mark_policy)"

  route_all=1
  if [ "$POLICY_ENABLED" != "1" ]; then
    cyan "--SEGMENT_DISABLED_ON_SKEEN_JSON--"
  elif [ -z "$POLICY_SEGMENT" ]; then
    cyan "--SEGMENT_NAME_NOT_SET--"
  elif [ -z "$SKEEN_MARK_POLICY" ]; then
    echowarn "--SEGMENT_POLICY_POLICY_SEGMENT_IS_NOT_AVA--"
  else
    cyan "--SEGMENT_POLICY_ROUTING_POLICY_SEGMENT--"
    route_all=0
  fi
  [ "$route_all" = 1 ] && echowarn "--FULL_DEVICE_ROUTING_YOU_CAN_CONFIGURE_TH--"

  SKEEN_PROXY_ROUTER="0"
  [ "$FIREWALL_PROXY_ROUTER" = "1" ] && SKEEN_PROXY_ROUTER="1"

  SKEEN_IPTABLES_LIST="$(get_iptables_list)"

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    local msg_err="--NO_SUPPORTED_IPTABLES_FOUND--"
    echoerr "$msg_err"; logger_error "$msg_err"
    press_any_key_to_menu 1
  fi

  setup_port_set() {
    local name_set="${1:-}"
    local ports="${2:-}"

    ipset create "$name_set" bitmap:port range 0-65535 -exist
    ipset flush "$name_set"

    if [ -n "$ports" ]; then
      {
        for p in $ports; do
          printf "add %s %s\n" "$name_set" "$p"
        done
      } | ipset restore
    fi
  }

  SKEEN_EXCLUDE_PORT="0"
  exclude_ports="$(get_validate_ports "exclude" "$(json_get_array '@.firewall.exclude.port')")"

  if [ -n "$exclude_ports" ]; then
    setup_port_set "$PORT_EXCLUDE_SET" "$exclude_ports"
    ipset del "$PORT_EXCLUDE_SET" 443 -! 2>/dev/null
    ipset del "$PORT_EXCLUDE_SET" 80 -! 2>/dev/null
    SKEEN_EXCLUDE_PORT="1"
  fi

  setup_net_ipset() {
    local ipver="${1:-}"
    local family="${2:-}"
    local name_set="${NET_EXCLUDE_SET}${ipver}"

    ipset create "$name_set" hash:net family "$family" -exist
    ipset flush "$name_set"

    get_exclude_addresses "$ipver" | tr ' ' '\n' | {
      while read -r addr; do
        [ -n "$addr" ] && printf "add %s %s -exist\n" "$name_set" "$addr"
      done
    } | ipset restore
  }

  if printf '%s\n' "$SKEEN_IPTABLES_LIST" | grep -q "iptables"; then
    setup_net_ipset 4 inet
  fi

  if [ "$NETWORK_IPV6" = "1" ] && printf '%s\n' "$SKEEN_IPTABLES_LIST" | grep -q "ip6tables"; then
    setup_net_ipset 6 inet6
  fi

  setup_fakeip_ipset() {
    if [ ! -f "$FAKEIP_INTERCEPT_FILE" ]; then
      touch "$FAKEIP_INTERCEPT_FILE" || {
        echoerr "--ERROR_CREATING_FILE_FAKEIP_INTERCEPT_FIL--"; return 1
      }
    fi

    local temp_file

    temp_file=$(mktemp) || {
      echoerr "--ERROR_CREATING_TEMPORARY_FILE_FOR_IPSET--"; return 1
    }

    {
      echo "create ${FAKEIP_INTERCEPT_SET}4 hash:net family inet maxelem 65536 -exist"
      echo "add ${FAKEIP_INTERCEPT_SET}4 198.18.0.0/15 -exist"
      if [ "$NETWORK_IPV6" = "1" ]; then
        echo "create ${FAKEIP_INTERCEPT_SET}6 hash:net family inet6 maxelem 65536 -exist"
        echo "add ${FAKEIP_INTERCEPT_SET}6 fd00::/8 -exist"
      fi

      if [ -s "$FAKEIP_INTERCEPT_FILE" ]; then
        awk -v S="$FAKEIP_INTERCEPT_SET" -v V6="$NETWORK_IPV6" '
          { sub(/#.*/, ""); gsub(/^[ \t]+|[ \t]+$/, "") }
          $0 == "" { next }
          /:/  { if (V6 == "1") print "add " S "6 " $0 " -exist"; next }
               { print "add " S "4 " $0 " -exist" }
        ' "$FAKEIP_INTERCEPT_FILE"
      fi
    } > "$temp_file" || {
      rm -f "$temp_file"
      echoerr "--ERROR_WRITING_TO_TEMPORARY_FILE_FOR_IPSE--"
      return 1
    }

    ipset restore < "$temp_file"
    rm -f "$temp_file"
    return 0
  }

  SKEEN_INTERCEPT_FAKEIP="0"
  if [ "$FIREWALL_INTERCEPT_FAKEIP" = "1" ]; then
    if [ "$SKEEN_INTERCEPT_DNS_ENABLED" = "1" ] || [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
      if setup_fakeip_ipset; then
        SKEEN_INTERCEPT_FAKEIP="1"

        local clients_src clients_src_count clients_count
        clients_src="$(json_get_array '@.firewall.intercept.fakeip.clients')"

        if [ -n "$clients_src" ]; then
          ipset create "$FAKEIP_CLIENTS_SRC_SET" hash:net family inet maxelem 100 -exist
          ipset flush "$FAKEIP_CLIENTS_SRC_SET"

          echo "$clients_src" | {
            while read -r addr; do
              [ -n "$addr" ] && printf "add %s %s -exist\n" "$FAKEIP_CLIENTS_SRC_SET" "$addr"
            done
          } | ipset restore

          # Both values are interpolated by the FakeIP status translations.
          # shellcheck disable=SC2034
          clients_count="$(echo "$clients_src" | wc -l)"
          # shellcheck disable=SC2034
          clients_src_count="--FAKEIP_CLIENT_COUNT--"
          SKEEN_INTERCEPT_FAKEIP="2"
        fi
        cyan "--FAKEIP_INTERCEPTION_ENABLED_CLIENTS_SRC--"
      else
        echoerr "--FAILED_TO_CONFIGURE_FAKEIP_INTERCEPTION--"
      fi
    else
      ipset destroy "${FAKEIP_INTERCEPT_SET}4" -exist 2>/dev/null
      ipset destroy "${FAKEIP_INTERCEPT_SET}6" -exist 2>/dev/null
      echowarn "$SINGBOX_NAME DNS не настроен, опция intercept.fakeip не будет работать!"
    fi
  fi

  {
    local postfix_tables=""
    [ "$SKEEN_TUN_ENABLED" = "1" ] && postfix_tables="|filter"
    [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ] && postfix_tables="${postfix_tables}|nat"

    local redirect="${TABLE_REDIRECT}${postfix_tables}"
    local hybrid="${TABLE_REDIRECT}|${TABLE_TPROXY}${postfix_tables}"
    local tproxy="${TABLE_TPROXY}${postfix_tables}"

    local hook_tables="" skip_hook=0
    case "$SKEEN_FIREWALL_MODE" in
      hybrid) hook_tables="$hybrid" ;; tproxy) hook_tables="$tproxy" ;; redirect) hook_tables="$redirect" ;;
      *) skip_hook=1 ;;
    esac
    write_firewall_hook_header "$SKEEN_IPTABLES_LIST" "$hook_tables" "$skip_hook"

    echo "export SKEEN_REDIRECT_PORT=\"$SKEEN_REDIRECT_PORT\""
    echo "export SKEEN_TPROXY_PORT=\"$SKEEN_TPROXY_PORT\""
    echo "export SKEEN_TPROXY_NETWORK=\"$SKEEN_TPROXY_NETWORK\""
    echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""
    echo "export SKEEN_FIREWALL_NETWORK=\"$SKEEN_FIREWALL_NETWORK\""
    echo "export SKEEN_POLICY_SEGMENT=\"$POLICY_SEGMENT\""
    echo "export SKEEN_MARK_POLICY=\"$SKEEN_MARK_POLICY\""
    echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""
    echo "export SKEEN_EXCLUDE_PORT=\"$SKEEN_EXCLUDE_PORT\""
    echo "export SKEEN_INTERCEPT_FAKEIP=\"$SKEEN_INTERCEPT_FAKEIP\""
    echo "export SKEEN_INTERCEPT_DNS_ENABLED=\"$SKEEN_INTERCEPT_DNS_ENABLED\""
    echo "export SKEEN_REDIRECT_DNS_ENABLED=\"$SKEEN_REDIRECT_DNS_ENABLED\""
    echo "export SKEEN_REDIRECT_DNS_PORT=\"$SKEEN_REDIRECT_DNS_PORT\""
    echo "export SKEEN_REDIRECT_DNS_USE_POLICY=\"$SKEEN_REDIRECT_DNS_USE_POLICY\""
    echo "export SKEEN_TUN_ENABLED=\"$SKEEN_TUN_ENABLED\""
    echo "export SKEEN_PROXY_ROUTER=\"$SKEEN_PROXY_ROUTER\""
    get_skeen_run_script_cmd
  } >"$FIREWALL_HOOK_FILE"

  chmod +x "$FIREWALL_HOOK_FILE"

  echook "$complete_msg"
}

check_hook_table() {
  local match="${1:-}"
  local hook_table="${2:-}"

  [ -z "$hook_table" ] && return 0

  if [ -n "$match" ]; then
    printf '%s\n' "$match" | grep -q "$hook_table" || return 1
  fi
}

apply_firewall() {
  local hook_table="${1:-}"
  local check iptables eth_subnets set_name tables protocols dns_rule_added

  check=$(echo "$SKEEN_IPTABLES_LIST" | sed 's/iptables//g; s/ip6tables//g; s/ //g')
  if [ -n "$check" ] || [ -z "$SKEEN_IPTABLES_LIST" ]; then
    local iptables_display
    # Referenced by the unknown-iptables error translation.
    # shellcheck disable=SC2034
    iptables_display="${iptables:-unknown}"
    local msg_err="--UNKNOWN_IPTABLES_IPTABLES--"
    logger_error "$msg_err"; echoerr "$msg_err"
    press_any_key_to_menu 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" != "none" ] || [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
    echomsg "--APPLYING_FIREWALL_RULES--"
  fi

  # DNS redirect
  if [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ] && check_hook_table "nat" "$hook_table"; then
    local mark_option=""
    [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] && [ -n "$SKEEN_MARK_POLICY" ] &&
      mark_option="-m mark --mark $SKEEN_MARK_POLICY"

    local args="-i br+ $mark_option -m pkttype --pkt-type unicast \
      --dport $DNS_PORT -j REDIRECT --to-ports $SKEEN_REDIRECT_DNS_PORT \
      -m comment --comment skeen_dns"

    for iptables in $SKEEN_IPTABLES_LIST; do
      dns_rule_added=0
      for proto in tcp udp; do
        # shellcheck disable=SC2086
        if ! $iptables -w -t nat -C "$CHAIN_DNS" -p "$proto" $args >/dev/null 2>&1; then
          if $iptables -w -t nat -I "$CHAIN_DNS" -p "$proto" $args; then dns_rule_added=1; fi
        fi
      done
      [ "$dns_rule_added" = "1" ] && log_firewall_update "$iptables" "$hook_table"
    done
  fi

  # TUN
  if [ "$SKEEN_TUN_ENABLED" = "1" ] && check_hook_table "filter" "$hook_table"; then
    if set_tun_rules; then log_firewall_update iptables "$hook_table"; fi
  fi

  # Exclude modes && tables
  case "$SKEEN_FIREWALL_MODE" in tun|dns|none) return 0 ;; esac
  check_hook_table "nat|mangle" "$hook_table" || return 0

  # Redirect, Tproxy and Hybrid modes
  for iptables in $SKEEN_IPTABLES_LIST; do
    if [ "$iptables" = "iptables" ]; then
      IP_VERSION="4"
      PROXY_IP="127.0.0.1"
    elif [ "$iptables" = "ip6tables" ]; then
      IP_VERSION="6"
      PROXY_IP="::1"
    fi

    check_and_set_route_rules

    if [ -f "$WAIT_ROUTE_FILE" ]; then
      eth_subnets="$(get_all_wan_ips "$IP_VERSION")"
      set_name="${NET_EXCLUDE_SET}${IP_VERSION}"

      for ip in $eth_subnets; do
        ipset add "$set_name" "$ip" -exist
      done
    fi

    case "$SKEEN_FIREWALL_MODE" in
      hybrid) tables="$TABLE_TPROXY $TABLE_REDIRECT" ;;
      tproxy) tables="$TABLE_TPROXY" ;;
      redirect) tables="$TABLE_REDIRECT" ;;
      *) tables="" ;;
    esac

    for table in $tables; do
      check_hook_table "$table" "$hook_table" || continue
      check_and_create_chain "$iptables" "$table" "$CHAIN_PREROUTING" || return 0
      protocols="$(get_protocols "$table")"
      set_chain_rules "$iptables" "$table" "$CHAIN_PREROUTING" "$protocols"
      goto_chain_rules "$iptables" "$table" PREROUTING "$CHAIN_PREROUTING"
      [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$table" "$protocols"
    done
    log_firewall_update "$iptables" "$hook_table"
  done

  [ -f "$WAIT_ROUTE_FILE" ] && rm -f "$WAIT_ROUTE_FILE"

  echook "--FIREWALL_RULES_APPLIED_SUCCESSFULLY--"
}

clean_firewall() {
  if [ -n "$is_check_update" ] && [ "$is_check_update" -eq 1 ]; then
    "$SKEEN_RUN_SCRIPT" clean_firewall update
    return 0
  fi

  echo "$DELIMETER"
  echomsg "--CLEANING_FIREWALL_RULES--"

  clean_chain() {
    local iptables="${1:-}"
    local table="${2:-}"
    local chain="${3:-}"
    local parent="${4:-}"

    if ! chain_exists "$iptables" "$table" "$chain"; then
      return 0
    fi

    $iptables -w -t "$table" -S "$parent" 2>/dev/null |
      grep -w "$chain" | sed "s/^-A/$iptables -w -t $table -D/" | sh 2>/dev/null

    $iptables -w -t "$table" -F "$chain" 2>/dev/null
    $iptables -w -t "$table" -X "$chain" 2>/dev/null
  }

  # 1. tun rules
  for ch in INPUT OUTPUT; do
    clean_chain "iptables" "filter" "$CHAIN_TUN" "$ch"
  done

  for ipt_cmd in iptables ip6tables; do
    # 2. DNS redirect
    $ipt_cmd -w -t nat -S $CHAIN_DNS 2>/dev/null | \
    sed -n "s/^-A /${ipt_cmd} -w -t nat -D /p" | grep "skeen_dns" | sh 2>/dev/null

    # 3. KeenDNS accept
    $ipt_cmd -w -t mangle -S INPUT 2>/dev/null | \
    sed -n "s/^-A /${ipt_cmd} -w -t mangle -D /p" | grep "skeen_keendns" | sh 2>/dev/null

    # 4. skeen PREROUTING & skeen_mask OUTPUT
    for table in nat mangle; do
      # PREROUTING chains
      for ch in "$CHAIN_PREROUTING" "$CHAIN_DIVERT"; do
        clean_chain "$ipt_cmd" "$table" "$ch" PREROUTING
      done

      # OUTPUT chains
      for ch in "$CHAIN_OUTPUT" "$CHAIN_DNS_OUT"; do
        clean_chain "$ipt_cmd" "$table" "$ch" OUTPUT
      done
    done
  done

  # 5. routing cleanup
  for ip_ver in 4 6; do
    ip -"$ip_ver" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1 || true
    ip -"$ip_ver" route flush table "$TABLE_ID" 2>/dev/null
  done

  # 6. ipset cleanup
  if command -v ipset >/dev/null 2>&1; then
    for ip_ver in 4 6; do
      for name in $NET_EXCLUDE_SET $FAKEIP_INTERCEPT_SET; do
        set_name="${name}${ip_ver}"
        ipset flush "$set_name" -exist 2>/dev/null
        ipset destroy "$set_name" -exist 2>/dev/null
      done
    done

    for set_name in "$PORT_EXCLUDE_SET" "$FAKEIP_CLIENTS_SRC_SET"; do
      ipset flush "$set_name" -exist 2>/dev/null
      ipset destroy "$set_name" -exist 2>/dev/null
    done
  fi

  # 7. cleanup hook
  rm -f "$FIREWALL_HOOK_FILE" 2>/dev/null

  echook "--FIREWALL_CLEANUP_COMPLETED--"
}

apply_sysctl_network_tuning() {
  _get_ct_max() {
    local mem_mb
    mem_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
    local ct=65536
    [ "$mem_mb" -le 128 ] && ct=8192 || \
    [ "$mem_mb" -le 256 ] && ct=16384 || \
    [ "$mem_mb" -le 512 ] && ct=32768
    [ "${1:-}" ] && ct=$((ct * 15 / 10))
    echo "$ct"
  }

  get_network_config
  local ct_max_base ct_max_tuned
  ct_max_base="$(_get_ct_max)"
  ct_max_tuned="$([ "$NETWORK_TUNING" = "1" ] && _get_ct_max "1" || echo "$ct_max_base")"

  # TProxy/TUN (needed for TUN/TProxy)
  sysctl -q -w \
    net.ipv4.ip_forward=1 \
    net.ipv4.conf.all.src_valid_mark=0 \
    net.ipv4.conf.all.rp_filter=0 \
    net.ipv4.conf.default.rp_filter=0 \
    net.ipv4.conf.all.route_localnet=1 \
    net.ipv4.conf.lo.route_localnet=1 \
    net.ipv4.ip_nonlocal_bind=1 \
    net.netfilter.nf_conntrack_max="$ct_max_base"

  # IPv6 support
  if [ -f /proc/net/if_inet6 ]; then
    if [ "$NETWORK_IPV6" = "0" ]; then
      sysctl -q -w net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
      for iface in /sys/class/net/lo /sys/class/net/t2s* /sys/class/net/ezcfg0; do
        [ -e "$iface" ] && sysctl -q -w "net.ipv6.conf.${iface##*/}.disable_ipv6=0"
      done
    else
      sysctl -q -w net.ipv6.conf.all.disable_ipv6=0 net.ipv6.conf.default.disable_ipv6=0 \
        net.ipv6.conf.all.forwarding=1 net.ipv6.conf.default.forwarding=1
    fi
  fi

  [ "$NETWORK_TUNING" = "1" ] || return 0

  # Interface Queues & Keep Alive & Latency / TCP Behavior
  sysctl -q -w \
    net.core.netdev_max_backlog=2000 \
    net.core.somaxconn=512 \
    net.ipv4.tcp_keepalive_time=60 \
    net.ipv4.tcp_keepalive_probes=6 \
    net.ipv4.tcp_keepalive_intvl=10 \
    net.netfilter.nf_conntrack_max="$ct_max_tuned" \
    net.netfilter.nf_conntrack_tcp_timeout_established=1800 \
    net.netfilter.nf_conntrack_udp_timeout=60 \
    net.netfilter.nf_conntrack_udp_timeout_stream=180 \
    net.netfilter.nf_conntrack_checksum=0 \
    net.ipv4.tcp_fastopen=3 \
    net.ipv4.tcp_mtu_probing=1 \
    net.ipv4.tcp_slow_start_after_idle=0 \
    net.ipv4.tcp_sack=1 \
    net.ipv4.tcp_syncookies=1 \
    net.ipv4.tcp_tw_reuse=1 \
    net.ipv4.tcp_fin_timeout=15 \
    net.ipv4.tcp_timestamps=1 \
    net.ipv4.tcp_max_syn_backlog=512 \
    net.ipv4.tcp_max_tw_buckets=8192 \
    net.ipv4.ip_local_port_range="10000 60001"

  # Only for ARM & RAM >= 512MB
  [ "$ct_max_base" -gt 32768 ] || return 0
  case "$(uname -m)" in
    aarch64|arm*)
      sysctl -q -w \
        net.core.rmem_max=4194304 \
        net.core.wmem_max=4194304 \
        net.core.rmem_default=229376 \
        net.core.wmem_default=229376 \
        net.ipv4.tcp_moderate_rcvbuf=1 \
        net.ipv4.tcp_rmem="4096 87380 4194304" \
        net.ipv4.tcp_wmem="4096 65536 4194304" \
        net.ipv4.udp_rmem_min=8192 \
        net.ipv4.udp_wmem_min=8192 \
        net.ipv4.tcp_limit_output_bytes=262144
      ;;
  esac
}

get_ulimit_n() {
  if [ -r /proc/sys/fs/file-max ]; then
    file_max=$(cat /proc/sys/fs/file-max)
    ulimit_n=$((file_max / 2))
  else
    # shellcheck disable=SC3045
    ulimit_n=$(ulimit -Hn)
  fi

  [ "$ulimit_n" -lt 4096 ] && ulimit_n=4096

  echo "$ulimit_n"
}

start_singbox() {
  local timeout=40
  local status_start msg

  echomsg "--STARTING_SINGBOX_NAME--"

  # shellcheck disable=SC3045
  ulimit -n "$(get_ulimit_n)" || exiterr "--FAILED_TO_SET_ULIMIT_N--"

  start-stop-daemon -S -b -m -p "$SINGBOX_PID_FILE" -x "$SINGBOX_BIN" \
    -c "root:${SKEEN_PROC}" -- run -D "$WORK_DIR" -c "$SINGBOX_CONFIG"
  status_start=$?

  if [ $status_start -ne 0 ]; then
    rm -f "$SINGBOX_PID_FILE"
    msg="--FAILED_TO_START_SINGBOX_NAME--"
    echoerr "$msg"; logger_error "$msg"
    return 1
  fi

  while ! is_running && [ $timeout -gt 0 ]; do
    usleep 250000
    timeout=$((timeout - 1))
  done

  if ! is_running; then
    rm -f "$SINGBOX_PID_FILE"
    msg="--SINGBOX_NAME_DID_NOT_START_IN_TIME--"
    echoerr "$msg"; logger_error "$msg"
    return 1
  fi

  [ -s "$SINGBOX_PID_FILE" ] && renice -3 -p "$(cat "$SINGBOX_PID_FILE")" >/dev/null 2>&1

  echook "--SINGBOX_NAME_STARTED--"; logger_notice "--SINGBOX_NAME_STARTED--"
  return 0
}

start() {
  get_singbox_config

  local no_sb_found_msg="--SINGBOX_NAME_BINARY_NOT_FOUND_PLEASE_INS--"

  if [ "$CALLER" = "init" ]; then
    if get_service_api_config && [ "$SERVICE_API_AUTO_START" = "1" ]; then
      [ -f "$SERVICE_API_SCRIPT" ] && "$SERVICE_API_SCRIPT" start || true
    fi
    get_auto_start_config
    if [ "$AUTO_START_ENABLED" != "1" ]; then
      return 0
    fi
  elif [ ! -f "$SINGBOX_BIN" ]; then
    echoerr "$no_sb_found_msg"; press_any_key_to_menu 1
  elif is_running; then
    echook "--SINGBOX_NAME_ALREADY_STARTED--"; return 0
  fi

  if [ "$on_restart" != "1" ]; then
    if ! check_config; then [ "$CALLER" != "init" ] && press_any_key_to_menu 1; fi
    echo "$DELIMETER"
  fi

  apply_sysctl_network_tuning

  prepare_firewall

  if [ "$SKEEN_FIREWALL_MODE" != "none" ] && [ "$CALLER" != "init" ]; then
    echo "$DELIMETER" && apply_firewall
  fi

  create_skeen_group
  [ $? -eq 2 ] && echo "$DELIMETER"

  if [ ! -f "$SINGBOX_BIN" ]; then
    logger_error "$no_sb_found_msg";
  else
    echo "$DELIMETER"
    start_singbox || {
      if [ "$CALLER" != "init" ]; then
        clean_firewall; press_any_key_to_menu 1
      fi
    }
  fi

  return 0
}

stop_singbox() {
  local timeout=40
  local msg

  echomsg "--STOPPING_SINGBOX_NAME--"

  if ! is_running; then
    echook "--SINGBOX_NAME_ALREADY_STOPPED--"
    return 0
  fi

  if ! start-stop-daemon -K -p "$SINGBOX_PID_FILE" >/dev/null 2>&1; then
    msg="--FAILED_TO_SEND_STOP_SIGNAL_TO_SINGBOX_NA--"
    echoerr "$msg"; logger_error "$msg"
    rm -f "$SINGBOX_PID_FILE"
    return 1
  fi

  while is_running && [ $timeout -gt 0 ]; do
    usleep 250000
    timeout=$((timeout - 1))
  done

  if is_running; then
    msg="--SINGBOX_NAME_DID_NOT_STOP_IN_TIME--"
    echoerr "$msg"; logger_error "$msg"
    return 1
  fi

  rm -f "$SINGBOX_PID_FILE"

  msg="--SINGBOX_NAME_STOPPED--"
  echook "$msg"; logger_notice "$msg"
  return 0
}

stop() {
  if [ "$on_restart" != "1" ]; then
    if ! check_config; then press_any_key_to_menu 1; fi; echo "$DELIMETER"
  fi
  if stop_singbox && clean_firewall; then
    [ "$on_restart" = "1" ] && echo "$DELIMETER"
    return 0
  else
    return 1
  fi
}

kill_proc() {
  if ! is_running; then
    echook "--SINGBOX_NAME_IS_NOT_RUNNING--"
    return 0
  fi

  echomsg "--KILLING_SKEEN_PROC--"
  if start-stop-daemon -K -s 9 -p "$SINGBOX_PID_FILE" >/dev/null 2>&1; then
    rm -f "$SINGBOX_PID_FILE"
    clean_firewall
    echook "--SINGBOX_NAME_STOPPED_SUCCESSFULLY--"
  else
    echoerr "--FAILED_TO_FORCE_STOP_SINGBOX_NAME--"
    return 1
  fi
}

version() {
  local sk_version sk_api_version sb_version
  get_singbox_config
  sk_version="$(get_current_version "skeen")"
  sk_api_version="$(get_current_version "skeen-api")"
  sb_version="$(get_current_version "sing")"
  { [ -z "$sk_api_version" ] && sk_api_version="$(red "--NOT_FOUND--")"; } || sk_api_version="$(cyan "$sk_api_version")"
  { [ -z "$sb_version" ] && sb_version="$(red "--NOT_FOUND--")"; } || sb_version="$(cyan "v${sb_version}")"
  if [ "$CALLER" = "cli" ]; then
    printf "${SKEEN_NAME}: %s\n" "$(cyan "v${sk_version}")"
    printf "${SKEEN_NAME} API: %s\n" "$(cyan "$sk_api_version")"
    printf "${SINGBOX_NAME}: %s\n" "$sb_version" && [ -f "$SINGBOX_BIN" ] &&
      $SINGBOX_BIN version | sed -nE '/^(Environment|Tags|Revision|CGO):/p'
  fi
}

switch_state() {
  if is_running; then
    stop
  else
    start
  fi
  press_any_key_to_menu
}

restart() {
  if ! check_config; then press_any_key_to_menu 1; fi
  echo "$DELIMETER"; on_restart=1
  stop || press_any_key_to_menu 1
  start || press_any_key_to_menu 1
  on_restart=0; press_any_key_to_menu
}

reload() {
  if ! check_config; then press_any_key_to_menu 1; fi; echo "$DELIMETER"
  get_singbox_config
  stop_singbox && start_singbox || return 1
}

proc_uptime() {
  local pid="${1:-}"
  local up stat runtime

  [ -r "/proc/$pid/stat" ] || return 1

  read -r up _ </proc/uptime
  read -r stat <"/proc/$pid/stat"
  stat="${stat#*) }"

  # shellcheck disable=SC2086
  set -- $stat

  runtime=$((${up%.*} - ${20:-0} / 100))

  printf "%dd %dh %dm\n" \
    $((runtime / 86400)) \
    $(((runtime % 86400) / 3600)) \
    $(((runtime % 3600) / 60))
}

status() {
  local pid mem_used mem_peak threads

  [ -f "$SINGBOX_PID_FILE" ] && pid="$(cat "$SINGBOX_PID_FILE")"

  printf '\033[1m%s\033[0m\n' "$SINGBOX_NAME"
  if [ -n "$pid" ]; then
    # shellcheck disable=SC2046
    set -- $(awk '$1=="VmRSS:"{r=$2} $1=="VmHWM:"{h=$2} $1=="Threads:"{t=$2} END{print r,h,t}' "/proc/$pid/status")
    mem_used="${1:-0}"
    mem_peak="${2:-0}"
    threads="${3:-0}"

    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--STATUS_S_N--" "running"
    printf 'PID: %s\n' "$pid"
    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--UPTIME_S_N--" "$(proc_uptime "$pid")"
    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--MEMORY_S_MB_PEAK_S_MB_N--" "$((mem_used / 1024))" "$((mem_peak / 1024))"
    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--THREADS_S_N--" "$threads"
    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--DESCRIPTORS_S_LIMIT_S_N--" "$(find "/proc/${pid}/fd" -type l 2>/dev/null | wc -l)" "$(awk '/Max open files/ {print $5}' "/proc/${pid}/limits" 2>/dev/null)"
  else
    # Translation placeholders supply the format specifiers at build time.
    # shellcheck disable=SC3045,SC2182
    printf "--STATUS_S_N--" "stopped"
  fi

  if [ -f "$SERVICE_API_SCRIPT" ]; then
    printf '\n\033[1m%s\033[0m\n' "$SKEEN_NAME API"
    "$SERVICE_API_SCRIPT" status
  fi
}

status_json() {
  local running="false" mode="unknown" sb_version="unknown" pid line version_data

  if [ -f "$SINGBOX_PID_FILE" ]; then
    IFS= read -r pid < "$SINGBOX_PID_FILE" 2>/dev/null
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && running="true"
  fi

  if [ -f "$FIREWALL_HOOK_FILE" ]; then
    while IFS='=' read -r line mode; do
      [ "$line" = "export SKEEN_FIREWALL_MODE" ] || continue
      mode="${mode#\"}"
      mode="${mode%\"}"
      break
    done < "$FIREWALL_HOOK_FILE"
    [ -z "$mode" ] && mode="unknown"
  fi

  if [ ! -f "$SINGBOX_RUN_VERSION" ]; then
    get_singbox_config ""
    sb_version="$(get_current_version "sing")"
  else
    IFS= read -r version_data < "$SINGBOX_RUN_VERSION" 2>/dev/null
    sb_version="${version_data##*|}"
  fi
  [ -z "$sb_version" ] && sb_version="unknown"

  printf '{"running":%s,"version":"%s","mode":"%s","sb_version":"%s"}\n' \
    "$running" "${SKEEN_VERSION:-unknown}" "$mode" "${sb_version:-unknown}"
}

print_aligned_table() {
  LC_ALL=C awk -v max_width="${1:-28}" -F'|' '
    function trim(s) { sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
    function width(s) { gsub(/[\200-\277]/,"",s); return length(s) }
    function repeat(c,n,o,i) { for(i=0;i<n;i++) o=o c; return o }
    function border(i) { printf "+"; for(i=1;i<=columns;i++) printf "%s+",repeat("-",widths[i]+2); printf "\n" }
    function wrap(r,c,s,w,n,i,x,l) {
      n=split(s,w,/[ \t]+/); l=1
      for(i=1;i<=n;i++) {
        if(x=="") x=w[i]
        else if(width(x " " w[i])<=widths[c]) x=x " " w[i]
        else { wrapped[r,c,l++]=x; x=w[i] } }
      wrapped[r,c,l]=x; if(l>row_lines[r]) row_lines[r]=l }
    { rows=NR; if(NF>columns) columns=NF
      for(i=1;i<=NF;i++) { cells[NR,i]=trim($i); w=width(cells[NR,i]); if(w>max_width) w=max_width; if(w>widths[i]) widths[i]=w } }
    END {
      if(!rows) exit
      for(r=1;r<=rows;r++) for(c=1;c<=columns;c++) wrap(r,c,cells[r,c])
      border()
      for(r=1;r<=rows;r++) {
        for(l=1;l<=row_lines[r];l++) {
          printf "|"; for(c=1;c<=columns;c++) { v=wrapped[r,c,l]; printf " %s%s |",v,repeat(" ",widths[c]-width(v)) }
          printf "\n" }
        if(r==1) border() }
      border() }
  ' | while IFS= read -r line; do
        case "$line" in +*) cyan "$line" ;; "--PROTOCOL--"* | "--TABLE_STATE_COLUMN--"* | "--MARK--"* | "--COUNTER--"* | "--TCP_STATE--"*) cyan "$line" ;; *) printf '%s\n' "$line" ;; esac
      done
}

show_connstat() {
  local ct_count ct_max percent conntrack_report ct_summary mark_summary
  local conntrack_stats tcp_summary

  check_tty

  cyan_bold "--CONNECTION_DIAGNOSTICS--"
  printf '\n'
  if [ -r /proc/sys/net/netfilter/nf_conntrack_count ] && [ -r /proc/sys/net/netfilter/nf_conntrack_max ]; then
    if command -v conntrack >/dev/null 2>&1; then ct_count="$(conntrack -C 2>/dev/null)"; fi
    case "$ct_count" in
      '' | *[!0-9]*) ct_count="$(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null)" ;;
    esac
    ct_max="$(cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null)"
    case "$ct_count:$ct_max" in
      *[!0-9:]* | :* | *: | *:0) echowarn "--CONNTRACK_TABLE_UNABLE_TO_READ_COUNT_MAX--" ;;
      *)
        percent="$(awk -v count="$ct_count" -v max="$ct_max" 'BEGIN { printf "%d", count * 1000 / max }')"
        # Translation placeholders supply the format specifiers at build time.
        # shellcheck disable=SC3045,SC2182
        printf "--CONNTRACK_TABLE_S_S_ENTRIES_S_S_FULL_N--" \
          "$ct_count" "$ct_max" "$((percent / 10))" "$((percent % 10))"
        if [ "$percent" -ge 1000 ]; then
          red "--ASSESSMENT_CRITICAL_CONNTRACK_TABLE_LIMI--"
        elif [ "$percent" -ge 950 ]; then
          red "--ASSESSMENT_CRITICAL_CONNTRACK_TABLE_IS_A--"
        elif [ "$percent" -ge 800 ]; then
          yellow "--ASSESSMENT_WARNING_CONNTRACK_TABLE_IS_OV--"
        else
          green "--ASSESSMENT_BELOW_THE_WARNING_THRESHOLD--"
        fi
        echomsg "--MESSAGE_80_AND_95_THRESHOLDS_ARE_HEURISTICS_GROW--"
        ;;
    esac
  else
    echowarn "--CONNTRACK_TABLE_KERNEL_COUNT_MAX_COUNTER--"
  fi

  printf '\n'
  cyan_bold "--TRACKED_CONNTRACK_CONNECTIONS--"
  if command -v conntrack >/dev/null 2>&1; then
    conntrack_report="$(conntrack -L -o extended 2>/dev/null | awk '
      { proto=$3; state=(proto=="tcp" ? $6 : "—")
        mark="unmarked"
        for(i=1;i<=NF;i++) {
          if(proto!="tcp" && $i=="[UNREPLIED]") state="UNREPLIED"
          else if(proto!="tcp" && $i=="[ASSURED]") state="ASSURED"
          else if($i~/^mark=/) mark=substr($i,6) }
        count[proto "|" state]++; marks[mark]++ }
      END {
        for(key in count) {
          split(key,p,"|")
          printf "C|%s|%s|%s\n",p[1],p[2],count[key] }
        for(mark in marks) printf "M|%s|%s\n",mark,marks[mark] }
      ')"
    ct_summary="$(printf '%s\n' "$conntrack_report" |
      awk -F'|' '$1=="C" { print $2 "|" $3 "|" $4 }' |
      sort -t'|' -k1,1 -k2,2)"
    mark_summary="$(printf '%s\n' "$conntrack_report" |
      awk -F'|' '$1=="M" { print $2 "|" $3 }' |
      sort -t'|' -k2,2nr)"

    if [ -n "$ct_summary" ]; then
      { printf '%s\n' "--PROTOCOL_STATE_COUNT_MEANING--"
        printf '%s\n' "$ct_summary" | awk -F'|' '
        { s=$2
          if($1=="tcp") {
            if(s=="ESTABLISHED") m="--AWK_CONNTRACK_TCP_ESTABLISHED--"
            else if(s=="SYN_SENT") m="--AWK_WAITING_FOR_PEER_RESPONSE--"
            else if(s=="SYN_RECV") m="--AWK_WAITING_FOR_FINAL_HANDSHAKE--"
            else if(s=="FIN_WAIT") m="--AWK_CONNECTION_IS_CLOSING--"
            else if(s=="CLOSE_WAIT") m="--AWK_CONNTRACK_TCP_CLOSE_WAIT--"
            else if(s=="LAST_ACK") m="--AWK_WAITING_FOR_FINAL_CLOSE_ACKNOWLEDGEMENT--"
            else if(s=="TIME_WAIT") m="--AWK_RECENTLY_CLOSED_EXPIRES_AUTOMATICALLY--"
            else if(s=="CLOSE") m="--AWK_CONNTRACK_TCP_CLOSE--"
            else m="--AWK_CONNTRACK_TCP_OTHER--"
          } else if(s=="UNREPLIED") m=($1=="icmp" || $1=="icmpv6" ? "--AWK_CONNTRACK_ICMP_UNREPLIED--" : "--AWK_CONNTRACK_UNREPLIED--")
          else if(s=="ASSURED") m=($1=="icmp" || $1=="icmpv6" ? "--AWK_CONNTRACK_ICMP_ASSURED--" : "--AWK_CONNTRACK_ASSURED--")
          else if($1=="udp") m="--AWK_CONNTRACK_UDP--"
          else if($1=="icmp" || $1=="icmpv6") m="--AWK_CONNTRACK_ICMP--"
          else m="--AWK_CONNTRACK_OTHER--"
          printf "%s|%s|%s|%s\n",$1,s,$3,m }
        '
      } | print_aligned_table
    else
      echowarn "--CONNTRACK_RETURNED_NO_DATA_EMPTY_TABLE_O--"
    fi
  else
    echowarn "--CONNTRACK_UTILITY_MISSING_DETAILED_SUMMA--"
  fi

  printf '\n'
  cyan_bold "--CONNTRACK_EVENT_COUNTERS--"
  if command -v conntrack >/dev/null 2>&1; then
    conntrack_stats="$(conntrack -S 2>/dev/null | awk '
      { for(i=1;i<=NF;i++) { split($i,p,"="); if(p[1]!="cpu" && p[2]~/^[0-9]+$/) total[p[1]]+=p[2] } }
      END { for(key in total) print key,total[key] }
    ' | sort -k1,1)"
    if [ -n "$conntrack_stats" ]; then
      printf '%s\n' "$conntrack_stats" | awk '
        BEGIN { print "--AWK_COUNTER_VALUE_MEANING--" }
        $1=="insert_failed" {
          m="--AWK_NEW_ENTRIES_COULD_NOT_BE_ADDED_CHECK_IF--"
          m=m "" }
        $1=="early_drop" { m="--AWK_ENTRIES_EVICTED_EARLY_CHECK_IF_INCREASIN--" }
        $1=="drop" { m="--AWK_PACKETS_DROPPED_BY_CONNTRACK_CHECK_IF_IN--" }
        $1=="invalid" {
          m="--AWK_PACKETS_CLASSIFIED_INVALID_OFTEN_UNRELAT--"
          m=m "" }
        $1=="error" { m="--AWK_PROCESSING_ERRORS_CUMULATIVE_COMPARE_OVE--" }
        $1=="ignore" { m="--AWK_PACKETS_INTENTIONALLY_NOT_TRACKED_OFTEN--" }
        $1=="found" { m="--AWK_EXISTING_ENTRY_FOUND_INFORMATIONAL--" }
        $1=="insert" { m="--AWK_NEW_ENTRIES_INSERTED_INFORMATIONAL--" }
        $1=="search_restart" {
          m="--AWK_HASH_SEARCH_RESTARTED_USUALLY_INFORMATIO--"
          m=m "" }
        m!="" { print $1 "|" $2 "|" m; m="" }
      ' | print_aligned_table
    else
      echowarn "--COUNTER_DATA_IS_UNAVAILABLE--"
    fi
  else
    echowarn "--COUNTERS_UNAVAILABLE_WITHOUT_THE_CONNTRA--"
  fi

  printf '\n'
  cyan_bold "--LOCAL_TCP_SOCKETS_NETSTAT--"
  echo "--NETSTAT_SHOWS_ROUTER_SOCKETS_CONNTRACK_A--"
  if ! command -v netstat >/dev/null 2>&1; then
    echowarn "--NETSTAT_IS_NOT_INSTALLED--"
  else
    tcp_summary="$(netstat -antp 2>/dev/null | awk '
      $1~/^tcp/ && $6!="" { count[$6]++ }
      END { for(s in count) printf "%s|%s\n",s,count[s] }
    ')"
    if [ -z "$tcp_summary" ]; then
      echowarn "--NO_TCP_SOCKET_DATA_AVAILABLE--"
    else
      printf '%s\n' "$tcp_summary" | sort -t'|' -k1,1 | awk -F'|' '
        BEGIN { print "--AWK_TCP_STATE_MEANING_COUNT--" }
        { s=$1; m=s
          if(s=="ESTABLISHED") m="--AWK_ACTIVE_CONNECTION--"; else if(s=="SYN_SENT") m="--AWK_WAITING_FOR_PEER_RESPONSE--"
          else if(s=="SYN_RECV") m="--AWK_WAITING_FOR_FINAL_HANDSHAKE--"
          else if(s=="FIN_WAIT1" || s=="FIN_WAIT2") m="--AWK_CONNECTION_IS_CLOSING--"
          else if(s=="CLOSE_WAIT") { m="--AWK_PEER_CLOSED_LOCAL_PROCESS_MAY_NOT_HAVE_C--"; m=m "" }
          else if(s=="LAST_ACK") m="--AWK_WAITING_FOR_FINAL_CLOSE_ACKNOWLEDGEMENT--"
          else if(s=="TIME_WAIT") m="--AWK_RECENTLY_CLOSED_EXPIRES_AUTOMATICALLY--"
          else if(s=="LISTEN") m="--AWK_WAITING_FOR_INCOMING_CONNECTIONS--"
          printf "%s|%s|%s\n",s,$2,m }' | print_aligned_table
    fi
  fi

  printf '\n'
  cyan_bold "--CONNECTION_MARKS--"
  if [ -n "$mark_summary" ]; then
    printf '%s\n' "$mark_summary" | awk -F'|' '
      BEGIN { print "--AWK_MARK_DEC_HEX_COUNT_PURPOSE--" }
      { mark=$1; value=mark; count=$2
        if(mark=="unmarked") { value="--AWK_NONE--"; d="--AWK_NO_CONNTRACK_MARK--" }
        else {
          if(mark~/^[0-9]+$/) value=mark " / " sprintf("0x%x",mark+0)
          if(mark=="0" || mark=="0x0") d="--AWK_MARK_IS_NOT_SET--"
          else if(mark=="18" || mark=="0x12") d="--AWK_SKEEN_TPROXY_POLICY_ROUTING_MARK_0X12--"
          else d="--AWK_OTHER_MARK_SOURCE_UNKNOWN_FROM_VALUE--" }
        printf "%s|%s|%s\n",value,count,d }
    ' | print_aligned_table
  else
    echo "--NO_MARKED_CONNECTIONS_AVAILABLE--"
  fi
}

update_core() {
  get_os_release
  get_architecture
  download_singbox "$UPDATE_SINGBOX_BETA" || return 1
  if is_running; then stop || exit 1; fi
  install_singbox
  echook "--SINGBOX_NAME_CORE_HAS_BEEN_SUCCESSFULLY--"
}

update_skeen() {
  if download_skeen_script "update"; then
    echook "--SKEEN_NAME_HAS_BEEN_SUCCESSFULLY_UPDATED--"
    is_update_skeen=1
  else
    echoerr "--FAILED_TO_UPDATE_SKEEN_NAME--"
  fi
}

check_should_run(){
  local proc="${1:-}"
  local should_run="0"

  [ "$proc" != "skeen" ] && return

  get_service_proxy_config
  get_firewall_config

  if [ "$SERVICE_PROXY_ENABLED" = "1" ] || [ "$FIREWALL_PROXY_ROUTER" = "1" ]; then
    should_run="1"
  fi
  if [ "$should_run" = "1" ]; then
    if ! is_running; then
      start || press_any_key_to_menu 1
      sleep 2
    fi
  elif is_running; then stop || press_any_key_to_menu 1; fi
}

ask_and_update() {
  local name="${1:-}"
  local proc="${2:-}"
  local api="${3:-}"
  local update_fn="${4:-}"
  local releases="${5:-}"
  local current_version beta opt
  latest_version=""

  check_should_run "$proc"

  echomsg "--CHECKING_NAME_FOR_UPDATES--"

  current_version=$(get_current_version "$proc")
  [ -z "$current_version" ] && current_version="--CURRENT_VERSION_NOT_INSTALLED--"

  case "$api" in *atom) beta="1" ;; */releases/latest) beta="0" ;; esac
  latest_version=$(get_latest_version "$api" "$beta")
  [ -z "$latest_version" ] && echoerr "--FAILED_TO_FETCH_VERSION_NUMBER--" && return 1

  if [ "$current_version" != "$latest_version" ]; then
    printf '%s %s\n' "$(cyan "--CURRENT_VERSION_NAME--")" "$(red "$current_version")"
    printf '%s %s\n' "$(cyan "--NEW_VERSION_IS_AVAILABLE--")" "$(green "$latest_version")"
    printf '%s %s\n' "$(cyan "--MORE_DETAILS--")" "$(green "$releases")"

    while :; do
      # shellcheck disable=SC3045
      printf "--PERFORM_THE_UPDATE_Y_N_DEFAULT_N--" >/dev/tty
      read -r opt </dev/tty
      [ -z "$opt" ] && opt=n

      case $opt in
      y | Y)
        "$update_fn" || return 1
        break
        ;;
      n | N) break ;;
      *) echoerr "--INCORRECT_OPTION--" ;;
      esac
    done
  else
    echook "--THE_LATEST_NAME_VERSION_LATEST_VERSION_I--"
  fi

  return 0
}

check_updates() {
  check_tty

  is_check_update=1; is_update_skeen=0

  get_update_config
  if [ "$UPDATE_SINGBOX_ENABLED" != "1" ] && [ "$UPDATE_SKEEN_ENABLED" != "1" ]; then
    echowarn "--UPDATES_ARE_DISABLED_IN_THE_SKEEN_NAME_C--"
    press_any_key_to_menu 1
  fi

  # sing-box
  if get_singbox_config && [ "$SINGBOX_EXTERNAL_ENABLED" != "1" ]; then
    if [ "$UPDATE_SINGBOX_ENABLED" = "1" ]; then
      local repo="$SINGBOX_REPO" api_url
      FORK_CHANNEL="${UPDATE_SINGBOX_CHANNEL:-official}"

      case "$FORK_CHANNEL" in
        skb|skb-upx) repo="$FORK_SKB_REPO" ;;
        pdk|pdk-full) repo="$FORK_PDK_REPO" ;;
        lx|lx-upx) repo="$FORK_LX_REPO" ;;
        *) FORK_CHANNEL="official" ;;
      esac
      api_url="https://github.com/${repo}/releases/latest"
      [ "$UPDATE_SINGBOX_BETA" = "1" ] && api_url="https://github.com/${repo}/releases.atom"
      ask_and_update "$SINGBOX_NAME $FORK_CHANNEL" "sing" "$api_url" update_core "https://github.com/${repo}/releases"
    fi
  fi

  # skeen
  if [ "$UPDATE_SKEEN_ENABLED" = "1" ]; then
    ask_and_update "$SKEEN_NAME" "skeen" "$SKEEN_API_URL" \
      update_skeen "https://github.com/jinndi/SKeen/releases"
  fi

  # skeen-api
  if [ "$UPDATE_SKEEN_API" = "1" ] && [ -f "$SERVICE_API_SCRIPT" ]; then
    "$SERVICE_API_SCRIPT" update
  fi

  unset is_check_update

  if [ "$is_update_skeen" -eq 1 ]; then
    exec sh "$SKEEN_SCRIPT" deps menu
  else
    press_any_key_to_menu "" reload
  fi
}

import_firewall_vars() {
  if [ -f "$FIREWALL_HOOK_FILE" ]; then
    set -a
    eval "$(
      grep -E '^export [A-Za-z_][A-Za-z0-9_]*=' "$FIREWALL_HOOK_FILE" |
        sed 's/^export //'
    )"
    set +a
  fi
}

fw_test() {
  local content
  # $1 — table
  # $2 — chain
  # $3 — content
  # $4 — grep pattern
  # $5 — test name (human readable)

  if echo "$3" | grep -Eq "$4"; then
    green "[OK($1/$2)] $5"
  else
    red "[MISS($1/$2)] $5"
  fi
}

fw_test_chain() {
  local content
  # $1 — table
  # $2 — chain
  # $3 — iptables

  # Referenced by the firewall-test translation.
  # shellcheck disable=SC2034
  local ref="PREROUTING"
  [ "$2" = "$CHAIN_OUTPUT" ] && ref="OUTPUT"
  # shellcheck disable=SC2034
  [ "$2" = "$CHAIN_TUN" ] && ref="INPUT/OUTPUT"

  cyan "--TEST_REF_1_2--"

  content="$($3 -w -t "$1" -nvL "$2" 2>/dev/null)"

  if [ "$1" = "mangle" ] && [ "$2" = "INPUT" ]; then
    fw_test "$1" "$2" "$content" "skeen_keendns" "KeenDNS accept"
    return 0
  fi

  fw_test "$1" "$2" "$content" "[1-9][0-9]* references" "Reference"

  if [ "$2" = "$CHAIN_DNS" ]; then
    fw_test "$1" "$2" "$content" "skeen_dns" "DNS redirect"
    return 0
  fi

  if [ "$2" = "$CHAIN_TUN" ]; then
    fw_test "$1" "$2" "$content" "skeen_tun" "Accept"
    return 0
  fi

  fw_test "$1" "$2" "$content" "ctdir REPLY" "REPLY accept"

  if [ "$1" = "mangle" ]; then
    case "$2" in
    "$CHAIN_PREROUTING")
      [ "$SKEEN_FIREWALL_MODE" = "tproxy" ] && fw_test "$1" "$2" "$content" "$CHAIN_DIVERT" "Socket accept"
      [ "$SKEEN_INTERCEPT_DNS_ENABLED" = "1" ] && comment="DNS intercept" || comment="DNS exclude"
      fw_test "$1" "$2" "$content" "dpt:${DNS_PORT}" "$comment"
      ;;
    "$CHAIN_OUTPUT")
      [ "$SKEEN_REDIRECT_DNS_ENABLED" != "1" ] && comment="DNS mark" || comment="DNS exclude"
      fw_test "$1" "$2" "$content" "dpt:${DNS_PORT}" "$comment"
      ;;
    esac
  fi

  if [ "$SKEEN_EXCLUDE_PORT" = "1" ]; then
    # shellcheck disable=SC2015
    fw_test "$1" "$2" "$content" "$PORT_EXCLUDE_SET" "Port exclude"
  fi

  fw_test "$1" "$2" "$content" "$NET_EXCLUDE_SET" "Subnet exclude"

  if [ "$2" = "$CHAIN_PREROUTING" ] && [ "$SKEEN_INTERCEPT_FAKEIP" != "0" ]; then
    fw_test "$1" "$2" "$content" "$FAKEIP_INTERCEPT_SET" "FakeIP intercept"
  fi

  if [ "$1" = "mangle" ] && [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "MARK" "Mark set"
  elif [ "$1" = "nat" ] && [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "redir" "TCP Redirect"
  fi

  [ "$2" = "$CHAIN_OUTPUT" ] && return 0

  if [ "$1" = "mangle" ]; then
    fw_test "$1" "$2" "$content" "redirect" "TProxy redirect"
  elif [ "$1" = "nat" ]; then
    fw_test "$1" "$2" "$content" "redir" "TCP Redirect"
  fi
}

test_firewall() {
  local tables

  if ! is_running; then
    echoerr "--TESTING_ARE_AVAILABLE_ONLY_WHEN_SKEEN_NA--"
    press_any_key_to_menu 1
  else
    if [ ! -f "$FIREWALL_HOOK_FILE" ]; then
      echoerr "--THE_FILE_AT_PATH_FIREWALL_HOOK_FILE_IS_M--"
      echomsg "--PLEASE_REBOOT_SINGBOX_NAME--"
      press_any_key_to_menu 1
    fi

    import_firewall_vars
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "hybrid" ]; then
    tables="nat mangle"
  elif [ "$SKEEN_FIREWALL_MODE" = "tproxy" ]; then
    tables="mangle"
  elif [ "$SKEEN_FIREWALL_MODE" = "redirect" ]; then
    tables="nat"
  elif [ "$SKEEN_FIREWALL_MODE" = "tun" ]; then
    tables="filter"
  elif [ "$SKEEN_REDIRECT_DNS_ENABLED" != "1" ]; then
    echowarn "--TESTING_IS_AVAILABLE_IN_TUN_REDIRECT_TPR--"
    echowarn "--ALSO_WITH_THE_SPECIFIED_DNS_REDIRECT_PAR--"
    press_any_key_to_menu 1
  fi

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "--IPTABLES_UTILITY_IS_NOT_INSTALLED--"
    press_any_key_to_menu 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ]; then
    fw_test_chain filter "$CHAIN_TUN" "iptables"
  else
    for iptables in $SKEEN_IPTABLES_LIST; do
      [ "$iptables" = "ip6tables" ] && echo "$DELIMETER"
      local iptables_display
      # Referenced by the firewall-testing translation.
      # shellcheck disable=SC2034
      iptables_display="$(cyan "$iptables")"
      yellow "--FIREWALL_TESTING--"
      echo "$DELIMETER"

      [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ] && fw_test_chain nat "$CHAIN_DNS" "$iptables"

      for table in $tables; do
        fw_test_chain "$table" "$CHAIN_PREROUTING" "$iptables"
        [ "$table" = "mangle" ] && fw_test_chain "$table" INPUT "$iptables"
        [ "$SKEEN_PROXY_ROUTER" = "1" ] &&
          fw_test_chain "$table" "$CHAIN_OUTPUT" "$iptables"
      done

      [ "$SKEEN_TUN_ENABLED" = "1" ] && [ "$iptables" = "iptables" ] &&
        fw_test_chain filter "$CHAIN_TUN" "iptables"
    done
  fi

  press_any_key_to_menu
}

backup_list() {
  find "$ENTWARE_DIR" -maxdepth 1 -type f -name "skeen_*.tar"
}

backup_create() {
  local archive_path parent_dir folder_name required_mb

  if [ -d "$WORK_DIR" ] && [ "$(ls -A "$WORK_DIR")" ]; then
    required_mb="$(du -sm "$WORK_DIR" | awk '{print $1}')"

    check_free_space "$required_mb"

    echomsg "--CREATING_A_BACKUP_OF_THE_CURRENT_CONFIGU--"
    archive_path="${ENTWARE_DIR}/skeen_$(date '+%Y-%m-%d_%H%M%S').tar"
    parent_dir=$(dirname "$WORK_DIR")
    folder_name=$(basename "$WORK_DIR")
    if tar -cf "$archive_path" -C "$parent_dir" "$folder_name"; then
      echook "--BACKUP_SUCCESSFULLY_CREATED_AT_ARCHIVE_P--"
    else
      echoerr "--ERROR_CREATING_BACKUP--"
      return 1
    fi
  else
    echowarn "--NO_CURRENT_CONFIGURATION_FOUND_SKIPPING--"
  fi
  return 0
}

backup_restore() {
  local tarname="${1:-}"
  local archive_path

  restore() {
    local archive_path="${ENTWARE_DIR}/${1:-}"
    local work_dir_backup required_mb

    if [ -f "$archive_path" ] && tar -tf "$archive_path" | grep -q "^skeen/"; then
      required_mb="$(du -sm "$archive_path" | awk '{print $1}')"
      check_free_space "$required_mb"

      work_dir_backup="${ENTWARE_DIR}/skeen_backup"
      mv "$WORK_DIR" "$work_dir_backup"
      mkdir -p "$WORK_DIR"
      echomsg "--EXTRACTING_ARCHIVE_ARCHIVE_PATH--"
      if tar --strip-components=1 -xf "$archive_path" -C "$WORK_DIR"; then
        rm -rf "$work_dir_backup"
        echook "--BACKUP_SUCCESSFULLY_RESTORED--"
      else
        rm -rf "$WORK_DIR"
        mv "$work_dir_backup" "$WORK_DIR"
        echoerr "--ERROR_EXTRACTING_ARCHIVE_ARCHIVE_PATH--"
        return 1
      fi
    else
      echoerr "--ARCHIVE_MISSING_OR_SKEEN_FOLDER_NOT_FOUN--"
      return 1
    fi

    return 0
  }

  if is_tty && [ "$CALLER" = "cli" ] && [ -z "$tarname" ]; then
    while :; do
      # shellcheck disable=SC3045
      printf "--ENTER_THE_NAME_OF_THE_BACKUP_ARCHIVE_FIL--"
      # shellcheck disable=SC3045
      printf "--LOCATED_IN_THE_OPT_ROOT_DIRECTORY_N--"
      # Translation placeholders supply the format specifiers at build time.
      # shellcheck disable=SC3045,SC2182
      printf "--FOR_EXAMPLE_S--" "$(cyan "skeen.tar")" >/dev/tty
      read -r tarname </dev/tty
      [ -z "$tarname" ] && exit 1
      restore "$tarname" && break
    done
  elif [ -n "$tarname" ]; then
    restore "$tarname"
  else
    echoerr "--NO_ARCHIVE_NAME_PROVIDED--"
    return 1
  fi
}

config_reset() {
  check_tty

  while :; do
    # shellcheck disable=SC3045
    printf "--A_FULL_CONFIGURATION_RESET_WILL_BE_PERFO--"
    # shellcheck disable=SC3045
    printf "--WITH_A_BACKUP_OF_THE_CURRENT_CONFIGURATI--"
    # shellcheck disable=SC3045
    printf "--CONTINUE_Y_N--" >/dev/tty
    read -r option </dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
    y | Y)
      if backup_create; then
        rm -rf "$WORK_DIR"
        mkdir -p "$WORK_DIR"
        get_update_config
        download_singbox_config "$UPDATE_SINGBOX_BETA" "force"
        download_initial_ruleset
        create_skeen_config "force"
        echook "--CONFIGURATION_RESET_COMPLETED--"
      else
        echoerr "--FAILED_TO_RESET_CONFIGURATION--"
      fi
      break
      ;;
    n | N) break ;;
    *) echoerr "--INCORRECT_OPTION--" ;;
    esac
  done

  press_any_key_to_menu
}

clean_cache() {
  local cache_file_enabled cache_file_path msg_not_found="--CACHE_FILE_NOT_FOUND_AT_PATH--"

  get_singbox_config

  if [ ! -s "$SINGBOX_CONFIG" ]; then
    echoerr "--CONFIGURATION_FILE_WITH_EXPERIMENTAL_CAC--"
    return 0
  fi

  eval "$(
    jsonfilter -i "$SINGBOX_CONFIG" \
      -e cache_file_enabled='@.experimental.cache_file.enabled' \
      -e cache_file_path='@.experimental.cache_file.path'
  )"

  if [ "$cache_file_enabled" != "1" ]; then
    echowarn "--CACHE_FILE_IS_DISABLED_IN_SINGBOX_NAME_C--"
  fi

  if [ -z "$cache_file_path" ]; then
    cache_file_path="${WORK_DIR}/cache.db"
  else
    if ! echo "$cache_file_path" | grep -q "^/"; then
      cache_file_path="${WORK_DIR}/${cache_file_path}"
      if [ ! -f "$cache_file_path" ]; then
        echoerr "${msg_not_found}: $cache_file_path"
        return 0
      fi
    elif [ ! -f "$cache_file_path" ]; then
      echoerr "${msg_not_found}: $cache_file_path"
      return 0
    fi
  fi

  rm -f "$cache_file_path"
  echook "--CACHE_CLEARED_RESTART_SKEEN_NAME_TO_APPL--"
}

check_skeen_config() {
  echomsg "--CHECKING_SKEEN_NAME_CONFIGURATION--"
  if jsonfilter -i "$(get_skeen_config_path)" -e '@.auto_start' >/dev/null; then
    echook "--SKEEN_NAME_JSON_IS_VALID--"
    return 0
  else
    local err_msg="--SKEEN_NAME_CONFIGURATION_IS_INVALID--"
    logger_error "$err_msg"; echoerr "$err_msg"
    return 1
  fi
}

check_singbox_config() {
  if get_singbox_config && [ -f "$SINGBOX_BIN" ]; then
    echomsg "--CHECKING_SINGBOX_NAME_CONFIGURATION--"
    local config="-c $SINGBOX_CONFIG"
    [ -n "$SINGBOX_CONFIG_DIR" ] && config="-C $SINGBOX_CONFIG_DIR"
    # shellcheck disable=SC2086
    if $SINGBOX_BIN check $config; then
      echook "--SINGBOX_NAME_CONFIGURATION_IS_VALID--"
    else
      local err_msg="--SINGBOX_NAME_CONFIGURATION_IS_INVALID--"
      logger_error "$err_msg"; echoerr "$err_msg"
      return 1
    fi
  fi
  return 0
}

check_config() {
  check_skeen_config || return 1
  check_singbox_config || return 1
  return 0
}

format_config() {
  if get_singbox_config && [ -f "$SINGBOX_BIN" ]; then
    echomsg "--FORMATTING_SINGBOX_NAME_CONFIGURATION--"
    local config="-c $SINGBOX_CONFIG"
    [ -n "$SINGBOX_CONFIG_DIR" ] && config="-C $SINGBOX_CONFIG_DIR"
    # shellcheck disable=SC2086
    if $SINGBOX_BIN format -w $config; then
      echook "--CONFIGURATION_FORMATTED_SUCCESSFULLY--"
    else
      echoerr "--CONFIGURATION_FORMATTING_FAILED--"
    fi
  else
    echoerr "--SINGBOX_NAME_EXECUTABLE_IS_MISSING--"
  fi
}

run_api() {
  local error_msg="--ONLY_SUPPORTED_IN_SINGBOX_NAME_1_14_0--"
  shift

  check_tty
  get_singbox_config
  if [ -f "$SINGBOX_BIN" ]; then
    local version major minor
    version="$(get_current_version "sing")"
    major="${version%%.*}"
    minor="${version#1.}"
    minor="${minor%%.*}"

    if [ "$major" -eq 1 ] && [ "$minor" -eq 14 ]; then
      case "$version" in
        *alpha* | *beta*) exiterr "$error_msg" ;;
      esac
    fi

    if [ "${version%%.*}" -ge 1 ] && [ "$minor" -ge 14 ]; then
      "$SINGBOX_BIN" api "$@"
    else
      exiterr "$error_msg"
    fi
  else
    exiterr "--EXECUTABLE_FILE_SINGBOX_NAME_IS_MISSING--"
  fi
}

get_api_links() {
  get_singbox_config
  local f="$SINGBOX_CONFIG" json=0 o="" fst=1
  [ "${1:-}" = "--json" ] && json=1
  [ "$json" -eq 1 ] && o="["

  ip="$(ip -4 addr show dev br0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)"
  : "${ip:=192.168.1.1}"

  fa() {
    [ "$1" = "0.0.0.0" ] || [ "$1" = "::" ] && echo "$ip:$2" && return
    [ "$1" != "127.0.0.1" ] && [ -n "$1" ] && echo "$1:$2"
  }

  local panels="" apis=""

  emit() {
    local type="$1" addr="$2" has_p="$3" base_name="$4" run_state="${5:-1}"
    [ -n "$addr" ] || return

    if [ "$json" -eq 1 ]; then
      [ "$type" = "skeen_api" ] || [ "$has_p" -ne 1 ] || [ "$run_state" -eq 0 ] && return
      [ "$fst" -eq 0 ] && o="$o,"
      o="$o{\"type\":\"$type\",\"url\":\"http://$addr\"}"
      fst=0
    else
      local label; label="$(cyan "$base_name API$( [ "$has_p" -eq 1 ] && echo "+UI" )$( [ "$run_state" -eq 0 ] && red " (off)" )")"
      [ "$has_p" -eq 1 ] && panels="$panels\n$label: http://$addr" || apis="$apis\n$label: http://$addr"
    fi
  }

  [ "$json" -eq 0 ] && {
    get_service_api_config 2>/dev/null
    [ -n "${SERVICE_API_PORT:-}" ] && {
      local skeen_api_run=1
      [ -n "${SERVICE_API_SCRIPT:-}" ] && "$SERVICE_API_SCRIPT" status >/dev/null 2>&1 || skeen_api_run=0
      emit "skeen_api" "$(fa "$ip" "$SERVICE_API_PORT")" "${SERVICE_API_DASHBOARD:-0}" "SKeen" "$skeen_api_run"
    }
  }

  local sb_run=1; is_running >/dev/null 2>&1 || sb_run=0

  local s i=0 t l p d
  s=$(jsonfilter -i "$f" -e '@.services' 2>/dev/null)
  while t=$(jsonfilter -s "$s" -e "@[$i].type" 2>/dev/null) && [ -n "$t" ]; do
    [ "$t" = "api" ] && {
      l=$(jsonfilter -s "$s" -e "@[$i].listen"); p=$(jsonfilter -s "$s" -e "@[$i].listen_port"); d=$(jsonfilter -s "$s" -e "@[$i].dashboard")
      local has_p=1
      [ "$d" = "false" ] || [ "$(jsonfilter -s "$s" -e "@[$i].dashboard.enabled")" = "false" ] && has_p=0

      emit "api" "$(fa "$l" "$p")" "$has_p" "Sing-box" "$sb_run"
    }
    i=$((i + 1))
  done

  eval "$(jsonfilter -i "$f" -e 'cc=@.experimental.clash_api.external_controller' -e 'ext_ui=@.experimental.clash_api.external_ui' 2>/dev/null)"
  [ -n "$cc" ] && {
    local has_p=0; [ -n "$ext_ui" ] && has_p=1
    emit "clash_api" "$(fa "${cc%%:*}" "${cc##*:}")" "$has_p" "Clash" "$sb_run"
  }

  if [ "$json" -eq 1 ]; then printf "%s]\n" "$o"; else printf "%b\n" "$panels\n$apis" | sed '/^$/d'; fi
}

split_singbox_config() {
  local src_file="${1:-}"
  local target_dir="${2:-}"

  mkdir -p "$target_dir"

  local KEYS=""
  eval "$(jsonfilter -i "$src_file" -e 'KEYS=@')"

  local schema_val=""
  schema_val="$(jsonfilter -i "$src_file" -e "@['\$schema']")"

  local schema_prefix=""
  if [ -n "$schema_val" ]; then
    schema_val="$(echo "$schema_val" | sed 's#\\/#/#g')"
    # shellcheck disable=SC2016
    schema_prefix="$(printf '  "$schema": "%s",\n' "$schema_val")"
  fi

  for key in $KEYS; do
    case "$key" in
      \$*) continue ;;
    esac

    local val
    val=$(jsonfilter -i "$src_file" -e "@['$key']")

    if [ -n "$val" ]; then
      val=$(echo "$val" | sed 's#\\/#/#g')
      printf '{\n%s  "%s": %s\n}\n' "$schema_prefix" "$key" "$val" > "$target_dir/$key.json"
    fi
  done
}

sync_config() {
  local address="${1:-}" config_tmp

  get_singbox_config

  if [ -z "$address" ]; then
    [ -z "$SINGBOX_CONFIG_URL" ] && echoerr "--SYNC_URL_ADDRESS_IS_NOT_SPECIFIED--" && return 1
    address="$SINGBOX_CONFIG_URL"
  fi

  if ! echo "$address" | grep -qE '^https?://'; then
    echoerr "--URL_MUST_START_WITH_HTTP_OR_HTTPS--"; return 1
  fi

  config_tmp="$(mktemp /tmp/skeen_sync.XXXXXX)" || {
    echoerr "--FAILED_TO_CREATE_TEMPORARY_FILE--"; return 1
  }

  if ! run_curl -s --max-time 20 "$address" -o "$config_tmp"; then
    rm -f "$config_tmp"
    echoerr "--FAILED_TO_DOWNLOAD_CONFIGURATION_FROM_AD--"; return 1
  fi

  if ! $SINGBOX_BIN check -c "$config_tmp"; then
    rm -f "$config_tmp"
    echoerr "--SINGBOX_NAME_CONFIGURATION_IS_INVALID_SY--"; return 1
  fi

  if [ -n "$SINGBOX_CONFIG_DIR" ]; then
    local tmp_target_dir
    tmp_target_dir="$(mktemp -d /tmp/skeen_dir.XXXXXX)" || {
      rm -f "$config_tmp"; echoerr "--FAILED_TO_CREATE_TMP_DIRECTORY--"; return 1
    }

    if [ "$SINGBOX_CONFIG_SPLIT" = "1" ]; then
      if ! split_singbox_config "$config_tmp" "$tmp_target_dir"; then
        rm -rf "$tmp_target_dir"; rm -f "$config_tmp"
        echoerr "--ERROR_SPLITTING_CONFIGURATION_SYNC_CANCE--"; return 1
      fi
    else
      mv -f "$config_tmp" "${tmp_target_dir}/config.json"
    fi

    local backup_dir="${SINGBOX_CONFIG_DIR}_backup"
    rm -rf "$backup_dir"; cp -a "$SINGBOX_CONFIG_DIR" "$backup_dir" 2>/dev/null

    rm -rf "${SINGBOX_CONFIG_DIR:?}"; mv -f "$tmp_target_dir" "$SINGBOX_CONFIG_DIR"
  elif [ -f "$SINGBOX_CONFIG" ]; then
    cp -f "$SINGBOX_CONFIG" "${SINGBOX_CONFIG}.bak"
    if ! mv -f "$config_tmp" "$SINGBOX_CONFIG"; then
      mv -f "${SINGBOX_CONFIG}.bak" "$SINGBOX_CONFIG"
      echoerr "--FAILED_TO_SAVE_NEW_CONFIG_ROLLBACK_EXECU--"; return 1
    fi
  else
    mv -f "$config_tmp" "$SINGBOX_CONFIG"
  fi

  rm -f "$config_tmp"
  echook "--CONFIGURATION_SYNCED_RESTART_SKEEN_NAME--"
  return 0
}

gen_headers() {
  local hwid line pair os ver mod json

  check_tty
  hwid="$(tr '[:lower:]' '[:upper:]' </proc/sys/kernel/random/uuid)"
  line="$(printf '%s\n' \
    "Windows|10.0.19045,Windows 10|10.0.22631,Windows 11|10.0.26100,Windows 11 24H2|10.0.19042,Windows 10 20H2" \
    "Linux|5.15.0-88,Ubuntu 22.04 LTS|6.8.0-45,Ubuntu 24.04 LTS|6.1.0-21,Debian 12|6.9.7,Arch Linux|6.6.2,Manjaro" \
    "macOS|14.5.0,MacBook Pro|14.6.0,MacBook Air|15.0.0,Mac mini|13.6.7,MacBook Pro M1" |
      awk 'BEGIN{srand()} {a[NR]=$0} END{print a[int(rand()*NR)+1]}')"
  pair="$(printf '%s' "${line#*|}" | tr '|' '\n' | awk 'BEGIN{srand()} {a[NR]=$0} END{print a[int(rand()*NR)+1]}')"
  os="${line%%|*}"; ver="${pair%%,*}"; mod="${pair#*,}"
  json="{\"x-hwid\":\"$hwid\",\"x-device-os\":\"$os\",\"x-ver-os\":\"$ver\",\"x-device-model\":\"$mod\"}"

  cyan "--GENERATED_RANDOM_DEVICE_PARAMETERS--"
  for k in x-hwid x-device-os x-ver-os x-device-model; do printf '  %s: ' "$k"; green "$(jsonfilter -s "$json" -e "@['$k']")"; done
  printf '\n'; cyan "--SUB_STORE_ADD_THE_FOLLOWING_PARAMETER_TO--"; green "$(printf '%s' "#headers=$json" | sed 's/ /%20/g')"
}

show_iface() {
  check_tty

  local G='\e[32m' R='\e[31m' W='\e[1m' N='\e[0m' Y='\e[33m' B='\e[36m' M='\e[35m'
  local ip_data ln_data mt_data tf_data v6_flags

  printf "${W}%-10s %-4s %-5s %-6s %-10s %-10s${N}\n" "INTERFACE" "IPv6" "MTU" "LINK" "RX/TX (MB)" "IP ADDRESS"
  printf "%-10s %-4s %-5s %-6s %-10s %-10s\n" "----------" "----" "-----" "------" "----------" "----------"

  ip_data="$(ip -o addr show | awk '{print $2,$3,$4}' | cut -d/ -f1)"
  ln_data="$(grep . /sys/class/net/*/operstate 2>/dev/null)"
  mt_data="$(awk '{print FILENAME ":" $0}' /sys/class/net/*/mtu 2>/dev/null | sed 's|/sys/class/net/||;s|/mtu||')"
  tf_data="$(cat /proc/net/dev | tail -n +3 | tr ':' ' ' | awk '{$1=$1;print}')"
  v6_flags="$(awk '{print FILENAME ":" $0}' /proc/sys/net/ipv6/conf/*/disable_ipv6 2>/dev/null | sed 's|/proc/sys/net/ipv6/conf/||;s|/disable_ipv6||')"

  echo "$tf_data" | sort | awk -v g="$G" -v r="$R" -v n="$N" -v y="$Y" -v b="$B" -v m="$M" -v ipd="$ip_data" -v lnd="$ln_data" -v mtd="$mt_data" -v v6f="$v6_flags" '
  BEGIN {
    split(lnd, a_ln, "\n"); for (i in a_ln) { split(a_ln[i], t, /[\/:]/); link[t[5]] = t[7] }
    split(mtd, a_mt, "\n"); for (i in a_mt) { split(a_mt[i], t, ":"); mtu[t[1]] = t[2] }
    split(v6f, a_v6, "\n"); for (i in a_v6) { split(a_v6[i], t, ":"); v6_sys[t[1]] = t[2] }
    split(ipd, i_arr, "\n"); for (x in i_arr) {
      split(i_arr[x], t, " ")
      if (t[2] == "inet") ip4[t[1]] = t[3]
      if (t[2] == "inet6" && !ip6[t[1]]) ip6[t[1]] = t[3]
    }
  }
  {
    ifc = $1
    rx = int($2/1048576); tx = int($10/1048576)
    tr_p = rx "/" tx
    v6_s = (v6_sys[ifc] == "0") ? g"on  "n : r"off "n
    ln_raw = link[ifc]
    if (ln_raw == "up") ln_s = g"up    "n
    else if (ln_raw == "unknown") ln_s = n"unk   "n
    else ln_s = r"down  "n
    printf "%-10s %s %s%-5s%s %s ", ifc, v6_s, b, (mtu[ifc] ? mtu[ifc] : "-"), n, ln_s
    printf "%s%s%s/%s%s%s", b, rx, n, m, tx, n
    pad = 10 - length(tr_p)
    for (p=0; p<pad; p++) printf " "
    printf " %s%s%s\n", y, (ip4[ifc] ? ip4[ifc] : "-"), n
    if (ip6[ifc]) {
      printf "                                        %s%s%s\n", b, ip6[ifc], n
    }
  }'
}

show_menu() {
  local autostart_status running_status running_text running_state output version ipv4 ipv6 sb_dns_work_text

  check_tty
  check_skeen_config && printf "\033[1A\033[2K\033[1A\033[2K"
  import_firewall_vars
  get_singbox_config

  if get_auto_start_config && [ "$AUTO_START_ENABLED" = "1" ]; then
    autostart_status="$(green "--YES--")"
  else
    autostart_status="$(red "--NO--")"
  fi

  if is_running; then
    running_status="$(green "running")"
    running_text="--STOP--"
    running_state=1
  else
    running_status="$(red "stopped")"
    running_text="--START--"
    running_state=0
  fi

  add_line() {
    local key="${1:-}"
    local val="${2:-}"
    local target_len=10
    local pad spaces="          "
    pad=$((target_len - ${#key}))
    [ $pad -lt 1 ] && pad=1
    while [ ${#spaces} -gt $pad ]; do spaces="${spaces%?}"; done
    output="${output}\n ${key}${spaces} ${val}"
  }

  add_line "${SKEEN_NAME}" "$(cyan "v$(get_current_version "skeen")")"

  version="$(cyan "v$(get_current_version "sing")")"
  [ "$version" = "$(cyan "v")" ] && version="$(red "--SINGBOX_VERSION_NOT_INSTALLED--")"
  add_line "${SINGBOX_NAME}" "${version}"

  add_line "--STATUS_STATE_LABEL--" "$running_status"
  add_line "--AUTOSTART--" "$autostart_status"

  if [ "$running_state" = "1" ]; then
    if [ "$SKEEN_INTERCEPT_DNS_ENABLED" = "1" ] || [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
      sb_dns_work_text="$(green "--YES--")"
    else
      sb_dns_work_text="$(red "--NO--")"
    fi
    add_line "Sing DNS" "$sb_dns_work_text"

    if [ "$SKEEN_FIREWALL_MODE" != "none" ] && [ "$SKEEN_FIREWALL_MODE" != "tun" ]; then
      case "$SKEEN_IPTABLES_LIST" in *ipt*) ipv4="$(cyan "4")" ;; esac
      case "$SKEEN_IPTABLES_LIST" in *ip6t*) ipv6="$(cyan "6")" ;; esac

      [ -n "$SKEEN_POLICY_SEGMENT" ] && add_line "--SEGMENT--" "$(cyan "$SKEEN_POLICY_SEGMENT")"
      [ "$SKEEN_TUN_ENABLED" = "1" ] && add_line "OpkgTun" "$(cyan "--YES--")"
      add_line "--MODE--" "$(cyan "$SKEEN_FIREWALL_MODE")"
      add_line "--NETWORK--" "$(cyan "$SKEEN_FIREWALL_NETWORK")"
      add_line "--IP_VER--" "$ipv4 $ipv6"
    else
      add_line "--MODE--" "$(cyan "$SKEEN_FIREWALL_MODE")"
    fi
  fi

  output="$output\n\n$(cyan "--SELECT_OPTION--")"
  output="$output\n  $(green "1.") $running_text"
  output="$output\n  $(green "2.") --MENU_RESTART--"
  output="$output\n  $(green "3.") --MENU_UPDATES--"
  output="$output\n  $(green "4.") --MENU_TEST--"
  output="$output\n  $(green "5.") --MENU_UNINSTALL--"
  output="$output\n  $(green "0.") --MENU_EXIT--\n"

  show_header
  printf '%b\n' "$output"

  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    # shellcheck disable=SC3045
    printf "--CHOICE_0_5--" >/dev/tty
    read -r option </dev/tty

    printf "\n"

    case "$option" in
      [1-5])
        echo "$DELIMETER"
        case "$option" in
          1) switch_state ;;
          2) restart ;;
          3) check_updates ;;
          4) test_firewall ;;
          5) accept_uninstall ;;
        esac
        ;;
      0) exit 0 ;;
      *)
        echoerr "--INCORRECT_OPTION--"
        attempt=$((attempt + 1))
        ;;
    esac
  done

  exiterr "--MAXIMUM_ATTEMPTS_REACHED_EXITING_MENU--"
}

show_help() {
  printf '%s\n' "--USAGE_SKEEN_COMMAND_AVAILABLE_COMMANDS_S--"
}

case "$CALLER:$ACTION" in
  netfilter:apply_firewall) apply_firewall "$3"; exit 0 ;;
  update:clean_firewall) rm -f "$SKEEN_RUN_SCRIPT"; clean_firewall; exit 0 ;;
  netfilter:*) exit 0 ;;
esac

if [ -f "$SKEEN_SCRIPT" ]; then
  check_and_create_or_sync_skeen_config

  case "$ACTION" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  reload) reload ;;
  kill) kill_proc ;;
  status) if [ "$2" = "--json" ]; then status_json; else status; fi ;;
  version) version ;;
  iface) show_iface ;;
  connstat) show_connstat ;;
  update) check_updates ;;
  test) test_firewall ;;
  deps)
    install_dependencies
    press_any_key_to_menu
    ;;
  check) check_config ;;
  format) format_config ;;
  api) run_api "$@" ;;
  dash) get_api_links "$2" ;;
  backup) backup_create ;;
  backups) backup_list ;;
  restore) backup_restore "$2" ;;
  reset) config_reset ;;
  clean) clean_cache ;;
  sync) sync_config "$2" ;;
  headers) gen_headers ;;
  tun)
    check_tty
    release_version_ge5 || return 1
    case "$2" in
    create) tun_create "$3" "$4" ;;
    delete) tun_delete "$3" ;;
    list) tun_list ;;
    *) show_help | awk '/OpkgTun / {flag=1} flag' ;;
    esac
    ;;
  get_singbox_config) get_singbox_config --json ;;
  get_api_config) get_service_api_config --json ;;
  "") show_menu ;;
  help | *) show_help ;;
  esac
else
  install
fi

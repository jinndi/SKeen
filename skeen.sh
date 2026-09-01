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

readonly DEPENDENCIES="start-stop-daemon iptables ip-full ipset net-tools curl tar jsonfilter logger"

readonly ENTWARE_DIR="/opt"
readonly WORK_DIR="${ENTWARE_DIR}/etc/skeen"
readonly TMP_DIR="${ENTWARE_DIR}/tmp"
readonly NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
readonly MODULES_OS_DIR="/lib/modules"
readonly MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"
readonly CURL_RESOLVE_FIX="--resolve release-assets.githubusercontent.com:443:185.199.108.133"
readonly REPO_MAIN_BRANCH="https://raw.githubusercontent.com/jinndi/SKeen/refs/heads/main/"

readonly SKEEN_NAME="SKeen"
readonly SKEEN_VERSION="5.3.1"
readonly SKEEN_PROC="skeen"
readonly SKEEN_SCRIPT="${ENTWARE_DIR}/bin/${SKEEN_PROC}"
readonly SKEEN_RUN_SCRIPT="/tmp/${SKEEN_PROC}.sh"
readonly SKEEN_API_URL="https://github.com/jinndi/SKeen/releases/latest"
readonly SKEEN_CONFIG="${WORK_DIR}/${SKEEN_PROC}.json"
readonly SKEEN_RUN_CONFIG="/tmp/${SKEEN_PROC}.json"
readonly SKEEN_AUTOSTART_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"
readonly SKEEN_SCRIPT_URL="${SKEEN_API_URL}/download/skeen_ru $CURL_RESOLVE_FIX"

readonly SINGBOX_NAME="Sing-box"
readonly SINGBOX_PID_FILE="/tmp/run/skeen.pid"
readonly SINGBOX_RUN_VERSION="/tmp/skeen_singbox_version"
readonly SINGBOX_BIN_PATH="${ENTWARE_DIR}/bin/skeen-box"
readonly SINGBOX_DEFAULT_CONFIG_PATH="${WORK_DIR}/config.json"
readonly SINGBOX_API_URL="https://github.com/SagerNet/sing-box/releases/latest"
readonly SINGBOX_API_URL_BETA="https://github.com/SagerNet/sing-box/releases.atom"
readonly SINGBOX_SPACE_MB=128

readonly FIREWALL_HOOK_FILE="${NETFILTER_DIR}/${SKEEN_PROC}_firewall.sh"
readonly WAIT_ROUTE_FILE="/tmp/${SKEEN_PROC}_wait_route"
readonly NET_EXCLUDE_SET="skeen_exclude_net"
readonly PORT_EXCLUDE_SET="skeen_exclude_port"
readonly FAKEIP_INTERCEPT_SET="skeen_fakeip_net"
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
  [ -t 1 ] || [ -t 2 ]
  ret=$?

  is_tty() { return "$ret"; }
  return "$ret"
}

cyan() { is_tty && printf '\033[36m%s\033[0m\n' "$1" || printf '%s\n' "$1"; }
red() { is_tty && printf '\033[31m%s\033[0m\n' "$1" || printf '%s\n' "$1"; }
green() { is_tty && printf '\033[32m%s\033[0m\n' "$1" || printf '%s\n' "$1"; }
yellow() { is_tty && printf '\033[33m%s\033[0m\n' "$1" || printf '%s\n' "$1"; }

echomsg() { cyan "[INFO]: $1"; }
echook() { green "[OK]: $1"; }
echowarn() { yellow "[WARN]: $1"; }
echoerr() { red "[ERROR]: $1"; }
exiterr() { red "[FATAL]: $1"; exit 1; }

check_tty() { is_tty || { echoerr "Command supports only tty"; exit 1; }; }

logger_notice() { logger -p notice -t "$SKEEN_NAME" "$1"; }
logger_warning() { logger -p warning -t "$SKEEN_NAME" "$1"; }
logger_error() { logger -p error -t "$SKEEN_NAME" "$1"; }

if is_tty; then
  cleanup() { stty sane </dev/tty 2>/dev/null || true; }
  trap cleanup EXIT TERM
  trap 'printf "\n"; cleanup; exit 130' INT
fi

create_skeen_config() {
  if [ "$1" = "force" ]; then
    rm -f "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG"
  elif [ -f "$SKEEN_CONFIG" ]; then
    echomsg "Configuration file $SKEEN_NAME already exists, skipping creation"
    return
  fi

  echomsg "Creating configuration file $SKEEN_NAME..."

  mkdir -p "$(dirname "$SKEEN_CONFIG")"

  cat <<EOF >"$SKEEN_CONFIG"
// https://github.com/jinndi/SKeen
{
  "auto_start": {
    "enabled": 1,
    "delay": 0
  },
  "policy": {
    "enabled": 0,
    "segment": "br1"
  },
  "network": {
    "ipv6": 1,
    "tuning": 0,
    "check": ["1.1.1.1", "ya.ru", "223.5.5.5"]
  },
  "singbox": {
    "config": {
      "path": "${SINGBOX_DEFAULT_CONFIG_PATH}",
      "url": "",
      "split": 1
    },
    "external": {
      "enabled": ${EXTERNAL_ENABLED:-0},
      "path": "",
      "config": {
        "path": "",
        "url": "",
        "split": 1
      }
    }
  },
  "services": {
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
        "include": "${WORK_DIR}/pure_cidr.list",
        "clients": []
      }
    },
    "exclude": {
      "port": ["137:139", 445, 1900],
      "ipv4_cidr": [],
      "ipv6_cidr": []
    },
    "redirect_dns": {
      "enabled": 0,
      "to_port": "",
      "use_policy": 1
    },
    "proxy_router": 0
  },
  "update": {
    "singbox": {
      "enabled": 1,
      "beta": ${BETA_ENABLED:-0}
    },
    "skeen": {
      "enabled": 1
    }
  }
}
EOF

  cp -fp "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG" >/dev/null 2>&1

  [ ! -f "$SKEEN_AUTOSTART_SCRIPT" ] && create_autostart_script >/dev/null 2>&1

  echook "Configuration file $SKEEN_NAME created successfully"
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

  [ -z "$config_path" ] && return 1

  arr="$(jsonfilter -i "$config_path" -e "${path}[*]")"

  if [ -n "$arr" ]; then
    echo "$arr"
    return
  fi

  jsonfilter -i "$config_path" -e "$path" | tr -d '[],"'
}

check_and_create_or_sync_skeen_config() {
  [ ! -f "$SKEEN_CONFIG" ] && create_skeen_config

  if [ ! -f "$SKEEN_RUN_CONFIG" ] || [ "$SKEEN_CONFIG" -nt "$SKEEN_RUN_CONFIG" ]; then
    if cp -fp "$SKEEN_CONFIG" "$SKEEN_RUN_CONFIG"; then
      chmod 644 "$SKEEN_RUN_CONFIG"
    else
      exiterr "Failed to synchronize $SKEEN_CONFIG to memory"
    fi
  fi
}

check_and_merge_singbox_config() {
  case "$SINGBOX_CONFIG" in
    /*) ;;
    *) SINGBOX_CONFIG="${WORK_DIR}/${SINGBOX_CONFIG}" ;;
  esac

  SINGBOX_CONFIG="${SINGBOX_CONFIG%/}"

  local merged_path="$WORK_DIR/.merged.json"
  [ "$SINGBOX_EXTERNAL_ENABLED" = "1" ] && merged_path="$WORK_DIR/.merged_external.json"
  SINGBOX_CONFIG_DIR=""

  if [ -d "$SINGBOX_CONFIG" ]; then
    SINGBOX_CONFIG_DIR="$SINGBOX_CONFIG"
    if [ ! -f "$merged_path" ] ||
      [ -n "$(find "$SINGBOX_CONFIG_DIR" -mindepth 1 -newer "$merged_path" -print -quit)" ];
    then
      if [ -n "$(find "$SINGBOX_CONFIG_DIR" -mindepth 1 -print -quit)" ]; then
        if ! "$SINGBOX_BIN" merge "$merged_path" -C "$SINGBOX_CONFIG_DIR" >/dev/null 2>&1; then
          exiterr "Failed to merge $SINGBOX_NAME config from $SINGBOX_CONFIG_DIR"
        fi
      else
        echowarn "Directory $SINGBOX_CONFIG_DIR is empty (no $SINGBOX_NAME configs found)"; sleep 2
      fi
    fi
    SINGBOX_CONFIG="$merged_path"
  elif [ "$SINGBOX_CONFIG" = "$merged_path" ]; then
    exiterr "Path $SINGBOX_CONFIG for $SINGBOX_NAME is reserved"
  elif [ ! -f "$SINGBOX_CONFIG" ]; then
    echowarn "$SINGBOX_NAME config missing at $SINGBOX_CONFIG"; sleep 2
  fi
}

check_and_kill_old_singbox_proc() {
  local sing_pid sing_path

  if [ -f "$SINGBOX_PID_FILE" ]; then
    read -r sing_pid < "$SINGBOX_PID_FILE"
    if [ -n "$sing_pid" ] && [ -d "/proc/$sing_pid" ]; then
      sing_path="$(readlink -f "/proc/$sing_pid/exe" 2>/dev/null)"
    fi
  fi

  case "$sing_path" in
    "" | "$SINGBOX_BIN") ;;
    *)
      if kill -0 "$sing_pid" 2>/dev/null; then
        echomsg "Terminating $SINGBOX_NAME (old process)..."
        kill -9 "$sing_pid"; clean_firewall; rm -f "$SINGBOX_PID_FILE"
      fi
    ;;
  esac

  if [ -f "$SINGBOX_BIN" ] && [ ! -x "$SINGBOX_BIN" ]; then
    chmod +x "$SINGBOX_BIN" 2>/dev/null || true
  fi
}

get_auto_start_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e AUTO_START_ENABLED='@.auto_start.enabled' \
      -e AUTO_START_DELAY='@.auto_start.delay'
  )"
  : "${AUTO_START_ENABLED:=1}"
  : "${AUTO_START_DELAY:=0}"
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
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e sing_config_path='@.singbox.config.path' \
      -e sing_config_url='@.singbox.config.url' \
      -e sing_config_split='@.singbox.config.split' \
      -e SINGBOX_EXTERNAL_ENABLED='@.singbox.external.enabled' \
      -e sing_external_path='@.singbox.external.path' \
      -e sing_external_config_path='@.singbox.external.config.path' \
      -e sing_external_config_url='@.singbox.external.config.url' \
      -e sing_external_config_split='@.singbox.external.config.split'
  )"

  : "${sing_config_path:=$SINGBOX_DEFAULT_CONFIG_PATH}"
  : "${sing_config_url:=}"
  : "${sing_config_split:=1}"
  : "${SINGBOX_EXTERNAL_ENABLED:=0}"
  : "${sing_external_path:=/opt/bin/sing-box}"
  : "${sing_external_config_path:=$sing_config_path}"
  : "${sing_external_config_url:=$sing_config_url}"
  : "${sing_external_config_split:=$sing_config_split}"

  if [ "$SINGBOX_EXTERNAL_ENABLED" = "1" ]; then
    [ -f "$sing_external_path" ] || sing_external_path="$(command -v "$sing_external_path")"
    SINGBOX_BIN="$sing_external_path"
    SINGBOX_CONFIG="$sing_external_config_path"
    SINGBOX_CONFIG_URL="$sing_external_config_url"
    SINGBOX_CONFIG_SPLIT="$sing_external_config_split"
  else
    SINGBOX_BIN="$SINGBOX_BIN_PATH"
    SINGBOX_CONFIG="$sing_config_path"
    SINGBOX_CONFIG_URL="$sing_config_url"
    SINGBOX_CONFIG_SPLIT="$sing_config_split"
  fi

  check_and_merge_singbox_config
  check_and_kill_old_singbox_proc
}

get_service_proxy_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e SERVICE_PROXY_ENABLED='@.services.proxy.enabled' \
      -e SERVICE_PROXY_PORT='@.services.proxy.port' \
      -e SERVICE_PROXY_USER='@.services.proxy.user' \
      -e SERVICE_PROXY_PASS='@.services.proxy.pass'
  )"
  : "${SERVICE_PROXY_ENABLED:=0}"
  : "${SERVICE_PROXY_PORT:=}"
  : "${SERVICE_PROXY_USER:=}"
  : "${SERVICE_PROXY_PASS:=}"
}

get_firewall_config() {
  local config_path
  config_path="$(get_skeen_config_path)"

  [ -n "$config_path" ] && eval "$(
    jsonfilter -i "$config_path" \
      -e POLICY_ENABLED='@.policy.enabled' \
      -e POLICY_SEGMENT='@.policy.segment' \
      -e NETWORK_IPV6='@.network.ipv6' \
      -e NETWORK_TUNING='@.network.tuning' \
      -e FIREWALL_INTERCEPT_DNS='@.firewall.intercept.dns' \
      -e FIREWALL_INTERCEPT_FAKEIP='@.firewall.intercept.fakeip.enabled' \
      -e FIREWALL_INTERCEPT_FAKEIP_INCLUDE='@.firewall.intercept.fakeip.include' \
      -e FIREWALL_REDIRECT_DNS_ENABLED='@.firewall.redirect_dns.enabled' \
      -e FIREWALL_REDIRECT_DNS_PORT='@.firewall.redirect_dns.to_port' \
      -e FIREWALL_REDIRECT_DNS_USE_POLICY='@.firewall.redirect_dns.use_policy' \
      -e FIREWALL_PROXY_ROUTER='@.firewall.proxy_router'
  )"

  : "${POLICY_ENABLED:=0}"
  : "${POLICY_SEGMENT:=br1}"
  : "${NETWORK_IPV6:=1}"
  : "${NETWORK_TUNING:=0}"
  : "${FIREWALL_INTERCEPT_DNS:=1}"
  : "${FIREWALL_INTERCEPT_FAKEIP:=0}"
  : "${FIREWALL_INTERCEPT_FAKEIP_INCLUDE:=/opt/etc/skeen/pure_cidr.list}"
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
      -e UPDATE_SKEEN_ENABLED='@.update.skeen.enabled'
  )"

  : "${UPDATE_SINGBOX_ENABLED:=1}"
  : "${UPDATE_SINGBOX_BETA:=0}"
  : "${UPDATE_SKEEN_ENABLED:=1}"
}

run_curl() {
  local proxy_opts=""
  local err_template="Service proxy is enabled but"

  get_service_proxy_config

  if [ "$SERVICE_PROXY_ENABLED" = "1" ]; then
    if [ -z "$SERVICE_PROXY_PORT" ]; then
      echoerr "$err_template 'service_proxy.port' is not set" && return 1
    elif ! is_running; then
      echoerr "$err_template $SINGBOX_NAME is not running" && return 1
    elif ! netstat -tuln 2>/dev/null | grep -q ":${SERVICE_PROXY_PORT}"; then
      echoerr "$err_template no process is listening on port ${SERVICE_PROXY_PORT}" && return 1
    else
      proxy_opts="--socks5-hostname 127.0.0.1:${SERVICE_PROXY_PORT}"
      if [ -n "$SERVICE_PROXY_USER" ] && [ -n "$SERVICE_PROXY_PASS" ]; then
        proxy_opts="$proxy_opts --proxy-user ${SERVICE_PROXY_USER}:${SERVICE_PROXY_PASS}"
      fi
    fi
  fi

  # shellcheck disable=SC2086
  curl -fL --connect-timeout 5 --max-time 1800 --speed-limit 1000 --speed-time 15 \
    --retry 2 --retry-delay 2 --retry-all-errors $proxy_opts "$@"
}

get_current_version() {
  local proc="${1:-}"

  case "$proc" in
  "sing")
    if [ -f "$SINGBOX_BIN" ]; then
      local cached_path cached_ver

      if [ -f "$SINGBOX_RUN_VERSION" ]; then
        IFS='|' read -r cached_path cached_ver < "$SINGBOX_RUN_VERSION" 2>/dev/null
      fi

      if [ "$cached_path" = "$SINGBOX_BIN" ] && [ "$SINGBOX_BIN" -ot "$SINGBOX_RUN_VERSION" ]; then
        echo "$cached_ver"
        return 0
      fi

      local ver raw_output
      raw_output="$("$SINGBOX_BIN" version 2>/dev/null)"
      set -- $raw_output
      ver="${3:-unknown}"

      echo "${SINGBOX_BIN}|${ver}" > "$SINGBOX_RUN_VERSION"
      echo "$ver"
    fi
    ;;
  "skeen") echo "$SKEEN_VERSION" ;;
  esac
}

get_latest_version() {
  local api_url="${1:-}" sing_beta="${2:-}" latest_release tag

  if [ "$sing_beta" = "1" ]; then
    latest_release="$(run_curl -s "$api_url")"
    tag="$(echo "$latest_release" | grep -oE '<title>[^<]+' | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?' | head -n 1 | sed 's/^v//')"
  else
    latest_release="$(run_curl -sI -H "Cache-Control: no-cache" "${api_url}?$(date +%s)")"
    tag="$(echo "$latest_release" | grep -i "^location:" | sed -E 's/.*tag\/(.*)/\1/' | tr -d '\r' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
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
  local required_mb="${1:-$SINGBOX_SPACE_MB}"
  local path="${2:-$ENTWARE_DIR}"
  local free_mb

  free_mb="$(df -m "$path" 2>/dev/null | tail -1 | awk '{print $4}')"

  if [ -z "$free_mb" ]; then
    exiterr "Failed to determine free space on $path"
  elif [ "$free_mb" -lt "$required_mb" ]; then
    exiterr "Insufficient free space on $path: ${required_mb}MB required, ${free_mb}MB available"
  fi
}

get_os_release() {
  local release_path

  release_path="$(command -v opkg)"

  if [ "$release_path" != "/opt/bin/opkg" ]; then
    exiterr "Unsupported the system OS!"
  else
    PKG_OS="openwrt"
    PKG_SUFFIX=".ipk"
  fi
}

ask_install_singbox() {
  show_header; printf "\n"
  while :; do
    cyan "$SINGBOX_NAME installation options:"
    printf " 1) Latest stable\n 2) Latest alpha/beta/rc\n 3) Use custom binary\n\n"
    printf "Select an option [1-3]: " >/dev/tty
    read -r opt </dev/tty;

    BETA_ENABLED=0; EXTERNAL_ENABLED=0

    case ${opt:-1} in
      1) break ;;
      2) BETA_ENABLED=1; break ;;
      3) EXTERNAL_ENABLED=1; break ;;
      *) echoerr "Please enter 1, 2, or 3."; printf "\n" ;;
    esac
  done
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

  [ -z "$ARCH" ] && exiterr "Unsupported CPU architecture"

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

  echomsg "Detected CPU architecture: $(green "$PKG_ARCH")"
}

wait_input() {
  local oldstty
  oldstty=$(stty -g </dev/tty)
  stty -icanon -echo min 1 time 0 </dev/tty
  dd bs=1 count=1 </dev/tty 2>/dev/null
  stty "$oldstty" </dev/tty
  echo >/dev/tty
}

install_dependencies() {
  echomsg "Checking dependencies"

  opkg update >/dev/null 2>&1
  local pkg_list
  pkg_list="$(opkg list 2>/dev/null | awk '{print $1}')"

  for pkg_name in $DEPENDENCIES; do
    printf "[%s] " "$pkg_name" >&2

    if command -v "$pkg_name" >/dev/null 2>&1; then
      echook "Already installed"
      continue
    fi

    case "$pkg_list" in
    *"$pkg_name"*)
      if opkg install "$pkg_name" >/dev/null 2>&1; then
        echook "Installed"
      else
        exiterr "Installation error"
      fi
      ;;
    *) exiterr "Package not found in opkg repositories" ;;
    esac
  done

  echook "All dependencies are installed"
}

download_singbox() {
  local beta="${1:-}" version="${2:-$latest_version}" pkg_url

  if [ -z "$version" ] && [ -z "$MIRROR" ]; then
    echomsg "Fetching the latest version..."
    local api_url="$SINGBOX_API_URL"
    [ "$beta" = "1" ] && api_url="$SINGBOX_API_URL_BETA"
    version="$(get_latest_version "$api_url" "$beta")"
    [ -z "$version" ] && echoerr "Failed to fetch the latest version" && exit 1

    echook "Latest version is $version"
  fi

  if [ -z "$MIRROR" ]; then
    PKG_NAME="sing-box_${version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
    pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${version}/${PKG_NAME} $CURL_RESOLVE_FIX"
  else
    PKG_NAME="sing-box_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
    local sing_folder="sing-box"
    [ "$beta" = "1" ] && sing_folder="sing-box-beta"
    pkg_url="${MIRROR}${sing_folder}/${PKG_NAME}"
  fi

  echomsg "Downloading ${PKG_NAME}..."

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR" || exit 1

  # shellcheck disable=SC2086
  if run_curl -o "$PKG_NAME" $pkg_url; then
    echook "Downloaded $PKG_NAME successfully"
  else
    echoerr "Failed to download $PKG_NAME"
    [ -n "$latest_version" ] && return 1 || exit 1
  fi
}

install_singbox() {
  local tmp_unpack_dir="${TMP_DIR}/sing-box-unpack"

  [ -d "$tmp_unpack_dir" ] && rm -rf "$tmp_unpack_dir"

  echomsg "Extracting $PKG_NAME"
  mkdir -p "$tmp_unpack_dir"
  cd "$tmp_unpack_dir" || exit 1

  if tar -xzf "../${PKG_NAME}" && tar -xzf data.tar.gz; then
    echook "Extraction completed"
  else
    rm -rf "$tmp_unpack_dir"
    rm -f "${TMP_DIR}/${PKG_NAME}"
    exiterr "Error extracting $PKG_NAME"
  fi

  echomsg "Installing $SINGBOX_NAME binary to $SINGBOX_BIN_PATH"
  [ -f "$SINGBOX_BIN_PATH" ] && rm -f "$SINGBOX_BIN_PATH"
  mv ./usr/bin/sing-box "$SINGBOX_BIN_PATH"
  chmod 755 "$SINGBOX_BIN_PATH"
  rm -f "$SINGBOX_RUN_VERSION"

  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${PKG_NAME}"

  echook "$SINGBOX_NAME binary installed successfully"
}

download_singbox_config() {
  local beta="${1:-}" action="${2:-}"

  get_singbox_config
  local backup_config="${SINGBOX_CONFIG}.bak"

  if [ "$act" != "force" ] && [ -f "$SINGBOX_CONFIG" ]; then
    echomsg "Configuration $SINGBOX_NAME found, skipping creation"
    return
  fi

  echomsg "Downloading $SINGBOX_NAME configuration..."

  mkdir -p "$(dirname "$SINGBOX_CONFIG")"

  [ -f "$SINGBOX_CONFIG" ] && mv -f "$SINGBOX_CONFIG" "$backup_config"

  local config_name="config.json" config_url=""
  [ "$beta" = "1" ] && config_name="config_beta.json"

  if [ -n "$MIRROR" ]; then
    config_url="${MIRROR}${config_name}"
  else
    config_url="${REPO_MAIN_BRANCH}${config_name}"
  fi

  if ! run_curl -o "$SINGBOX_CONFIG" $config_url; then
    [ -f "$backup_config" ] && mv -f "$backup_config" "$SINGBOX_CONFIG"
    echoerr "Failed to download $SINGBOX_NAME configuration"
    return 1
  fi

  echook "$SINGBOX_NAME configuration downloaded successfully"
}

create_autostart_script() {
  echomsg "Create $SKEEN_NAME autostart script..."

  [ -f "$SKEEN_AUTOSTART_SCRIPT" ] && rm -f "$SKEEN_AUTOSTART_SCRIPT"

  mkdir -p "$(dirname "$SKEEN_AUTOSTART_SCRIPT")"

  {
    echo "#!/bin/sh"
    echo "PATH=$PATH"
    echo "$SKEEN_PROC start init"
  } >"$SKEEN_AUTOSTART_SCRIPT"

  chmod 755 "$SKEEN_AUTOSTART_SCRIPT"
  chmod +x "$SKEEN_AUTOSTART_SCRIPT"

  echook "Autostart script created successfully"
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

  exiterr "No free GID available"
}

create_skeen_group() {
  local name="$SKEEN_PROC"
  local group_file="${ENTWARE_DIR}/etc/group"
  local gid_num

  if ! grep -q "^${name}:" "$group_file" 2>/dev/null; then
    gid_num=$(get_free_gid "$group_file" 1000)

    echomsg "Creating group $name with GID ${gid_num}..."
    addgroup -g "$gid_num" "$name" >/dev/null 2>&1 ||
      exiterr "Failed to create group $name"
    echook "Group $name created successfully"
    return 2
  else
    return 0
  fi
}

download_skeen_script() {
  local action="${1:-}"
  local backup_script="${SKEEN_SCRIPT}.bak"
  local script_url="$SKEEN_SCRIPT_URL"

  echomsg "Downloading $SKEEN_NAME script at $SKEEN_SCRIPT"

  [ -f "$SKEEN_SCRIPT" ] && mv -f "$SKEEN_SCRIPT" "$backup_script"

  if [ -n "$MIRROR" ]; then
    script_url="${MIRROR}skeen"
  fi

  # shellcheck disable=SC2086
  if ! run_curl -o "$SKEEN_SCRIPT" $script_url; then
    [ -f "$backup_script" ] && mv -f "$backup_script" "$SKEEN_SCRIPT"
    echoerr "Failed to download $SKEEN_NAME script"
    [ "$action" != "update" ] && exit 1
    return 1
  fi

  chmod 755 "$SKEEN_SCRIPT"
  chmod +x "$SKEEN_SCRIPT"

  [ -f "$backup_script" ] && rm -f "$backup_script"

  echook "$SKEEN_NAME script downloaded successfully"
  return 0
}

press_any_key_to_menu() {
  local action="${1:-}"
  local exit_code="${2:-0}"

  [ "$CALLER" != "menu" ] && exit "$exit_code"

  echo "$DELIMETER"

  printf "Press any key to open menu..." >/dev/tty
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
  MIRROR="${MIRROR:-}"

  if [ -n "$MIRROR" ]; then
    case "$MIRROR" in
    https://*static/ | http://*static/) echomsg "Using mirror: $MIRROR"; printf "\n"; ;;
    *) exiterr "Mirror URL must start with http(s):// and end with static/"; ;;
    esac
  fi

  get_os_release
  ask_install_singbox
  if [ "$EXTERNAL_ENABLED" != "1" ]; then
    check_free_space
    get_architecture
    download_singbox "$BETA_ENABLED"
    install_singbox
  fi
  install_dependencies
  download_singbox_config "$BETA_ENABLED"
  create_autostart_script
  create_skeen_group
  download_skeen_script
  create_skeen_config

  if [ "$EXTERNAL_ENABLED" != "1" ]; then
    "$SINGBOX_BIN_PATH" version
  elif [ ! -f /opt/bin/sing-box ]; then
    echomsg "Set the $SINGBOX_NAME binary path in $SKEEN_CONFIG"
  fi

  echomsg "Configure $SINGBOX_NAME by editing: $CONFIG_DIR"
  echomsg "Configure $SKEEN_NAME by editing: $SKEEN_CONFIG"
  echook "Installation completed"

  MIRROR=""

  press_any_key_to_menu
}

uninstall() {
  echomsg "Uninstalling ${SKEEN_NAME}..."

  is_running && stop

  echomsg "Removing auto-start script..."
  rm -f "$SKEEN_AUTOSTART_SCRIPT"

  echomsg "Removing firewall hook script..."
  rm -f "$FIREWALL_HOOK_FILE"

  echomsg "Removing $SKEEN_NAME script..."
  rm -f "$SKEEN_SCRIPT"

  echomsg "Removing ${SKEEN_NAME} caches..."
  rm -f "$SKEEN_RUN_SCRIPT" "$SKEEN_RUN_CONFIG" "$SINGBOX_RUN_VERSION"

  echomsg "Delete group ${SKEEN_PROC}..."
  delgroup "$SKEEN_PROC"

  if [ -f "$SINGBOX_BIN_PATH" ]; then
    while :; do
      printf "Delete %s? [y/n]: " "$SINGBOX_NAME" >/dev/tty
      read -r opt </dev/tty
      opt=${opt:-n}
      case $opt in
      y | Y) echomsg "Removing $SINGBOX_NAME binary..."; rm -f "$SINGBOX_BIN_PATH"; break ;;
      n | N) echomsg "File $SINGBOX_BIN_PATH kept!"; break ;;
      *) echoerr "Please enter y (yes) or n (no)." ;;
      esac
    done
  fi

  if [ -d "$WORK_DIR" ]; then
    echowarn "Configuration directory $WORK_DIR is retained"
    echowarn "If you want to remove it manually, run: rm -rf $WORK_DIR"
  fi
  echook "${SKEEN_NAME} has been uninstalled successfully"
  echo "$DELIMETER"
  cyan "For reinstallation, use:"
  green "curl -Ls https://github.com/jinndi/SKeen/releases/latest/download/skeen $CURL_RESOLVE_FIX | sh"
  exit 0
}

accept_uninstall() {
  local max_attempts=3
  local attempt=0
  local option

  while [ $attempt -lt $max_attempts ]; do
    printf "Uninstall, %s? [y/n]: " "$SKEEN_NAME" >/dev/tty
    read -r option </dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
    y | Y) uninstall ;;
    n | N) break ;;
    *)
      echoerr "Incorrect option"
      attempt=$((attempt + 1))
      ;;
    esac
  done

  show_menu
}

get_net_check_hosts() {
  local ipv="${1:-}"
  local hosts sys_hosts count result
  local max="3"

  if [ "$ipv" = "4" ]; then
    sys_hosts="1.1.1.1 77.88.8.8 223.5.5.5"
    hosts="$(json_get_array '@.network.check') $sys_hosts"
  else
    sys_hosts="2606:4700:4700::1111 2a02:6b8::feed:0ff 2400:3200::1"
  fi

  if [ -z "$hosts" ]; then
    echo "$sys_hosts"
  else
    hosts="$(echo "$hosts" |
      tr ',\t\n' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')"

    # shellcheck disable=SC2086
    set -- $hosts

    count=0
    result=""

    while [ $# -gt 0 ] && [ "$count" -lt "$max" ]; do
      result="${result:+$result }$1"
      count=$((count + 1))
      shift
    done

    echo "$result"
  fi
}

check_internet() {
  local hosts host attempt
  local max_attempts=3

  hosts="$(get_net_check_hosts "4")"
  max_attempts=3

  for host in $hosts; do
    attempt=1
    while [ $attempt -le $max_attempts ]; do
      if ping -c 1 "$host" >/dev/null 2>&1; then
      logger_notice "Internet is available via ${host}"
      return 0
      else
        logger_warning "Internet is not available (${host}), attempt ${attempt}/${max_attempts}..."
    fi
      attempt=$((attempt + 1))
      sleep 10
    done
  done

  logger_error "Internet is not available via any of the checked hosts"
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
      msg_err="Port $port is in use. Free it and try running again"
      echoerr "$msg_err"
      logger_error "$msg_err"
      press_any_key_to_menu "" 1
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

  echoerr "Module '$module' not found or failed to load"
  return 1
}

loading_modules() {
  local modules="${1:-xt_TPROXY.ko xt_socket.ko xt_owner.ko xt_comment.ko ip_set_bitmap_port.ko}"
  local err_msg="Please install router component: «Kernel modules for Netfilter»"

  KERNEL_OS_V="$(uname -r)"

  for module in $modules; do
    if ! load_module "$module"; then
      echoerr "$err_msg"
      logger_error "$err_msg"
      press_any_key_to_menu "" 1
      return 1
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
      echowarn "IPv6 enabled in ${SKEEN_NAME}, but no IPv6 connectivity detected" >&2
    fi
  fi

  echo "$ipt_list"
}

get_mark_policy() {
  local mark=""

  if [ "$POLICY_ENABLED" = "1" ] && [ -n "$POLICY_SEGMENT" ]; then
    local seg=$(echo "$POLICY_SEGMENT" | tr '[:upper:]' '[:lower:]')
    case "$seg" in
      br[0-9]|br[0-9][0-9])
        mark=$(iptables -t mangle -L -v -n | awk -v iface="$seg" '$0 ~ iface && /MARK set/ {print $NF}')
        ;;
      *) echowarn "Segment name must start with 'br' followed by 1 or 2 digits" >&2 ;;
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

    local msg="Check your internet connection"
    [ -n "$SKEEN_MARK_POLICY" ] && msg="$msg for segment ${SKEEN_POLICY_SEGMENT:-unknown}"

    echoerr "$msg"; logger_warning "$msg"

    [ "$CALLER" = "netfilter" ] && exit 0

    press_any_key_to_menu "" 1; return 1
  fi

  case "$SKEEN_FIREWALL_MODE" in
    redirect|tun|dns|none) return 0 ;;
  esac

  ip -"$IP_VERSION" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1 || true
  ip -"$IP_VERSION" rule add fwmark "$TABLE_MARK" lookup "$TABLE_ID" pref "$TABLE_ID" || {
    msg="Failed to add IP rule for family $IP_VERSION"
    echoerr "$msg"; logger_error "$msg"
    press_any_key_to_menu "" 1; return 1
  }
  ip -"$IP_VERSION" route replace local default dev lo table "$TABLE_ID" || {
    msg="Failed to replace local route in table $TABLE_ID"
    echoerr "$msg"; logger_error "$msg"
    press_any_key_to_menu "" 1; return 1
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
    local msg="Invalid $label port(s): $invalid_ports"
    logger_warning "$msg"
    is_tty && echowarn "$msg" >&2
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
    is_tty && echowarn "Invalid IPv$ip_v exclude: $invalid_list"
    logger_warning "Invalid IPv$ip_v exclude: $invalid_list"
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

check_and_create_chain() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"

  if chain_exists "$iptables" "$table" "$chain"; then
    return 1
  else
    $iptables -w -t "$table" -N "$chain" 2>/dev/null
  fi
}

create_or_flush_chain() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"

  if chain_exists "$iptables" "$table" "$chain"; then
    $iptables -w -t "$table" -F "$chain" 2>/dev/null
  else
    $iptables -w -t "$table" -N "$chain" 2>/dev/null
  fi
}

add_skeen_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local type="${4:-}"
  local protocols="${5:-}"
  local connmark_match_opt=""

  add_conntrack_mark() {
    local chain="${1:-}"

    if echo "$protocols" | grep -q "tcp"; then
      connmark_match_opt="-m connmark --mark $TABLE_MARK"

      add_rule "$iptables" "$table" "$chain" \
          -p tcp -m conntrack --ctstate NEW -j CONNMARK --set-mark "$TABLE_MARK"
    fi
  }

  get_connmark_match_opt() {
    local proto="${1:-}"
    if [ -n "$connmark_match_opt" ] && [ "$proto" = "tcp" ]; then
      echo "$connmark_match_opt"
    fi
  }

  case "$type" in
  "socket")
    if echo "$protocols" | grep -q "tcp"; then
      create_or_flush_chain "$iptables" "$table" "$CHAIN_DIVERT" || return 0
      add_rule "$iptables" "$table" "$CHAIN_DIVERT" -j MARK --set-mark "$TABLE_MARK"
      add_rule "$iptables" "$table" "$CHAIN_DIVERT" -j ACCEPT
      add_rule "$iptables" "$table" "$chain" -p tcp -m socket --transparent -g "$CHAIN_DIVERT"
    fi
    ;;

  "ctdir_reply")
    add_rule "$iptables" "$table" "$chain" -m conntrack --ctdir REPLY -j ACCEPT
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
    if echo "$protocols" | grep -q "tcp"; then
      add_conntrack_mark "$chain"
    fi

    for proto in $protocols; do
      # shellcheck disable=SC2086
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
    # shellcheck disable=SC2086
    add_rule "$iptables" "$table" "$chain" \
      -p "$protocols" $(get_connmark_match_opt "$protocols") -j REDIRECT --to-port "$SKEEN_REDIRECT_PORT"
    ;;

  "proxy_router_owner")
    add_rule "$iptables" "$table" "$chain" -m owner --gid-owner "$SKEEN_PROC" -j ACCEPT
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
    add_rule "$iptables" "$table" "$chain" -j MARK --set-mark "$TABLE_MARK"
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
      add_skeen_rules "$iptables" "$table" "$chain" "socket" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "ctdir_reply" "$protocols"
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
    add_skeen_rules "$iptables" "$table" "$chain" "proxy_router_owner" "$protocols"
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
  local r1="" r2=""

  # shellcheck disable=SC2086
  $iptables -w -t "$table" -S "$target_chain" >/dev/null 2>&1 || return 0

  if [ "$chain" = "PREROUTING" ] && [ -n "$SKEEN_MARK_POLICY" ]; then
    r1="-m connmark --mark $SKEEN_MARK_POLICY $base"
    [ "$table" != "$TABLE_REDIRECT" ] && [ "$SKEEN_PROXY_ROUTER" = "1" ] && r2="-m mark --mark $TABLE_MARK $base"
  else
    r1="$base"
  fi

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
  major=  major=$(ndmc -c "show version" | awk '/release:/ {print $2}' | cut -d'.' -f1)

  if [ "$major" -lt 5 ]; then
    echoerr "Release version KeeneticOS is lower than 5" && return 1
  fi
}

tun_create() {
  local opkgtun_ip="${1:-}"
  local opkgtun_desc="${2:-}"
  local opkgtun_name="OpkgTun0"
  local inface_list opkgtun_ids opkgtun_name_lower

  if [ -z "$opkgtun_ip" ] || [ -z "$opkgtun_desc" ]; then
    echomsg "Use the following format to create an OpkgTun interface:"
    echomsg "skeen tun create <ipv4> <name>"
    return
  fi

  case "$opkgtun_desc" in
  [!A-Za-z0-9_-]*)
    exiterr "Invalid name, allowed characters: A–Z, a–z, 0–9, _ and -"
    ;;
  esac

  if ! is_valid_ipv4 "$opkgtun_ip"; then
    echoerr "Invalid IPv4 address specified"
    return
  fi
  opkgtun_ip="${opkgtun_ip%%/*}"

  inface_list="$(ndmc -c show interface)"

  if echo "$inface_list" |
    grep -q "^[[:space:]]*description:[[:space:]]*$opkgtun_desc$"; then
    echoerr "Interface named \"$opkgtun_desc\" already exists"
    return
  fi

  if echo "$inface_list" |
    awk -v ip="$opkgtun_ip" '/^[[:space:]]*address:/ {
        sub(/.*: */, "", $0)
        if ($0 == ip) found=1
    }
    END { exit !found }'; then
    exiterr "IP address $opkgtun_ip is already in use"
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
    exiterr "Failed to set ${1} the interface"
  }

  ndmc -c interface "$opkgtun_name" || { echoerr "Failed to create the interface" && return; }
  ndmc -c interface "$opkgtun_name" description "$opkgtun_desc" || tun_delete_msg "description"
  ndmc -c interface "$opkgtun_name" ip address "${opkgtun_ip}/32" || tun_delete_msg "ip address"
  ndmc -c interface "$opkgtun_name" ip tcp adjust-mss pmtu || tun_delete_msg "ip tcp adjust-mss pmtu"
  ndmc -c ip route default "$opkgtun_ip" "$opkgtun_name" || tun_delete_msg "ip route default"
  ndmc -c interface "$opkgtun_name" ip global auto || tun_delete_msg "ip global auto"
  ndmc -c interface "$opkgtun_name" up && ndmc -c system configuration save

  echook "OpkgTun interface named \"$opkgtun_desc\" was created successfully"
  echo "Use the name $(green "\"$opkgtun_name_lower\"") for the $(yellow "\"interface_name\"") field in the tun configuration"
}

tun_delete() {
  local opkgtun_desc="${1:-}"
  local opkgtun_name

  if [ -z "$opkgtun_desc" ]; then
    echoerr "Please specify the name of the OpkgTun interface to delete"
    echomsg "skeen tun delete <name>"
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
      echook "Interface \"$opkgtun_name\" has been successfully deleted"
      ;;
    *)
      echoerr "Interface name: \"$opkgtun_name\" not OpkgTun"
      echoerr "You can only delete an OpkgTun interface"
      ;;
    esac
  else
    echoerr "Interface named $opkgtun_desc does not exist"
  fi
}

tun_list() {
  local opkgtun_list
  opkgtun_list="$(ndmc -c show interface | awk '/^Interface, name = "OpkgTun/ {p=1} /^Interface, name =/ && !/^Interface, name = "OpkgTun/ {p=0} p')"
  [ -z "$opkgtun_list" ] && echomsg "No OpkgTun interfaces found" || echo "$opkgtun_list"
}

set_tun_rules() {
  apply_rule() {
    table="$1"
    shift

    iptables -w -t "$table" -C "$@" 2>/dev/null || \
    iptables -w -t "$table" -A "$@"
  }

  iptables -t filter -N "$CHAIN_TUN" 2>/dev/null
  apply_rule filter INPUT -i opkgtun+ -j "$CHAIN_TUN"
  apply_rule filter "$CHAIN_TUN" -i opkgtun+ -j ACCEPT
  apply_rule filter "$CHAIN_TUN" -o opkgtun+ -j ACCEPT
  apply_rule nat POSTROUTING -o opkgtun+ -j MASQUERADE -m comment --comment "$CHAIN_TUN"
}

get_skeen_run_script_cmd() {
  if [ ! -f "$SKEEN_RUN_SCRIPT" ] || [ "$SKEEN_SCRIPT" -nt "$SKEEN_RUN_SCRIPT" ]; then
    if cp -fp "$SKEEN_SCRIPT" "$SKEEN_RUN_SCRIPT"; then
      chmod 755 "$SKEEN_RUN_SCRIPT"
      echo "$SKEEN_RUN_SCRIPT apply_firewall netfilter \"\$table\""
    else
      echo "$SKEEN_PROC apply_firewall netfilter \"\$table\""
    fi
  fi
}

prepare_firewall() {
  local complete_msg redirect_data tproxy_data has_opkgtun route_all exclude_ports

  echomsg "Preparing a firewall:"

  complete_msg="Firewall preparation is complete"

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

  cyan " - Detected firewall mode: $SKEEN_FIREWALL_MODE $has_opkgtun"

  get_firewall_config

  SKEEN_INTERCEPT_DNS_ENABLED="0"
  SKEEN_REDIRECT_DNS_ENABLED="0"
  SKEEN_REDIRECT_DNS_PORT=""

  if has_dns_servers; then
    local msg_dns_detect=" - Detected DNS configuration:"
    if [ "$FIREWALL_REDIRECT_DNS_ENABLED" = "1" ]; then
      if [ -z "$FIREWALL_REDIRECT_DNS_PORT" ]; then
        echoerr "DNS redirect enabled, but port is missing in $SKEEN_NAME config"
        press_any_key_to_menu "" 1
      fi
      check_port "$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_ENABLED="1"
      SKEEN_REDIRECT_DNS_PORT="$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_USE_POLICY="$FIREWALL_REDIRECT_DNS_USE_POLICY"
      [ "$SKEEN_FIREWALL_MODE" = "none" ] && SKEEN_FIREWALL_MODE="dns"
      cyan "$msg_dns_detect redirect"
    fi

    if [ "$FIREWALL_REDIRECT_DNS_ENABLED" = "1" ] && [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      echowarn "DNS redirect/intercept conflict: using redirect only"
    elif [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      case "$SKEEN_FIREWALL_MODE" in
      tproxy | hybrid)
        SKEEN_INTERCEPT_DNS_ENABLED="1"
        cyan "$msg_dns_detect intercept"
      ;;
      *) echowarn "DNS intercept does not work in '$SKEEN_FIREWALL_MODE' mode" ;;
      esac
    fi
  elif [ "$FIREWALL_REDIRECT_DNS_ENABLED" = "1" ] || [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
    echowarn "DNS settings provided in ${SKEEN_NAME}, but $SINGBOX_NAME is not configured"
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ] || [ "$SKEEN_FIREWALL_MODE" = "dns" ]; then
    {
      echo "#!/bin/sh"
      echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"

      local tables="nat|filter"
      if [ "$SKEEN_FIREWALL_MODE" = "dns" ]; then
        tables="nat"
        SKEEN_IPTABLES_LIST="$(get_iptables_list)"
      else
        SKEEN_IPTABLES_LIST="iptables"
      fi

      echo "[ \"$SKEEN_IPTABLES_LIST\" = \"\$type\" ] || exit 0"
      echo "echo \"$tables\" | grep -q \"\$table\" || exit 0"

      echo "logger -p notice -t \"$SKEEN_NAME\" \"Updating \$type rules for \$table table\""

      echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""

      [ "$SKEEN_FIREWALL_MODE" = "tun" ] &&
        echo "export SKEEN_TUN_ENABLED=\"$SKEEN_TUN_ENABLED\""

      echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""

      if [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
        loading_modules xt_comment.ko
        [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] &&
          SKEEN_MARK_POLICY="$(get_mark_policy)"
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

  cyan " - Checking and loading modules..."
  loading_modules

  SKEEN_MARK_POLICY="$(get_mark_policy)"

  route_all=1
  if [ "$POLICY_ENABLED" != "1" ]; then
    cyan " - Segment disabled on skeen.json"
  elif [ -z "$POLICY_SEGMENT" ]; then
    cyan " - Segment name not set"
  elif [ -z "$SKEEN_MARK_POLICY" ]; then
    cyan " - Segment policy $POLICY_SEGMENT is not available"
  else
    cyan " - Segment policy routing: $POLICY_SEGMENT"
    route_all=0
  fi
  [ "$route_all" = 1 ] && echowarn "Routing entire device"

  SKEEN_PROXY_ROUTER="0"
  [ "$FIREWALL_PROXY_ROUTER" = "1" ] && SKEEN_PROXY_ROUTER="1"

  SKEEN_IPTABLES_LIST="$(get_iptables_list)"

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "No supported iptables found for the firewall mode?"
    press_any_key_to_menu "" 1
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

  if echo "$SKEEN_IPTABLES_LIST" | grep -q "iptables"; then
    setup_net_ipset 4 inet
  fi

  if [ "$NETWORK_IPV6" = "1" ] && echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6tables"; then
    setup_net_ipset 6 inet6
  fi

  setup_fakeip_ipset() {
    if [ ! -f "$FIREWALL_INTERCEPT_FAKEIP_INCLUDE" ]; then
      touch "$FIREWALL_INTERCEPT_FAKEIP_INCLUDE" || {
        echoerr "Error creating file $FIREWALL_INTERCEPT_FAKEIP_INCLUDE"
        return 1
      }
    fi

    local temp_file

    temp_file=$(mktemp) || {
      echoerr "Error creating temporary file for ipset $FAKEIP_INTERCEPT_SET"
      return 1
    }

    {
      echo "create ${FAKEIP_INTERCEPT_SET}4 hash:net family inet maxelem 65536 -exist"
      echo "add ${FAKEIP_INTERCEPT_SET}4 198.18.0.0/15 -exist"
      if [ "$NETWORK_IPV6" = "1" ]; then
        echo "create ${FAKEIP_INTERCEPT_SET}6 hash:net family inet6 maxelem 65536 -exist"
        echo "add ${FAKEIP_INTERCEPT_SET}6 fd00::/8 -exist"
      fi

      if [ -s "$FIREWALL_INTERCEPT_FAKEIP_INCLUDE" ]; then
        awk -v S="$FAKEIP_INTERCEPT_SET" -v V6="$NETWORK_IPV6" '
          { sub(/#.*/, ""); gsub(/^[ \t]+|[ \t]+$/, "") }
          $0 == "" { next }
          /:/  { if (V6 == "1") print "add " S "6 " $0 " -exist"; next }
               { print "add " S "4 " $0 " -exist" }
        ' "$FIREWALL_INTERCEPT_FAKEIP_INCLUDE"
      fi
    } > "$temp_file" || {
      rm -f "$temp_file"
      echoerr "Error writing to temporary file for ipset $FAKEIP_INTERCEPT_SET"
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

        local clients_src clients_src_count
        clients_src="$(json_get_array '@.firewall.intercept.fakeip.clients')"

        if [ -n "$clients_src" ]; then
          ipset create "$FAKEIP_CLIENTS_SRC_SET" hash:net family inet maxelem 100 -exist
          ipset flush "$FAKEIP_CLIENTS_SRC_SET"

          echo "$clients_src" | {
            while read -r addr; do
              [ -n "$addr" ] && printf "add %s %s -exist\n" "$FAKEIP_CLIENTS_SRC_SET" "$addr"
            done
          } | ipset restore

          clients_src_count=", clients: $(echo "$clients_src" | wc -l)"
          SKEEN_INTERCEPT_FAKEIP="2"
        fi
        cyan " - FakeIP interception enabled${clients_src_count}"
      else
        echoerr "Failed to configure FakeIP interception"
      fi
    else
      ipset destroy "${FAKEIP_INTERCEPT_SET}4" -exist 2>/dev/null
      ipset destroy "${FAKEIP_INTERCEPT_SET}6" -exist 2>/dev/null
      echowarn "$SINGBOX_NAME DNS не настроен, опция intercept.fakeip не будет работать!"
    fi
  fi

  [ -f "$FIREWALL_HOOK_FILE" ] && rm -f "$FIREWALL_HOOK_FILE"

  {
    echo "#!/bin/sh"
    echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"

    echo "echo \"$SKEEN_IPTABLES_LIST\" | grep -q \"\$type\" || exit 0"

    local postfix_tables=""
    if [ "$SKEEN_TUN_ENABLED" = "1" ]; then
      postfix_tables="|filter"
      [ "$SKEEN_FIREWALL_MODE" = "tproxy" ] && postfix_tables="|filter|nat"
    elif [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
      postfix_tables="|nat"
    fi

    local redirect="${TABLE_REDIRECT}${postfix_tables}"
    local hybrid="${TABLE_REDIRECT}|${TABLE_TPROXY}${postfix_tables}"
    local tproxy="${TABLE_TPROXY}${postfix_tables}"

    case "$SKEEN_FIREWALL_MODE" in
    hybrid) echo "echo \"$hybrid\" | grep -q \"\$table\" || exit 0" ;;
    tproxy) echo "echo \"$tproxy\" | grep -q \"\$table\" || exit 0" ;;
    redirect) echo "echo \"$redirect\" | grep -q \"\$table\" || exit 0" ;;
    *) echo "exit 0" ;;
    esac

    echo "logger -p notice -t \"$SKEEN_NAME\" \"Updating \$type rules for \$table table\""

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
    echo "$match" | grep -q "$hook_table" || return 1
  fi
}

apply_firewall() {
  local hook_table="${1:-}"
  local check iptables eth_subnets set_name

  check=$(echo "$SKEEN_IPTABLES_LIST" | sed 's/iptables//g; s/ip6tables//g; s/ //g')
  if [ -n "$check" ] || [ -z "$SKEEN_IPTABLES_LIST" ]; then
    local msg_err="Неизвестный iptables: ${iptables:-unknown}"
    logger_error "$msg_err"
    echoerr "$msg_err"
    press_any_key_to_menu "" 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" != "none" ] || [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
    echomsg "Applying firewall rules..."
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
      for proto in tcp udp; do
        # shellcheck disable=SC2086
        if ! $iptables -w -t nat -C "$CHAIN_DNS" -p "$proto" $args >/dev/null 2>&1; then
          $iptables -w -t nat -I "$CHAIN_DNS" -p "$proto" $args
        fi
      done
    done
  fi

  # TUN
  [ "$SKEEN_TUN_ENABLED" = "1" ] && check_hook_table "filter|nat" "$hook_table" && set_tun_rules

  # Exclude modes && tables
  echo "tun|dns|none" | grep -q "$SKEEN_FIREWALL_MODE" && return 0
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

    local protocols=""

    if [ "$SKEEN_FIREWALL_MODE" = "hybrid" ]; then
      for table in "$TABLE_TPROXY" "$TABLE_REDIRECT"; do
        ! check_hook_table "$table" "$hook_table" && continue
        check_and_create_chain "$iptables" "$table" "$CHAIN_PREROUTING" || return 0
        protocols="$(get_protocols "$table")"
        set_chain_rules "$iptables" "$table" "$CHAIN_PREROUTING" "$protocols"
        goto_chain_rules "$iptables" "$table" PREROUTING "$CHAIN_PREROUTING"
        [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$table" "$protocols"
      done
    elif [ "$SKEEN_FIREWALL_MODE" = "tproxy" ] && check_hook_table "$TABLE_TPROXY" "$hook_table"; then
      check_and_create_chain "$iptables" "$TABLE_TPROXY" "$CHAIN_PREROUTING" || return 0
      protocols="$(get_protocols "$TABLE_TPROXY")"
      set_chain_rules "$iptables" "$TABLE_TPROXY" "$CHAIN_PREROUTING" "$protocols"
      goto_chain_rules "$iptables" "$TABLE_TPROXY" PREROUTING "$CHAIN_PREROUTING"
      [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$TABLE_TPROXY" "$protocols"
    elif [ "$SKEEN_FIREWALL_MODE" = "redirect" ] && check_hook_table "$TABLE_REDIRECT" "$hook_table"; then
      check_and_create_chain "$iptables" "$TABLE_REDIRECT" "$CHAIN_PREROUTING" || return 0
      protocols="$(get_protocols "$TABLE_REDIRECT")"
      set_chain_rules "$iptables" "$TABLE_REDIRECT" "$CHAIN_PREROUTING" "$protocols"
      goto_chain_rules "$iptables" "$TABLE_REDIRECT" PREROUTING "$CHAIN_PREROUTING" "$protocols"
      [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$TABLE_REDIRECT"
    fi
  done

  [ -f "$WAIT_ROUTE_FILE" ] && rm -f "$WAIT_ROUTE_FILE"

  echook "Firewall rules applied successfully"
}

clean_firewall() {
  if [ -f "$SKEEN_RUN_SCRIPT" ]; then
    "$SKEEN_RUN_SCRIPT" clean_firewall run_state
    return 0
  fi

  echomsg "Cleaning firewall rules..."

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
  iptables -w -t nat -S POSTROUTING 2>/dev/null | \
    grep "$CHAIN_TUN" | sed "s/^-A/iptables -w -t nat -D/" | sh 2>/dev/null
  clean_chain "iptables" "filter" "$CHAIN_TUN" "INPUT"

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
  done
  ip route flush table "$TABLE_ID" 2>/dev/null

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

  echook "Firewall cleanup completed"
}

apply_sysctl_network_tuning() {
  get_connection_tracking() {
    local is_tuning="${1:-}"
    local mem_mb ct_max
    mem_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)

    if [ "$mem_mb" -le 128 ]; then
      ct_max=8192
    elif [ "$mem_mb" -le 256 ]; then
      ct_max=16384
    elif [ "$mem_mb" -le 512 ]; then
      ct_max=32768
    else
      ct_max=65536
    fi

    if [ -n "$is_tuning" ] && [ "$is_tuning" != "0" ]; then
      ct_max=$(( (ct_max * 15) / 10 ))
    fi

    echo "$ct_max"
  }

  {
    local ct_max

    # TProxy/TUN (needed for TUN/TProxy)
    sysctl -w net.ipv4.ip_forward=1               # Enable IPv4 routing
    sysctl -w net.ipv4.conf.all.src_valid_mark=0  # Accept TProxy marked packets
    sysctl -w net.ipv4.conf.all.rp_filter=0       # Disable reverse path filtering
    sysctl -w net.ipv4.conf.default.rp_filter=0   # same for new interfaces
    sysctl -w net.ipv4.conf.all.route_localnet=1  # Allow TPROXY to route packets via 127.0.0.1
    sysctl -w net.ipv4.conf.lo.route_localnet=1   # Allow lo local routing (TProxy)
    sysctl -w net.ipv4.ip_nonlocal_bind=1         # Allow processes to bind to any IP

    # Max tracked connections
    ct_max="$(get_connection_tracking)"
    sysctl -w net.netfilter.nf_conntrack_max="$ct_max"

    get_network_config

    # IPv6 support
    if [ -f /proc/net/if_inet6 ]; then
      if [ "$NETWORK_IPV6" = "0" ]; then
        sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sysctl -w net.ipv6.conf.default.disable_ipv6=1

        for iface_path in /sys/class/net/lo /sys/class/net/t2s* /sys/class/net/ezcfg0; do
          [ -e "$iface_path" ] || continue
          sysctl -w net.ipv6.conf."${iface_path##*/}".disable_ipv6=0
        done
      else
        sysctl -w net.ipv6.conf.all.disable_ipv6=0
        sysctl -w net.ipv6.conf.default.disable_ipv6=0

        # Forwarding
        sysctl -w net.ipv6.conf.all.forwarding=1
        sysctl -w net.ipv6.conf.default.forwarding=1
      fi
    fi

    [ "$NETWORK_TUNING" != "1" ] && return 0

    # Interface Queues
    sysctl -w net.core.netdev_max_backlog=2000 # Max packets queued on interface
    sysctl -w net.core.somaxconn=512           # Max pending TCP connections

    # Keep Alive
    sysctl -w net.ipv4.tcp_keepalive_time=60   # TCP keepalive interval
    sysctl -w net.ipv4.tcp_keepalive_probes=6  # Keepalive probes count
    sysctl -w net.ipv4.tcp_keepalive_intvl=10  # Keepalive interval between probes

    ct_max="$(get_connection_tracking "1")"

    sysctl -w net.netfilter.nf_conntrack_max="$ct_max"                # Max tracked connections
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=1800 # TCP established timeout
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=60               # UDP timeout without data
    sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=180       # UDP timeout with data
    sysctl -w net.netfilter.nf_conntrack_checksum=0                   # Disable checksum validation

    # Latency / TCP Behavior
    sysctl -w net.ipv4.tcp_fastopen=3      # Enable TCP Fast Open
    sysctl -w net.ipv4.tcp_mtu_probing=1   # Enable TCP MTU probing
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0  # keep TCP speed after idle
    sysctl -w net.ipv4.tcp_sack=1          # Enable selective ACKs
    sysctl -w net.ipv4.tcp_syncookies=1    # Enable SYN cookies (SYN flood protection)
    sysctl -w net.ipv4.tcp_tw_reuse=1      # Allow reuse of TIME_WAIT sockets
    sysctl -w net.ipv4.tcp_fin_timeout=15  # Shorten FIN timeout
    sysctl -w net.ipv4.tcp_timestamps=1    # Enable TCP timestamps for performance
    sysctl -w net.ipv4.tcp_max_syn_backlog=512 # Max SYN backlog
    sysctl -w net.ipv4.tcp_max_tw_buckets=8192 # Max TIME_WAIT sockets
    sysctl -w net.ipv4.ip_local_port_range="10000 60001" # Set ephemeral port range

    case "$(uname -m)" in
      aarch64|arm*) ;;
      *) return 0 ;;
    esac

    ## Only for ARM

    # Network Buffers
    sysctl -w net.core.rmem_max=4194304    # Max TCP/UDP receive buffer
    sysctl -w net.core.wmem_max=4194304    # Max TCP/UDP send buffer
    sysctl -w net.core.rmem_default=229376 # Default receive buffer
    sysctl -w net.core.wmem_default=229376 # Default send buffer
    sysctl -w net.ipv4.tcp_moderate_rcvbuf=1         # autotuning
    sysctl -w net.ipv4.tcp_rmem="4096 87380 4194304" # TCP per-socket read buffer min/def/max
    sysctl -w net.ipv4.tcp_wmem="4096 65536 4194304" # TCP per-socket write buffer min/def/max
    sysctl -w net.ipv4.udp_rmem_min=8192             # Min UDP receive buffer
    sysctl -w net.ipv4.udp_wmem_min=8192             # Min UDP send buffer
    sysctl -w net.ipv4.tcp_limit_output_bytes=262144 # Limit per-socket output burst
  } >/dev/null 2>&1
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
  local timeout=10
  local status_start msg

  echomsg "Starting ${SINGBOX_NAME}..."

  # shellcheck disable=SC3045
  ulimit -n "$(get_ulimit_n)" || exiterr "Failed to set ulimit -n"

  start-stop-daemon -S -b -m -p "$SINGBOX_PID_FILE" -x "$SINGBOX_BIN" \
    -c "root:${SKEEN_PROC}" -- run -D "$WORK_DIR" -c "$SINGBOX_CONFIG"
  status_start=$?

  if [ $status_start -ne 0 ]; then
    rm -f "$SINGBOX_PID_FILE"
    msg="Failed to start $SINGBOX_NAME"
    echoerr "$msg"; logger_error "$msg"
    return 1
  fi

  while ! is_running && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
  done

  if ! is_running; then
    rm -f "$SINGBOX_PID_FILE"
    msg="$SINGBOX_NAME did not start in time"
    echoerr "$msg"; logger_error "$msg"
    return 1
  fi

  [ -s "$SINGBOX_PID_FILE" ] && renice -3 -p "$(cat "$SINGBOX_PID_FILE")" >/dev/null 2>&1

  echook "$SINGBOX_NAME started"
  logger_notice "$SINGBOX_NAME started"
  return 0
}

start() {
  get_singbox_config

  if [ ! -f "$SINGBOX_BIN" ]; then
    echoerr "$SINGBOX_NAME binary not found, please install it first"
    press_any_key_to_menu "" 1
  fi

  if [ "$CALLER" = "init" ]; then
    get_auto_start_config
    if [ "$AUTO_START_ENABLED" = "0" ]; then
      return 0
    else
      if [ "$AUTO_START_DELAY" -eq "$AUTO_START_DELAY" ] 2>/dev/null; then
        sleep "$AUTO_START_DELAY"
        check_internet
      else
        sleep 5
        check_internet
      fi
    fi
  fi

  if is_running; then
    echook "Already started"
    return 0
  fi

  check_config && echo "$DELIMETER"

  create_skeen_group
  [ $? -eq 2 ] && echo "$DELIMETER"

  apply_sysctl_network_tuning

  prepare_firewall && echo "$DELIMETER"

  start_singbox || press_any_key_to_menu "" 1

  [ "$SKEEN_FIREWALL_MODE" != "none" ] && echo "$DELIMETER" && apply_firewall

  return 0
}

stop_singbox() {
  local timeout=10
  local msg

  echomsg "Stopping ${SINGBOX_NAME}..."

  if ! is_running; then
    echook "$SINGBOX_NAME already stopped"
    return 0
  fi

  if ! start-stop-daemon -K -p "$SINGBOX_PID_FILE" >/dev/null 2>&1; then
    msg="Failed to send stop signal to $SINGBOX_NAME (process not found or already terminated)"
    echoerr "$msg"; logger_error "$msg"
    rm -f "$SINGBOX_PID_FILE"
    return 1
  fi

  while is_running && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
  done

  if is_running; then
    msg="$SINGBOX_NAME did not stop in time"
    echoerr "$msg"; logger_error "$msg"
    return 1
  fi

  rm -f "$SINGBOX_PID_FILE"

  msg="$SINGBOX_NAME stopped"
  echook "$msg"; logger_notice "$msg"
  return 0
}

stop() {
  if stop_singbox && clean_firewall; then
    [ "$on_restart" = "1" ] && echo "$DELIMETER"
    return 0
  else
    return 1
  fi
}

kill_proc() {
  if ! is_running; then
    echook "$SINGBOX_NAME is not running"
    return 0
  fi

  echomsg "Killing ${SKEEN_PROC}..."
  if start-stop-daemon -K -s 9 -p "$SINGBOX_PID_FILE" >/dev/null 2>&1; then
    rm -f "$SINGBOX_PID_FILE"
    clean_firewall
    echook "$SINGBOX_NAME stopped successfully"
  else
    echoerr "Failed to force stop $SINGBOX_NAME"
    return 1
  fi
}

version() {
  local sk_version sb_version
  get_singbox_config
  sk_version="$(get_current_version "skeen")"
  sb_version="$(get_current_version "sing")"
  { [ -z "$sb_version" ] && sb_version="$(red "не найден")"; } || sb_version="$(cyan "v${sb_version}")"
  if [ "$CALLER" = "cli" ]; then
    echo "$DELIMETER"
    printf "${SKEEN_NAME}: %s\n" "$(cyan "v${sk_version}")"
    echo "$DELIMETER"

    printf "${SINGBOX_NAME}: %s\n" "$sb_version" && [ -f "$SINGBOX_BIN" ] &&
      $SINGBOX_BIN version | sed -nE '/^(Environment|Tags|Revision|CGO):/p' &&
      echo "$DELIMETER"
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
  on_restart=1
  stop || press_any_key_to_menu "" 1
  start || press_any_key_to_menu "" 1
  on_restart=0
  press_any_key_to_menu
}

reload() {
  check_config && echo "$DELIMETER"
  get_singbox_config
  stop_singbox && start_singbox || exit 1
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

  if [ -n "$pid" ]; then
    # shellcheck disable=SC2046
    set -- $(awk '$1=="VmRSS:"{r=$2} $1=="VmHWM:"{h=$2} $1=="Threads:"{t=$2} END{print r,h,t}' "/proc/$pid/status")
    mem_used="${1:-0}"
    mem_peak="${2:-0}"
    threads="${3:-0}"

    echo "Status: $(green "running")"
    echo "PID: $pid"
    echo "Uptime: $(proc_uptime "$pid")"
    echo "Memory: $((mem_used / 1024)) MB (peak: $((mem_peak / 1024)) MB)"
    echo "Threads: $threads"
    echo "File Descriptors: $(find "/proc/${pid}/fd" -type l 2>/dev/null | wc -l) (limit: $(awk '/Max open files/ {print $5}' "/proc/${pid}/limits" 2>/dev/null))"
  else
    echo "Status: $(red "stopped")"
  fi
}

update_core() {
  check_free_space
  get_os_release
  get_architecture
  download_singbox || return 1
  if is_running; then stop || exit 1; fi
  install_singbox
  echook "$SINGBOX_NAME core has been successfully updated"
}

update_skeen() {
  if download_skeen_script "update"; then
    echook "$SKEEN_NAME has been successfully updated"
    is_update_skeen=1
  else
    echoerr "Failed to update $SKEEN_NAME"
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
      start || press_any_key_to_menu "" 1
      sleep 2
    fi
  elif is_running; then stop || press_any_key_to_menu "" 1; fi
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

  echomsg "Checking $name for updates..."

  current_version=$(get_current_version "$proc")
  [ -z "$current_version" ] && current_version="not installed"

  case "$api" in *atom) beta="1" ;; esac
  latest_version=$(get_latest_version "$api" "$beta")
  [ -z "$latest_version" ] && echoerr "Failed to fetch the latest version" && return 1

  if [ "$current_version" != "$latest_version" ]; then
    printf '%s %s\n' "$(cyan "Current version ${name}:")" "$(red "$current_version")"
    printf '%s %s\n' "$(cyan "New version is available:")" "$(green "$latest_version")"
    printf '%s %s\n' "$(cyan "More details:")" "$(green "$releases")"

    while :; do
      printf 'Perform the update? [y/n] (default: n): ' >/dev/tty
      read -r opt </dev/tty
      [ -z "$opt" ] && opt=n

      case $opt in
      y | Y)
        "$update_fn" || return 1
        break
        ;;
      n | N) break ;;
      *) echoerr "Incorrect option" ;;
      esac
    done
  else
    echook "The latest $name version $latest_version is already installed"
  fi

  return 0
}

check_updates() {
  check_tty

  is_update_skeen=0

  get_update_config
  if [ "$UPDATE_SINGBOX_ENABLED" != "1" ] && [ "$UPDATE_SKEEN_ENABLED" != "1" ]; then
    echowarn "Updates are disabled in the ${SKEEN_NAME} configuration!"
    press_any_key_to_menu "" 1
  fi

  # sing-box
  if get_singbox_config && [ "$SINGBOX_EXTERNAL_ENABLED" != "1" ]; then
    if [ "$UPDATE_SINGBOX_ENABLED" = "1" ]; then
      local api_url="$SINGBOX_API_URL"
      [ "$UPDATE_SINGBOX_BETA" = "1" ] && api_url="$SINGBOX_API_URL_BETA"

      ask_and_update "$SINGBOX_NAME" "sing" "$api_url" \
        update_core "https://github.com/SagerNet/sing-box/releases"
    fi
  fi

  # skeen
  if [ "$UPDATE_SKEEN_ENABLED" = "1" ]; then
    ask_and_update "$SKEEN_NAME" "skeen" "$SKEEN_API_URL" \
      update_skeen "https://github.com/jinndi/SKeen/releases"
  fi

  [ "$CALLER" != "menu" ] && exit 0

  if [ "$is_update_skeen" -eq 1 ]; then
    exec sh "$SKEEN_SCRIPT" deps menu
  else
    press_any_key_to_menu reload
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

  local ref="PREROUTING"
  [ "$2" = "skeen_mask" ] && ref="OUTPUT"

  cyan "Test $ref $1 $2"

  content="$($3 -w -t "$1" -nvL "$2" 2>/dev/null)"

  if [ "$1" = "mangle" ] && [ "$2" = "INPUT" ]; then
    fw_test "$1" "$2" "$content" "skeen_keendns" "KeenDNS accept"
    return 0
  fi

  fw_test "$1" "$2" "$content" "[1-9][0-9]* references" "Reference"

  if [ "$2" = "$CHAIN_PREROUTING" ] && [ -n "$SKEEN_MARK_POLICY" ]; then
    fw_test "$1" "$2" "$content" "connmark match" "Connmark match"
  fi

  if [ "$2" = "$CHAIN_PREROUTING" ] && [ "$SKEEN_FIREWALL_MODE" = "tproxy" ]; then
    fw_test "$1" "$2" "$content" "$CHAIN_DIVERT" "Socket accept"
  fi

  if [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "owner" "Process owner"
  fi

  if [ "$2" = "$CHAIN_DNS" ]; then
    fw_test "$1" "$2" "$content" "skeen_dns" "DNS redirect"
    return 0
  fi

  if [ "$2" = "$CHAIN_TUN" ]; then
    fw_test "$1" "$2" "$content" "skeen_tun" "Accept"
    fw_test "nat" "POSTROUTING" "$($3 -w -t nat -S POSTROUTING 2>/dev/null)" "skeen_tun" "Masquerade"
    return 0
  fi

  fw_test "$1" "$2" "$content" "ctdir REPLY" "REPLY accept"

  if [ "$1" = "mangle" ]; then
    case "$2" in
    "$CHAIN_PREROUTING")
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
    echoerr "Testing are available only when $SKEEN_NAME is started"
    press_any_key_to_menu "" 1
  else
    if [ ! -f "$FIREWALL_HOOK_FILE" ]; then
      echoerr "The file at path $FIREWALL_HOOK_FILE is missing!"
      echomsg "Please reboot $SINGBOX_NAME"
      press_any_key_to_menu "" 1
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
    echowarn "Testing is available in tun, redirect, tproxy, and hybrid modes"
    echowarn "Also, with the specified DNS redirect parameters"
    press_any_key_to_menu "" 1
  fi

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "iptables utility is not installed"
    press_any_key_to_menu "" 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ]; then
    fw_test_chain filter "$CHAIN_TUN" "iptables"
  else
    for iptables in $SKEEN_IPTABLES_LIST; do
      [ "$iptables" = "ip6tables" ] && echo "$DELIMETER"
      yellow "Testing: $(cyan "$iptables")"
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

    echomsg "Creating a backup of the current configuration..."
    archive_path="${ENTWARE_DIR}/skeen_$(date '+%Y-%m-%d_%H%M%S').tar"
    parent_dir=$(dirname "$WORK_DIR")
    folder_name=$(basename "$WORK_DIR")
    if tar -cf "$archive_path" -C "$parent_dir" "$folder_name"; then
      echook "Backup successfully created at $archive_path"
    else
      echoerr "Error creating backup!"
      return 1
    fi
  else
    echowarn "No current configuration found, skipping backup"
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
      echomsg "Extracting archive ${archive_path}..."
      if tar --strip-components=1 -xf "$archive_path" -C "$WORK_DIR"; then
        rm -rf "$work_dir_backup"
        echook "Backup successfully restored"
      else
        rm -rf "$WORK_DIR"
        mv "$work_dir_backup" "$WORK_DIR"
        echoerr "Error extracting archive $archive_path"
        return 1
      fi
    else
      echoerr "Archive missing or 'skeen' folder not found"
      return 1
    fi

    return 0
  }

  if is_tty && [ "$CALLER" = "cli" ] && [ -z "$tarname" ]; then
    while :; do
      printf "Enter the name of the backup archive file\n"
      printf "located in the /opt root directory,\n"
      printf "for example %s: " "$(cyan "skeen.tar")" >/dev/tty
      read -r tarname </dev/tty
      [ -z "$tarname" ] && exit 1
      restore "$tarname" && break
    done
  elif [ -n "$tarname" ]; then
    restore "$tarname"
  else
    echoerr "No archive name provided"
    return 1
  fi
}

config_reset() {
  check_tty

  while :; do
    printf "A full configuration reset will be performed,\n"
    printf "with a backup of the current configuration created\n"
    printf "Continue? [y/n]: " >/dev/tty
    read -r option </dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
    y | Y)
      if backup_create; then
        rm -rf "$WORK_DIR"
        mkdir -p "$WORK_DIR"
        get_update_config
        download_singbox_config "$UPDATE_SINGBOX_BETA" "force"
        create_skeen_config "force"
        echook "Configuration reset completed"
      else
        echoerr "Failed to reset configuration!"
      fi
      break
      ;;
    n | N) break ;;
    *) echoerr "Incorrect option" ;;
    esac
  done

  press_any_key_to_menu
}

clean_cache() {
  local cache_file_enabled cache_file_path msg_not_found="Cache file not found at path"

  get_singbox_config

  if [ ! -s "$SINGBOX_CONFIG" ]; then
    echoerr "Configuration file with 'experimental.cache_file' parameter not found"
    return 0
  fi

  eval "$(
    jsonfilter -i "$SINGBOX_CONFIG" \
      -e cache_file_enabled='@.experimental.cache_file.enabled' \
      -e cache_file_path='@.experimental.cache_file.path'
  )"

  if [ "$cache_file_enabled" != "1" ]; then
    echowarn "Cache file is disabled in $SINGBOX_NAME configuration"
  fi

  if [ -z "$cache_file_path" ]; then
    cache_file_path="${WORK_DIR}/cache.db"
  else
    if ! echo "$cache_file_path" | grep -q "^/"; then
      cache_file_path="${WORK_DIR}/${cache_file}"
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
  echook "Cache cleared. Restart $SKEEN_NAME to apply changes"
}

check_skeen_config() {
  echomsg "Checking $SKEEN_NAME configuration..."
  if jsonfilter -i "$(get_skeen_config_path)" -e '@.auto_start' >/dev/null; then
    echook "$SKEEN_NAME JSON is valid"
  else
    local err_msg="$SKEEN_NAME configuration is invalid"
    echoerr "$err_msg"
    [ "$CALLER" != "menu" ] && logger_error "$err_msg"
    exit 0
  fi
}

check_singbox_config() {
  if get_singbox_config && [ -f "$SINGBOX_BIN" ]; then
    echomsg "Checking $SINGBOX_NAME configuration..."
    local config="-c $SINGBOX_CONFIG"
    [ -n "$SINGBOX_CONFIG_DIR" ] && config="-C $SINGBOX_CONFIG_DIR"
    # shellcheck disable=SC2086
    if $SINGBOX_BIN check $config; then
      echook "$SINGBOX_NAME configuration is valid"
    else
      local err_msg="$SINGBOX_NAME configuration is invalid"
      echoerr "$err_msg"
      [ "$CALLER" != "menu" ] && logger_error "$err_msg"
      press_any_key_to_menu "" "1"
    fi
  fi
}

check_config() {
  check_skeen_config
  check_singbox_config
}

format_config() {
  if get_singbox_config && [ -f "$SINGBOX_BIN" ]; then
    echomsg "Formatting ${SINGBOX_NAME} configuration..."
    local config="-c $SINGBOX_CONFIG"
    [ -n "$SINGBOX_CONFIG_DIR" ] && config="-C $SINGBOX_CONFIG_DIR"
    # shellcheck disable=SC2086
    if $SINGBOX_BIN format -w $config; then
      echook "Configuration formatted successfully"
    else
      echoerr "Configuration formatting failed"
    fi
  else
    echoerr "$SINGBOX_NAME executable is missing"
  fi
}

split_singbox_config() {
  local src_file="${1:-}"
  local target_dir="${2:-}"

  mkdir -p "$target_dir"

  local KEYS=""
  eval $(jsonfilter -i "$src_file" -e 'KEYS=@')

  local schema_val=""
  schema_val=$(jsonfilter -i "$src_file" -e "@['\$schema']")

  local schema_prefix=""
  if [ -n "$schema_val" ]; then
    schema_val=$(echo "$schema_val" | sed 's#\\/#/#g')
    schema_prefix=$(printf '  "$schema": "%s",\n' "$schema_val")
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
  local address="${1:-}"
  local config_tmp="/tmp/skeen_sync_config.tmp"

  get_singbox_config

  if [ -z "$address" ]; then
    [ -z "$SINGBOX_CONFIG_URL" ] && echoerr "Адрес для синхронизации не указан" && return 1
    address="$SINGBOX_CONFIG_URL"
  fi

  if ! echo "$address" | grep -qE '^https?://'; then
    echoerr "URL must start with http:// or https://" && return 1
  fi

  if ! run_curl -s "$address" -o "$config_tmp"; then
    echoerr "Failed to download configuration from $address" && return 1
  fi

  if ! $SINGBOX_BIN check -c "$config_tmp"; then
    echoerr "$SINGBOX_NAME configuration is invalid, sync canceled!"
    rm -f "$config_tmp"
    return 1
  fi

  if [ -n "$SINGBOX_CONFIG_DIR" ]; then
    if [ -n "$(find "$SINGBOX_CONFIG_DIR" -mindepth 1 -print -quit)" ]; then
      local parent_dir folder_name archive_path
      parent_dir=$(dirname "$SINGBOX_CONFIG_DIR")
      folder_name=$(basename "$SINGBOX_CONFIG_DIR")
      archive_path="${parent_dir}/${folder_name}_backup.tar"
      if tar -cf "$archive_path" -C "$parent_dir" "$folder_name"; then
        rm -rf "${SINGBOX_CONFIG_DIR:?}"/*
      else
        echoerr "Failed to create archive at $archive_path" && return 1
      fi
    fi
    if [ "$SINGBOX_CONFIG_SPLIT" = "1" ]; then
      split_singbox_config "$config_tmp" "$SINGBOX_CONFIG_DIR" && rm -f "$config_tmp"
    else
      mv -f "$config_tmp" "${SINGBOX_CONFIG_DIR}/config.json"
    fi
  elif [ -f "$SINGBOX_CONFIG" ] && cp -f "$SINGBOX_CONFIG" "${SINGBOX_CONFIG}.bak"; then
    mv -f "$config_tmp" "$SINGBOX_CONFIG"
  fi

  if [ ! -f "$config_tmp" ] && [ -f "$SINGBOX_CONFIG" ]; then
    echook "Configuration synced, then restart $SKEEN_NAME to apply the changes"
  else
    rm -f "$config_tmp"
    echoerr "Failed to save new config, sync canceled!"
  fi
}

show_iface() {
  check_tty

  local G='\e[32m' R='\e[31m' W='\e[1m' N='\e[0m' Y='\e[33m' B='\e[36m' M='\e[35m'
  local ip_data ln_data mt_data tf_data v6_flags

  printf "\n  ${W}%-10s %-4s %-5s %-6s %-10s %-10s${N}\n" "INTERFACE" "IPv6" "MTU" "LINK" "RX/TX (MB)" "IP ADDRESS"
  printf "  %-10s %-4s %-5s %-6s %-10s %-10s\n" "----------" "----" "-----" "------" "----------" "----------"

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
    printf "  %-10s %s %s%-5s%s %s ", ifc, v6_s, b, (mtu[ifc] ? mtu[ifc] : "-"), n, ln_s
    printf "%s%s%s/%s%s%s", b, rx, n, m, tx, n
    pad = 10 - length(tr_p)
    for (p=0; p<pad; p++) printf " "
    printf " %s%s%s\n", y, (ip4[ifc] ? ip4[ifc] : "-"), n
    if (ip6[ifc]) {
      printf "                                          %s%s%s\n", b, ip6[ifc], n
    }
  }'
}

show_menu() {
  local autostart_status running_status running_text output version ipv4 ipv6 sb_dns_work_text

  check_tty
  check_skeen_config && printf "\033[1A\033[2K\033[1A\033[2K"
  import_firewall_vars
  get_singbox_config

  if get_auto_start_config && [ "$AUTO_START_ENABLED" = "1" ]; then
    autostart_status="$(green "yes")"
  else
    autostart_status="$(red "no")"
  fi

  if is_running; then
    running_status="$(green "running")"
    running_text="Stop"
  else
    running_status="$(red "stopped")"
    running_text="Start"
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
  [ "$version" = "$(cyan "v")" ] && version="$(red "not installed")"
  add_line "${SINGBOX_NAME}" "${version}"

  add_line "State" "$running_status"
  add_line "Autostart" "$autostart_status"

  if [ "$running_text" = "Stop" ]; then
    if [ "$SKEEN_INTERCEPT_DNS_ENABLED" = "1" ] || [ "$SKEEN_REDIRECT_DNS_ENABLED" = "1" ]; then
      sb_dns_work_text="$(green yes)"
    else
      sb_dns_work_text="$(red no)"
    fi
    add_line "Sing DNS" "$sb_dns_work_text"

    if [ "$SKEEN_FIREWALL_MODE" != "none" ] && [ "$SKEEN_FIREWALL_MODE" != "tun" ]; then
      case "$SKEEN_IPTABLES_LIST" in *ipt*) ipv4="$(cyan "4")" ;; esac
      case "$SKEEN_IPTABLES_LIST" in *ip6t*) ipv6="$(cyan "6")" ;; esac

      [ -n "$SKEEN_POLICY_SEGMENT" ] && add_line "Segment" "$(cyan "$SKEEN_POLICY_SEGMENT")"
      [ "$SKEEN_TUN_ENABLED" = "1" ] && add_line "OpkgTun" "$(cyan "yes")"
      add_line "Mode" "$(cyan "$SKEEN_FIREWALL_MODE")"
      add_line "Network" "$(cyan "$SKEEN_FIREWALL_NETWORK")"
      add_line "IP ver." "$ipv4 $ipv6"
    else
      add_line "Mode" "$(cyan "$SKEEN_FIREWALL_MODE")"
    fi
  fi

  output="$output\n\n$(cyan "Select option:")"
  output="$output\n  $(green "1.") $running_text"
  output="$output\n  $(green "2.") Restart"
  output="$output\n  $(green "3.") Updates"
  output="$output\n  $(green "4.") Test"
  output="$output\n  $(green "5.") Uninstall"
  output="$output\n  $(green "0.") Exit\n"

  show_header
  echo -e "$output"

  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    printf "Choice [0-5]: " >/dev/tty
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
        echoerr "Incorrect option"
        attempt=$((attempt + 1))
        ;;
    esac
  done

  exiterr "Maximum attempts reached, exiting menu."
}

show_help() {
  cat <<EOF
Usage:
  skeen [command]

Available Commands:
  start   - Start service
  stop    - Stop service
  restart - Full restart
  reload  - Reload $SINGBOX_NAME only
  kill    - Force stop
  status  - Show status
  version - Show version
  help    - Help about any command
  iface   - Show network interface table
  update  - Check and install updates
  test    - Test firewall rules
  deps    - Check dependencies
  check   - Check configuration
  format  - Format $SINGBOX_NAME configuration
  backup  - Create archive of $WORK_DIR
  backups - List created archives in $ENTWARE_DIR
  restore - Restore $WORK_DIR from archive in $ENTWARE_DIR
  reset   - Reset $WORK_DIR to default
  clean   - Clear $SINGBOX_NAME cache file
  sync    - Synchronize $SINGBOX_NAME configuration

OpkgTun (KeeneticOS v5+):
  tun create [ipv4] [name] - Create interface with IP address and name
  tun delete [name]        - Delete interface by name
  tun list                 - List all OpkgTun interfaces
EOF
}

case "$CALLER:$ACTION" in
  netfilter:apply_firewall) apply_firewall "$3"; exit 0 ;;
  run_state:clean_firewall) rm -f "$SKEEN_RUN_SCRIPT"; clean_firewall; exit 0 ;;
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
  status) status ;;
  version) version ;;
  update) check_updates ;;
  test) test_firewall ;;
  deps)
    install_dependencies
    press_any_key_to_menu
    ;;
  check) check_config ;;
  format) format_config ;;
  backup) backup_create ;;
  backups) backup_list ;;
  restore) backup_restore "$2" ;;
  reset) config_reset ;;
  clean) clean_cache ;;
  sync) sync_config "$2" ;;
  iface) show_iface ;;
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
  "") show_menu ;;
  help | *) show_help ;;
  esac
else
  install
fi

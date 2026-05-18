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
readonly CONFIG_DIR="${WORK_DIR}/config"
readonly TMP_DIR="${ENTWARE_DIR}/tmp"
readonly NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
readonly MODULES_OS_DIR="/lib/modules"
readonly MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"

readonly SKEEN_NAME="SKeen"
readonly SKEEN_VERSION="4.16.3"
readonly SKEEN_PROC="skeen"
readonly SKEEN_SCRIPT="${ENTWARE_DIR}/bin/${SKEEN_PROC}"
readonly SKEEN_SCRIPT_URL="https://github.com/jinndi/SKeen/releases/latest/download/skeen_ru"
readonly SKEEN_API_URL="https://api.github.com/repos/jinndi/SKeen/releases/latest"
readonly SKEEN_CONFIG="${WORK_DIR}/${SKEEN_PROC}.json"
readonly SKEEN_AUTOSTART_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"

readonly SINGBOX_NAME="Sing-box"
SINGBOX_PROC="skeen-box"
SINGBOX_ARGS="run -D $WORK_DIR -C $CONFIG_DIR"
SINGBOX_BIN="${ENTWARE_DIR}/bin/${SINGBOX_PROC}"
readonly SINGBOX_API_URL="https://api.github.com/repos/SagerNet/sing-box/releases/latest"
readonly SINGBOX_SPACE_MB=128

readonly FIREWALL_HOOK_FILE="${NETFILTER_DIR}/${SKEEN_PROC}_firewall.sh"
readonly WAIT_ROUTE_FILE="/tmp/${SKEEN_PROC}_wait_route"
readonly NET_EXCLUDE_SET="skeen_exclude_net"
readonly PORT_INTERCEPT_SET="skeen_intercept_port"
readonly PORT_EXCLUDE_SET="skeen_exclude_port"
readonly CHAIN_PREROUTING="skeen"
readonly CHAIN_OUTPUT="skeen_mask"
readonly CHAIN_DIVERT="skeen_divert"
readonly CHAIN_TUN="skeen_tun"
readonly CHAIN_DNS="_NDM_HOTSPOT_DNSREDIR"
readonly CHAIN_DNS_PRE="skeen_dns_pre"
readonly CHAIN_DNS_OUT="skeen_dns_out"
readonly CHAIN_TPROXY="skeen_tproxy"
readonly CHAIN_REDIRECT="skeen_redirect"
readonly CHAIN_MARK_OUT="skeen_mark_out"
readonly TABLE_REDIRECT="nat"
readonly TABLE_TPROXY="mangle"
readonly TABLE_MARK="0x112"
readonly TABLE_ID="112"
readonly DNS_PORT=53

readonly RCI="http://127.0.0.1:79/rci"

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

check_tty() { is_tty || { echoerr "Команда только для терминала"; exit 1; }; }

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
    rm -f "$SKEEN_CONFIG"
  elif [ -f "$SKEEN_CONFIG" ]; then
    echomsg "Конфигурационный файл $SKEEN_NAME уже существует, пропускаем создание"
    return
  fi

  echomsg "Создаем конфигурационный файл $SKEEN_NAME..."

  mkdir -p "$(dirname "$SKEEN_CONFIG")"

  cat <<EOF >"$SKEEN_CONFIG"
// https://github.com/jinndi/SKeen/blob/main/README-RU.md
{
  "auto_start": {
    "enable": 1,
    "delay": 0
  },
  "policy": {
    "enable": 1,
    "name": "SKeen"
  },
  "network": {
    "ipv6": 1,
    "tuning": 0,
    "check": ["vk.com", "ya.ru", "223.5.5.5"]
  },
  "sing_binary": {
    "enable": ${SING_BINARY_ENABLE:-0},
    "path": "/opt/bin/sing-box"
  },
  "sing_config":{
    "enable": 0,
    "path": "",
    "sync_url": ""
  },
  "service_proxy": {
    "enable": 0,
    "port": "",
    "user": "",
    "pass": ""
  },
  "firewall": {
    "intercept": {
      "dns": 1,
      "port": []
    },
    "exclude": {
      "port": [123, "137:139", 445, 1900],
      "ipv4_cidr": [],
      "ipv6_cidr": []
    },
    "redirect_dns": {
      "enable": 0,
      "to_port": "",
      "use_policy": 1
    },
    "proxy_router": 0,
    "use_conntrack": 0
  }
}
EOF

  [ ! -f "$SKEEN_AUTOSTART_SCRIPT" ] && create_autostart_script >/dev/null 2>&1

  echook "Конфигурационный файл $SKEEN_NAME создан успешно"
}

json_get_array() {
  local path="${1:-}"
  local arr

  arr="$(jsonfilter -i "$SKEEN_CONFIG" -e "${path}[*]")"

  if [ -n "$arr" ]; then
    echo "$arr"
    return
  fi

  jsonfilter -i "$SKEEN_CONFIG" -e "$path" | tr -d '[],"'
}

rci() {
  curl -kfsS "${RCI}/${1:-}" 2>/dev/null
}

rci_post() {
  local payload="${2:-}"
  set -- -kfsS -X POST -H "Content-Type: application/json" "${RCI}/${1:-}"

  if [ -n "$payload" ]; then
    printf '%s' "$payload" | curl "$@" -d @- 2>/dev/null
  else
    curl "$@" -d "{}" 2>/dev/null
  fi
}

rci_delete() {
  curl -kfsS -X DELETE "${RCI}/${1:-}"
}

create_skeen_config_if_needed() {
  [ ! -f "$SKEEN_CONFIG" ] && create_skeen_config
}

get_auto_start_config() {
  create_skeen_config_if_needed

  eval "$(
    jsonfilter -i "$SKEEN_CONFIG" \
      -e AUTO_START_ENABLE='@.auto_start.enable' \
      -e AUTO_START_DELAY='@.auto_start.delay'
  )"
  : "${AUTO_START_ENABLE:=1}"
  : "${AUTO_START_DELAY:=0}"
}

get_sing_binary_config() {
  create_skeen_config_if_needed

  eval "$(
    jsonfilter -i "$SKEEN_CONFIG" \
      -e SING_BINARY_ENABLE='@.sing_binary.enable' \
      -e SING_BINARY_PATH='@.sing_binary.path'
  )"

  : "${SING_BINARY_ENABLE:=0}"
  : "${SING_BINARY_PATH:=/opt/bin/sing-box}"

  if [ "$SING_BINARY_ENABLE" = "1" ]; then
    pidof "skeen-box" 2>/dev/null && killall -9 "skeen-box" 2>/dev/null

    SINGBOX_PROC="$(basename "$SING_BINARY_PATH")"
    SINGBOX_BIN="$SING_BINARY_PATH"

    local path_bin
    path_bin="$(command -v "$SINGBOX_PROC")"
    if [ -z "$path_bin" ] && [ -f "$SINGBOX_BIN" ]; then
      PATH="$(dirname "$SINGBOX_BIN"):${PATH}"
    fi

    if [ -f "$SINGBOX_BIN" ] && [ ! -x "$SINGBOX_BIN" ]; then
      chmod +x "$SINGBOX_BIN" 2>/dev/null || true
    fi
  else
    pidof "$SING_BINARY_PATH" 2>/dev/null && killall -9 "$SING_BINARY_PATH" 2>/dev/null ||
      pidof "sing-box" 2>/dev/null && killall -9 "sing-box" 2>/dev/null
  fi
}

get_sing_args_config() {
  create_skeen_config_if_needed

  local default_config_path="/opt/etc/skeen/config.json"

  SING_CONFIG_ENABLE="$(jsonfilter -i "$SKEEN_CONFIG" -e '@.sing_config.enable')"
  : "${SING_CONFIG_ENABLE:=0}"

  SING_CONFIG_PATH="$default_config_path"
  SING_CONFIG_ARGS="-C $CONFIG_DIR"

  if [ "$SING_CONFIG_ENABLE" = "1" ]; then
    SING_CONFIG_PATH="$(jsonfilter -i "$SKEEN_CONFIG" -e '@.sing_config.path')"
    : "${SING_CONFIG_PATH:=$default_config_path}"
    SING_CONFIG_ARGS="-c $SING_CONFIG_PATH"

    SINGBOX_ARGS="run -D $WORK_DIR -c $SING_CONFIG_PATH"
  fi
}

get_service_proxy_config() {
  create_skeen_config_if_needed

  eval "$(
    jsonfilter -i "$SKEEN_CONFIG" \
      -e SERVICE_PROXY_ENABLE='@.service_proxy.enable' \
      -e SERVICE_PROXY_PORT='@.service_proxy.port' \
      -e SERVICE_PROXY_USER='@.service_proxy.user' \
      -e SERVICE_PROXY_PASS='@.service_proxy.pass'
  )"
  : "${SERVICE_PROXY_ENABLE:=0}"
  : "${SERVICE_PROXY_PORT:=}"
  : "${SERVICE_PROXY_USER:=}"
  : "${SERVICE_PROXY_PASS:=}"
}

get_network_config() {
  create_skeen_config_if_needed

  eval "$(
    jsonfilter -i "$SKEEN_CONFIG" \
      -e NETWORK_IPV6='@.network.ipv6' \
      -e NETWORK_TUNING='@.network.tuning'
  )"

  : "${NETWORK_IPV6:=1}"
  : "${NETWORK_TUNING:=0}"
}

get_firewall_config() {
  create_skeen_config_if_needed

  eval "$(
    jsonfilter -i "$SKEEN_CONFIG" \
      -e POLICY_ENABLE='@.policy.enable' \
      -e POLICY_NAME='@.policy.name' \
      -e NETWORK_IPV6='@.network.ipv6' \
      -e NETWORK_TUNING='@.network.tuning' \
      -e FIREWALL_INTERCEPT_DNS='@.firewall.intercept.dns' \
      -e FIREWALL_REDIRECT_DNS_ENABLE='@.firewall.redirect_dns.enable' \
      -e FIREWALL_REDIRECT_DNS_PORT='@.firewall.redirect_dns.to_port' \
      -e FIREWALL_REDIRECT_DNS_USE_POLICY='@.firewall.redirect_dns.use_policy' \
      -e FIREWALL_PROXY_ROUTER='@.firewall.proxy_router' \
      -e FIREWALL_USE_CONNTRACK='@.firewall.use_conntrack'
  )"

  : "${POLICY_ENABLE:=1}"
  : "${POLICY_NAME:=SKeen}"
  : "${NETWORK_IPV6:=1}"
  : "${NETWORK_TUNING:=0}"
  : "${FIREWALL_INTERCEPT_DNS:=1}"
  : "${FIREWALL_REDIRECT_DNS_ENABLE:=0}"
  : "${FIREWALL_REDIRECT_DNS_PORT:=}"
  : "${FIREWALL_REDIRECT_DNS_USE_POLICY:=1}"
  : "${FIREWALL_PROXY_ROUTER:=0}"
  : "${FIREWALL_USE_CONNTRACK:=0}"
}

get_curl_proxy_options() {
  local err_template

  get_service_proxy_config

  CURL_PROXY_OPTIONS="--connect-timeout 5 --max-time 720"
  if [ "$SERVICE_PROXY_ENABLE" = "1" ]; then
    err_template="Прокси-сервис включен, но"
    if [ -z "$SERVICE_PROXY_PORT" ]; then
      exiterr "$err_template 'service_proxy.port' не задан"
    elif get_sing_binary_config && ! is_running; then
      exiterr "$err_template $SINGBOX_NAME не запущен"
    elif ! netstat -tuln 2>/dev/null | grep -q ":${SERVICE_PROXY_PORT}"; then
      exiterr "$err_template процесс не слушает на порту ${SERVICE_PROXY_PORT}"
    else
      CURL_PROXY_OPTIONS="${CURL_PROXY_OPTIONS} --socks5-hostname 127.0.0.1:${SERVICE_PROXY_PORT}"
      if [ -n "$SERVICE_PROXY_USER" ] && [ -n "$SERVICE_PROXY_PASS" ]; then
        CURL_PROXY_OPTIONS="${CURL_PROXY_OPTIONS} --proxy-user ${SERVICE_PROXY_USER}:${SERVICE_PROXY_PASS}"
      fi
    fi
  fi
}

get_current_version() {
  local proc="${1:-}"

  case "$proc" in
  "sing")
    if [ -f "$SINGBOX_BIN" ]; then
      $SINGBOX_BIN version | awk 'NR==1 {print $3}' | xargs
    fi
    ;;
  "skeen") echo "$SKEEN_VERSION" ;;
  esac
}

get_latest_version() {
  local api_url="${1:-}"
  local latest_release

  # shellcheck disable=SC2086
  latest_release="$(curl $CURL_PROXY_OPTIONS -s "$api_url")"
  # shellcheck disable=SC2181
  [ $? -ne 0 ] && return 1

  echo "$latest_release" | grep tag_name | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
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
    exiterr "Не удалось определить свободное место на $path"
  elif [ "$free_mb" -lt "$required_mb" ]; then
    exiterr "Недостаточно свободного места на $path: требуется ${required_mb}MB, доступно ${free_mb}MB"
  fi
}

get_os_release() {
  local release_path

  release_path="$(command -v opkg)"

  if [ "$release_path" != "/opt/bin/opkg" ]; then
    exiterr "Неподдерживаемая система!"
  else
    PKG_OS="openwrt"
    PKG_SUFFIX=".ipk"
  fi
}

ask_install_singbox() {
  while :; do
    printf "Вы можете отказаться от установки %s из официального репозитория\n" "$SINGBOX_NAME"
    printf "и вместо этого настроить использование собственного экземпляра программы.\n"
    printf "Пропустить установку %s? [y/n]: " "$SINGBOX_NAME" >/dev/tty
    read -r opt </dev/tty

    opt=${opt:-n}

    case $opt in
    y | Y) SING_BINARY_ENABLE=1; break ;;
    n | N) SING_BINARY_ENABLE=0; break ;;
    *) echoerr "Пожалуйста, введите y (да) или n (нет)." ;;
    esac
  done
}

arch_elf() {
  local bin
  local base="mips"
  local B5
  local B6

  bin="/opt/bin/opkg"
  B5=$(printf "%d" "'$(dd if="$bin" bs=1 skip=4 count=1 2>/dev/null | head -c1)'")
  B6=$(printf "%d" "'$(dd if="$bin" bs=1 skip=5 count=1 2>/dev/null | head -c1)'")

  [ -z "$B5" ] && echo "" && return
  [ -z "$B6" ] && echo "" && return

  case "$B5" in 2) base="${base}64" ;; esac
  case "$B6" in 1) base="${base}el" ;; esac

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

  [ -z "$ARCH" ] && exiterr "Неподдерживаемая архитектура CPU"

  cpu_info=$(tr '[:upper:]' '[:lower:]' </proc/cpuinfo)

  case "$ARCH" in
  aarch64)
    case "$(echo "$cpu_info" | grep -m1 'cpu part')" in
    *0xd03*) PKG_ARCH="${ARCH}_cortex-a53" ;;
    *0xd08*) PKG_ARCH="${ARCH}_cortex-a72" ;;
    *0xd0b*) PKG_ARCH="${ARCH}_cortex-a76" ;;
    *) PKG_ARCH="${ARCH}_generic" ;; # fallback
    esac
    ;;
  mipsel)
    case "$cpu_info" in
    *74k*) PKG_ARCH="${ARCH}_74kc" ;;
    *24kf*) PKG_ARCH="${ARCH}_24kc_24kf" ;;
    *24k*) PKG_ARCH="${ARCH}_24kc" ;;
    *) PKG_ARCH="${ARCH}_mips32" ;; # fallback 1004, 34k, ...
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

  echomsg "Обнаружена архитектура CPU: $(green "$PKG_ARCH")"
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
  echomsg "Проверка зависимостей"

  opkg update >/dev/null 2>&1
  local pkg_list
  pkg_list="$(opkg list 2>/dev/null | awk '{print $1}')"

  for pkg_name in $DEPENDENCIES; do
    printf "[%s] " "$pkg_name" >&2

    if command -v "$pkg_name" >/dev/null 2>&1; then
      echook "Уже установлено"
      continue
    fi

    case "$pkg_list" in
    *"$pkg_name"*)
      if opkg install "$pkg_name" >/dev/null 2>&1; then
        echook "Установлено"
      else
        exiterr "Ошибка установки"
      fi
      ;;
    *) exiterr "Пакет не найден в opkg" ;;
    esac
  done

  echook "Все зависимости установлены"
}

download_singbox() {
  local version="${1:-$latest_version}"
  local pkg_url

  if [ -z "$version" ] && [ -z "$MIRROR" ]; then
    echomsg "Получение последней версии..."
    version="$(get_latest_version "$SINGBOX_API_URL")"
    [ -z "$version" ] && echoerr "Не удалось получить версию" && exit 1

    echook "Последняя версия: $version"
  fi

  if [ -z "$MIRROR" ]; then
    PKG_NAME="sing-box_${version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
    pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${version}/${PKG_NAME}"
  else
    PKG_NAME="sing-box_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
    pkg_url="${MIRROR}sing-box/${PKG_NAME}"
  fi

  echomsg "Загрузка ${PKG_NAME}..."

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR" || exit 1

  # shellcheck disable=SC2086
  if curl $CURL_PROXY_OPTIONS --fail -Lo "$PKG_NAME" "$pkg_url"; then
    echook "$PKG_NAME загружен успешно"
  else
    echoerr "Не удалось загрузить $PKG_NAME"
    [ -n "$latest_version" ] && return 1 || exit 1
  fi
}

install_singbox() {
  local tmp_unpack_dir="${TMP_DIR}/sing-box-unpack"

  [ -d "$tmp_unpack_dir" ] && rm -rf "$tmp_unpack_dir"

  echomsg "Распаковка $PKG_NAME"
  mkdir -p "$tmp_unpack_dir"
  cd "$tmp_unpack_dir" || exit 1

  if tar -xzf "../${PKG_NAME}" && tar -xzf data.tar.gz; then
    echook "Распаковка завершена"
  else
    rm -rf "$tmp_unpack_dir"
    rm -f "${TMP_DIR}/${PKG_NAME}"
    exiterr "Ошибка распаковки $PKG_NAME"
  fi

  echomsg "Установка $SINGBOX_NAME в $SINGBOX_BIN"
  [ -f "$SINGBOX_BIN" ] && rm -f "$SINGBOX_BIN"
  mv ./usr/bin/sing-box "$SINGBOX_BIN"
  chmod 755 "$SINGBOX_BIN"
  chmod +x "$SINGBOX_BIN"

  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${PKG_NAME}"

  echook "$SINGBOX_NAME успешно установлен"
}

create_singbox_config() {
  local act="${1:-}"
  local key
  local value

  if [ "$act" != "force" ] && [ -d "$CONFIG_DIR" ] &&
    ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
    echomsg "Найдена папка с конфигами ${CONFIG_DIR}, пропускаем создание"
    return
  elif [ ! -d "$CONFIG_DIR" ] && [ -f "$SKEEN_CONFIG" ]; then
    get_sing_args_config
    if [ "$SING_CONFIG_ENABLE" = "1" ] && [ ! -f "$SING_CONFIG_PATH" ]; then
      echowarn "Конфиги $SINGBOX_NAME не найдены"
    else
      echomsg "Конфиг $SINGBOX_NAME найден, пропускаем создание"
      return
    fi
  fi

  echomsg "Создание конфигурационных файлов $SINGBOX_NAME..."

  mkdir -p "$CONFIG_DIR"

  config_json='{"log":{"disabled":false,"level":"debug","output":"","timestamp":false},"dns":{"servers":[{"type":"tls","tag":"dns-proxy","detour":"proxy","domain_resolver":"dns-resolver","server":"one.one.one.one"},{"type":"https","tag":"dns-direct","domain_resolver":"dns-resolver","server":"common.dot.dns.yandex.net"},{"type":"udp","tag":"dns-resolver","server":"77.88.8.8"}],"rules":[{"rule_set":"adguard","action":"reject"},{"clash_mode":"Direct","server":"dns-direct"},{"clash_mode":"Global","server":"dns-proxy"},{"rule_set":"geosite-category-ru","server":"dns-direct"}],"final":"dns-proxy","strategy":"ipv4_only"},"inbounds":[{"type":"tproxy","tag":"tproxy-in","listen":"::","listen_port":65082,"tcp_fast_open":true,"udp_fragment":true,"udp_timeout":"1m0s"}],"outbounds":[{"tag":"proxy","type":"selector","default":"auto","interrupt_exist_connections":true,"outbounds":["direct","auto","vless-out"]},{"tag":"direct","type":"direct"},{"tag":"auto","type":"urltest","url":"http://www.gstatic.com/generate_204","interval":"5m","tolerance":100,"interrupt_exist_connections":true,"outbounds":["vless-out"]},{"tag":"vless-out","type":"vless","uuid":"00000000-0000-0000-0000-00000000000","flow":"xtls-rprx-vision","packet_encoding":"xudp","server":"example.com","server_port":443,"tls":{"enabled":true,"server_name":"example.com","utls":{"enabled":true,"fingerprint":"qq"}}}],"route":{"final":"proxy","auto_detect_interface":true,"default_domain_resolver":"dns-resolver","rules":[{"action":"sniff"},{"type":"logical","mode":"or","rules":[{"protocol":"dns"},{"port":53}],"action":"hijack-dns"},{"ip_is_private":true,"outbound":"direct"},{"clash_mode":"Direct","outbound":"direct"},{"clash_mode":"Global","outbound":"proxy"},{"protocol":"bittorrent","outbound":"direct"},{"rule_set":["geosite-category-ru","geoip-ru"],"outbound":"direct"}],"rule_set":[{"type":"remote","tag":"adguard","url":"https://github.com/jinndi/adguard-filter-list-srs/releases/latest/download/adguard-filter-list.srs","download_detour":"direct"},{"tag":"geoip-ru","type":"remote","url":"https://github.com/KaringX/karing-ruleset/raw/sing/geo/geoip/ru.srs","download_detour":"direct"},{"tag":"geosite-category-ru","type":"remote","url":"https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ru.srs","download_detour":"direct"}]},"experimental":{"clash_api":{"external_controller":"0.0.0.0:9999","external_ui":"zashboard","external_ui_download_url":"https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip","external_ui_download_detour":"direct","default_mode":"rule"},"cache_file":{"enabled":true,"path":"cache.db","store_fakeip":true,"store_rdrc":true}}}'

  for key in log dns inbounds outbounds route experimental; do
    value="$(printf '%s\n' "$config_json" | jsonfilter -e "@.$key")"

    if [ -z "$value" ] || [ "$value" = "null" ]; then
      case "$key" in
      services | endpoints | inbounds | outbounds) value="[]" ;;
      *) value="{}" ;;
      esac
    fi

    echo "{\"$key\": $value}" >"${CONFIG_DIR}/${key}.json"
  done

  $SINGBOX_PROC format -w -C $CONFIG_DIR

  echook "Конфигурационные файлы $SINGBOX_NAME созданы успешно"
}

create_autostart_script() {
  echomsg "Создание скрипта автозапуска $SKEEN_NAME..."

  [ -f "$SKEEN_AUTOSTART_SCRIPT" ] && rm -f "$SKEEN_AUTOSTART_SCRIPT"

  mkdir -p "$(dirname "$SKEEN_AUTOSTART_SCRIPT")"

  {
    echo "#!/bin/sh"
    echo "PATH=$PATH"
    echo "$SKEEN_PROC start init"
  } >"$SKEEN_AUTOSTART_SCRIPT"

  chmod 755 "$SKEEN_AUTOSTART_SCRIPT"
  chmod +x "$SKEEN_AUTOSTART_SCRIPT"

  echook "Скрипт автозапуска создан успешно"
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

  exiterr "Нет свободного GID"
}

create_skeen_group() {
  local name="$SKEEN_PROC"
  local group_file="${ENTWARE_DIR}/etc/group"
  local gid_num

  if ! grep -q "^${name}:" "$group_file" 2>/dev/null; then
    gid_num=$(get_free_gid "$group_file" 1000)

    echomsg "Создание группы $name с GID ${gid_num}..."
    addgroup -g "$gid_num" "$name" >/dev/null 2>&1 ||
      exiterr "Не удалось создать группу $name"
    echook "Группа $name создана успешно"
    return 2
  else
    return 0
  fi
}

download_skeen_script() {
  local action="${1:-}"
  local backup_script="${SKEEN_SCRIPT}.backup"

  echomsg "Загрузка скрипта $SKEEN_NAME..."

  [ -f "$SKEEN_SCRIPT" ] && mv "$SKEEN_SCRIPT" "$backup_script"

  if [ -n "$MIRROR" ]; then
    SKEEN_SCRIPT_URL="${MIRROR}skeen_ru"
  fi

  # shellcheck disable=SC2086
  if ! curl $CURL_PROXY_OPTIONS --fail -Lo "$SKEEN_SCRIPT" "$SKEEN_SCRIPT_URL"; then
    rm -f "$SKEEN_SCRIPT"
    [ -f "$backup_script" ] && mv "$backup_script" "$SKEEN_SCRIPT"
    echoerr "Не удалось загрузить скрипт $SKEEN_NAME"
    [ "$action" != "update" ] && exit 1
    return 1
  fi

  chmod 755 "$SKEEN_SCRIPT"
  chmod +x "$SKEEN_SCRIPT"

  [ -f "$backup_script" ] && rm -f "$backup_script"

  echook "Скрипт $SKEEN_NAME загружен успешно"
  return 0
}

press_any_key_to_menu() {
  local action="${1:-}"
  local exit_code="${2:-0}"

  [ "$CALLER" != "menu" ] && exit "$exit_code"

  echo "$DELIMETER"

  printf "Нажмите любую клавишу для открытия меню..." >/dev/tty
  wait_input

  if [ "$action" = "reload" ]; then
    exec sh "$SKEEN_SCRIPT"
  else
    show_menu
  fi
}

is_running() {
  pidof "$SINGBOX_PROC" >/dev/null 2>&1
}

install() {
  MIRROR="${MIRROR:-}"

  if [ -n "$MIRROR" ]; then
    case "$MIRROR" in
    https://*static/ | http://*static/) echomsg "Используем зеркало: $MIRROR"; ;;
    *) exiterr "URL зеркала должен начинаться с http(s):// и заканчиваться на static/"; ;;
    esac
  fi

  get_os_release
  ask_install_singbox
  if [ "$SING_BINARY_ENABLE" != "1" ]; then
    check_free_space
    get_architecture
    download_singbox
    install_singbox
  fi
  install_dependencies
  create_singbox_config
  create_autostart_script
  create_skeen_group
  download_skeen_script
  create_skeen_config

  if [ "$SING_BINARY_ENABLE" != "1" ]; then
    "$SINGBOX_BIN" version
  elif [ ! -f /opt/bin/sing-box ]; then
    echomsg "Укажите путь к бинарному файлу $SINGBOX_NAME в $SKEEN_CONFIG"
  fi

  if [ "$SING_CONFIG_ENABLE" != "1" ] && [ -d "$CONFIG_DIR" ]; then
    echomsg "Настройте $SINGBOX_NAME: отредактировав $CONFIG_DIR"
  fi

  echomsg "Настройте $SKEEN_NAME: отредактировав $SKEEN_CONFIG"

  echook "Установка завершена"

  MIRROR=""

  press_any_key_to_menu
}

uninstall() {
  echomsg "Удаление ${SKEEN_NAME}..."

  get_sing_binary_config

  is_running && stop

  if [ "$SINGBOX_PROC" = 'skeen-box' ]; then
    echomsg "Удаление файла $SINGBOX_NAME..."
    rm -f "$SINGBOX_BIN"
  fi

  echomsg "Удаление скрипта автозапуска..."
  rm -f "$SKEEN_AUTOSTART_SCRIPT"

  echomsg "Удаление скрипта файрвола..."
  rm -f "$FIREWALL_HOOK_FILE"

  echomsg "Удаление скрипта ${SKEEN_NAME}..."
  rm -f "$SKEEN_SCRIPT"

  echomsg "Удаление группы ${SKEEN_PROC}..."
  delgroup "$SKEEN_PROC"

  if [ -d "$WORK_DIR" ]; then
    echomsg "Каталог конфигурации $WORK_DIR незатронут"
    echomsg "Для удаления вручную выполните: rm -rf $WORK_DIR"
  fi
  echook "${SKEEN_NAME} успешно удалён"
  exit 0
}

accept_uninstall() {
  local max_attempts=3
  local attempt=0
  local option

  while [ $attempt -lt $max_attempts ]; do
    printf "Удалить, %s? [y/n]: " "$SKEEN_NAME" >/dev/tty
    read -r option </dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
    y | Y) uninstall ;;
    n | N) break ;;
    *)
      echoerr "Некорректный вариант"
      attempt=$((attempt + 1))
      ;;
    esac
  done

  show_menu
}

get_net_check_hosts() {
  local ipv="${1:-}"
  local hosts=""
  local sys_hosts=""
  local max="3"
  local count
  local result

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
  local hosts
  local max_attempts=3
  local host
  local attempt

  hosts="$(get_net_check_hosts "4")"
  max_attempts=3

  for host in $hosts; do
    attempt=1
    while [ $attempt -le $max_attempts ]; do
      if ping -c 1 "$host" >/dev/null 2>&1; then
        logger_notice "Интернет доступен через ${host}"
        return 0
      else
        logger_warning "Интернет недоступен (${host}), попытка ${attempt}/${max_attempts}..."
      fi
      attempt=$((attempt + 1))
      sleep 10
    done
  done

  logger_error "Интернет недоступен ни через один из проверенных хостов"
}

get_fw_mode_param() {
  local file="${1:-}"
  local type="${2:-}"
  local has_opkgtun
  local port
  local network

  if [ "$type" = "tun" ]; then
    has_opkgtun=$(jsonfilter -i "$file" \
      -e '@.inbounds[@.type="'"$type"'"].interface_name' | grep ^opkgtun)

    [ -z "$has_opkgtun" ] && return 0

    echo "tun"

    return 0
  fi

  port=$(jsonfilter -i "$file" \
    -e '@.inbounds[@.type="'"$type"'"].listen_port' |
    head -n1 2>/dev/null)

  [ -z "$port" ] && return 0

  if [ "$type" = "redirect" ]; then
    echo "${port}|tcp"
    return 0
  fi

  network=$(jsonfilter -i "$file" \
    -e '@.inbounds[@.type="'"$type"'"].network' |
    head -n1 2>/dev/null)

  if [ -n "$network" ]; then
    echo "${port}|${network}"
  else
    echo "${port}|tcpudp"
  fi

  return 0
}

get_fw_mode_data() {
  local type="$1"
  local file
  local param

  if [ "$SING_CONFIG_ENABLE" = "1" ]; then
    get_fw_mode_param "$SING_CONFIG_PATH" "$type"
    return 0
  fi

  [ -d "$CONFIG_DIR" ] || return 0
  for file in "$CONFIG_DIR"/*.json; do
    [ -f "$file" ] || continue
    param="$(get_fw_mode_param "$file" "$type")"
    [ -n "$param" ] && echo "$param" && return 0
  done

  return 0
}

has_dns_servers() {
  if [ "$SING_CONFIG_ENABLE" = "1" ]; then
    if jsonfilter -i "$SING_CONFIG_PATH" -e '@.dns.servers[0]' >/dev/null 2>&1; then
      return 0
    fi
  elif [ -d "$CONFIG_DIR" ]; then
    for file in "$CONFIG_DIR"/*.json; do
      [ -f "$file" ] || continue
      if jsonfilter -i "$file" -e '@.dns.servers[0]' >/dev/null 2>&1; then
        return 0
      fi
    done
  fi

  return 1
}

check_port() {
  local port="${1:-}"
  local msg_err

  if [ -n "$port" ]; then
    if netstat -lnt 2>/dev/null | grep -q ":$port\s"; then
      msg_err="Порт $port занят. Освободите его и попробуйте снова"
      echoerr "$msg_err"
      logger_error "$msg_err"
      press_any_key_to_menu "" 1
    fi
  fi

  return 0
}

is_owner_module_working() {
  [ -d "/sys/module/xt_owner" ] && return 0

  if iptables -m owner --help 2>&1 | grep -q "owner match options"; then
    return 0
  fi

  if iptables -w -t mangle -I OUTPUT 1 -m owner --gid-owner 65534 -j RETURN >/dev/null 2>&1; then
    iptables -w -t mangle -D OUTPUT 1 >/dev/null 2>&1
    return 0
  fi

  return 1
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
  fi

  echoerr "Модуль '$module' не найден или ошибка в загрузке"
  return 1
}

loading_modules() {
  local modules="${1:-xt_TPROXY.ko xt_socket.ko xt_owner.ko xt_comment.ko ip_set_bitmap_port.ko}"
  local err_msg="Установите компонент роутера: «Модули ядра подсистемы Netfilter»"

  KERNEL_OS_V="$(uname -r)"

  for module in $modules; do
    if [ "$module" = "xt_owner.ko" ] && is_owner_module_working; then
      continue
    fi

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
      echowarn "IPv6 активен в конфиге ${SKEEN_NAME}, но внешнее IPv6 соединение отсутствует" >&2
    fi
  fi

  echo "$ipt_list"
}

get_mark_policy() {
  local mark=""
  local json_policy
  local policy_name_lower
  local descriptions
  local marks_list
  local description
  local desc_lower
  local mark_val

  if [ "$POLICY_ENABLE" = "1" ] && [ -n "$POLICY_NAME" ]; then
    json_policy="$(rci_post show/ip/policy)"

    descriptions="$(printf '%s' "$json_policy" | jsonfilter -e '$.policy.*.description')"
    marks_list="$(printf '%s' "$json_policy" | jsonfilter -e '$.policy.*.mark')"

    [ -n "$descriptions" ] && [ -n "$marks_list" ] || return

    policy_name_lower=$(printf '%s' "$POLICY_NAME" | tr '[:upper:]' '[:lower:]')

    while IFS= read -r description && IFS= read -r mark_val <&3; do
      desc_lower=$(printf '%s' "$description" | tr '[:upper:]' '[:lower:]')

      if [ "$desc_lower" = "$policy_name_lower" ]; then
        mark="$mark_val"
        break
      fi
    done 3<<EOF2 <<EOF
$marks_list
EOF2
$descriptions
EOF
  fi

  [ -n "$mark" ] && echo "0x$mark"
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

    local msg="Проверьте подключение к интернету"
    [ -n "$SKEEN_MARK_POLICY" ] && msg="$msg для политики ${SKEEN_POLICY_NAME:-unknown}"

    echoerr "$msg"
    logger_warning "$msg"

    [ "$CALLER" = "netfilter" ] && exit 0

    press_any_key_to_menu "" 1; return 1
  fi

  case "$SKEEN_FIREWALL_MODE" in
    redirect|tun|dns|none) return 0 ;;
  esac

  ip -"$IP_VERSION" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1 || true
  ip -"$IP_VERSION" route flush table "$TABLE_ID" >/dev/null 2>&1 || true

  ip -"$IP_VERSION" rule add fwmark "$TABLE_MARK" lookup "$TABLE_ID"
  ip -"$IP_VERSION" route add local default dev lo table "$TABLE_ID"
}

is_valid_ipv4() {
  local addr="${1:-}"
  local ip
  local cidr
  local o1 o2 o3 o4
  local o

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
  local ip_only
  local cidr

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
  local valid_ports=""
  local invalid_ports=""
  local start end p

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
    local msg="Неверные $label порт(ы): $invalid_ports"
    logger_warning "$msg"
    is_tty && echowarn "$msg" >&2
  fi

  printf '%s' "$valid_ports"
}

get_all_wan_ips() {
  local version="$1"
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
  local reserved_subnets
  local user_exclude
  local prefix_length_default
  local all_list
  local line
  local subnet
  local invalid_list
  local addr
  local validator

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
    is_tty && echowarn "Неверные IPv${ip_v} исключения: $invalid_list"
    logger_warning "Неверные IPv${ip_v} исключения: $invalid_list"
  }

  echo "$all_list" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

add_rule() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  shift 3
  # shellcheck disable=SC2068
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

add_skeen_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local type="${4:-}"
  local protocols="${5:-}"
  local connmark_match_opt=""

  add_conntrack_mark() {
    [ "$SKEEN_USE_CONNMARK" != "1" ] && return
    connmark_match_opt="-m connmark --mark $TABLE_MARK"

    local proto="${1:-}"
    local chain="${2:-$chain}"

    if [ "$proto" = "tcp" ]; then
      add_rule "$iptables" "$table" "$chain" \
        -p "$proto" -m conntrack --ctstate NEW,RELATED -j CONNMARK --set-mark "$TABLE_MARK"
    else
      add_rule "$iptables" "$table" "$chain" \
        -p "$proto" -m connmark ! --mark "$TABLE_MARK" -j CONNMARK --set-mark "$TABLE_MARK"
    fi
  }

  case "$type" in
  "exclude_connmark")
    local connmark_options=""

    if [ -n "$SKEEN_MARK_POLICY" ]; then
      connmark_options="-m connmark ! --mark $SKEEN_MARK_POLICY"

      [ "$SKEEN_PROXY_ROUTER" = "1" ] &&
        connmark_options="$connmark_options -m connmark ! --mark $TABLE_MARK"
    fi

    # shellcheck disable=SC2086
    [ -n "$connmark_options" ] &&
      add_rule "$iptables" "$table" "$chain" $connmark_options -j ACCEPT
    ;;
  "socket")
    if echo "$protocols" | grep -q "tcp"; then
      ! safe_chain_create "$iptables" "$table" "$CHAIN_DIVERT" && return
      add_rule "$iptables" "$table" "$CHAIN_DIVERT" -j MARK --set-mark "$TABLE_MARK"
      add_rule "$iptables" "$table" "$CHAIN_DIVERT" -j ACCEPT
      add_rule "$iptables" "$table" "$chain" -p tcp -m socket --transparent -g "$CHAIN_DIVERT"
    fi
    ;;
  "ctdir_reply")
    [ "$SKEEN_USE_CONNMARK" != "1" ] && return
    add_rule "$iptables" "$table" "$chain" -m conntrack --ctdir REPLY -j ACCEPT
    ;;
  "intercept_dns")
    if [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ] && [ "$SKEEN_USE_CONNMARK" = "1" ]; then
      ! safe_chain_create "$iptables" "$table" "$CHAIN_DNS_PRE" && return
      for proto in $protocols; do
        add_conntrack_mark "$proto" "$CHAIN_DNS_PRE"
        add_rule "$iptables" "$table" "$chain" -p "$proto" --dport "$DNS_PORT" -g "$CHAIN_DNS_PRE"
      done
      chain="$CHAIN_DNS_PRE"
    fi

    for proto in $protocols; do
      if [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ]; then
        # shellcheck disable=SC2086
        add_rule "$iptables" "$table" "$chain" \
          -p "$proto" $connmark_match_opt --dport "$DNS_PORT" -j TPROXY --on-ip "$PROXY_IP" \
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
    elif [ "$SKEEN_INTERCEPT_PORT" = "1" ]; then
      for proto in $protocols; do
        add_rule "$iptables" "$table" "$chain" \
          -p "$proto" -m set ! --match-set "$PORT_INTERCEPT_SET" dst -j ACCEPT
      done
    fi

    add_rule "$iptables" "$table" "$chain" \
      -m set --match-set "${NET_EXCLUDE_SET}${IP_VERSION}" dst -j ACCEPT
    ;;
  "tproxy")
    if [ "$SKEEN_USE_CONNMARK" = "1" ]; then
      ! safe_chain_create "$iptables" "$table" "$CHAIN_TPROXY" && return
      for proto in $protocols; do
        add_conntrack_mark "$proto" "$CHAIN_TPROXY"
        add_rule "$iptables" "$table" "$chain" -p "$proto" -g "$CHAIN_TPROXY"
      done
      chain="$CHAIN_TPROXY"
    fi

    for proto in $protocols; do
      # shellcheck disable=SC2086
      add_rule "$iptables" "$table" "$chain" \
        -p "$proto" $connmark_match_opt -j TPROXY --on-ip "$PROXY_IP" \
        --on-port "$SKEEN_TPROXY_PORT" --tproxy-mark "$TABLE_MARK"
    done
    ;;
  "keendns_accept")
    local k_port
    k_port="$(rci ip/http | jsonfilter -e '@.ssl.port' 2>/dev/null)"
    [ -z "$k_port" ] && return 0

    local rule="-m mark --mark $TABLE_MARK -j ACCEPT -m comment --comment skeen_keendns"

    for proto in $protocols; do
      # shellcheck disable=SC2086
      if ! $iptables -t "$table" -C "$chain" -p "$proto" --dport "$k_port" $rule >/dev/null 2>&1; then
        $iptables -w -t "$table" -I "$chain" -p "$proto" --dport "$k_port" $rule
      fi
    done
  ;;
  "redirect")
    if [ "$SKEEN_USE_CONNMARK" = "1" ]; then
      if ! safe_chain_create "$iptables" "$table" "$CHAIN_REDIRECT"; then
        if [ "$chain" = "$CHAIN_OUTPUT" ]; then
          add_rule "$iptables" "$table" "$chain" -p "$protocols" -g "$CHAIN_REDIRECT"
        fi
        return
      fi
      add_conntrack_mark "$protocols" "$CHAIN_REDIRECT"
      add_rule "$iptables" "$table" "$chain" -p "$protocols" -g "$CHAIN_REDIRECT"
      chain="$CHAIN_REDIRECT"
    fi
    # shellcheck disable=SC2086
    add_rule "$iptables" "$table" "$chain" \
      -p "$protocols" $connmark_match_opt -j REDIRECT --to-port "$SKEEN_REDIRECT_PORT"
    ;;
  "proxy_router_owner")
    add_rule "$iptables" "$table" "$chain" -m owner --gid-owner "$SKEEN_PROC" -j ACCEPT
    ;;
  "proxy_router_dns")
    if [ "$SKEEN_REDIRECT_DNS_ENABLE" != "1" ]; then
      ! safe_chain_create "$iptables" "$table" "$CHAIN_DNS_OUT" && return
      if [ "$SKEEN_USE_CONNMARK" = "1" ]; then
        for proto in $protocols; do
          add_conntrack_mark "$proto" "$CHAIN_DNS_OUT"
        done
      fi
      for proto in $protocols; do
        add_rule "$iptables" "$table" "$chain" -p "$proto" --dport "$DNS_PORT" -g "$CHAIN_DNS_OUT"
      done
      chain="$CHAIN_DNS_OUT"
      # shellcheck disable=SC2086
      add_rule "$iptables" "$table" "$chain" $connmark_match_opt -j MARK --set-mark "$TABLE_MARK"
    fi

    for proto in $protocols; do
      add_rule "$iptables" "$table" "$chain" -p "$proto" --dport "$DNS_PORT" -j ACCEPT
    done
    ;;
  "proxy_router_mark")
    ! safe_chain_create "$iptables" "$table" "$CHAIN_MARK_OUT" && return
    if [ "$SKEEN_USE_CONNMARK" = "1" ]; then
      for proto in $protocols; do
        add_conntrack_mark "$proto" "$CHAIN_MARK_OUT"
      done
    fi
    for proto in $protocols; do
      add_rule "$iptables" "$table" "$chain" -p "$proto" -g "$CHAIN_MARK_OUT"
    done
    chain="$CHAIN_MARK_OUT"
    # shellcheck disable=SC2086
    add_rule "$iptables" "$table" "$chain" $connmark_match_opt -j MARK --set-mark "$TABLE_MARK"
    # shellcheck disable=SC2086
    add_rule "$iptables" "$table" "$chain" -j ACCEPT
    ;;
  esac
}

chain_exists() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"

  $iptables -t "$table" -S "$chain" >/dev/null 2>&1
}

safe_chain_create() {
  local iptables="$1"
  local table="$2"
  local chain="$3"

  [ -z "$iptables" ] || [ -z "$chain" ] && return 1

  if chain_exists "$iptables" "$table" "$chain"; then
    return 1
  elif ! $iptables -w -t "$table" -N "$chain"; then
    return 1
  fi

  return 0
}

set_chain_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local protocols="${4:-}"

  ! safe_chain_create "$iptables" "$table" "$chain" && return

  case "$chain" in
  "$CHAIN_PREROUTING")
    add_skeen_rules "$iptables" "$table" "$chain" "exclude_connmark" "$protocols"

    if [ "$table" = "mangle" ]; then
      add_skeen_rules "$iptables" "$table" "$chain" "socket" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "ctdir_reply" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "intercept_dns" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "exclude_set" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "tproxy" "$protocols"
      add_skeen_rules "$iptables" "$table" "INPUT" "keendns_accept" "$protocols"
    elif [ "$table" = "nat" ]; then
      add_skeen_rules "$iptables" "$table" "$chain" "ctdir_reply" "$protocols"
      add_skeen_rules "$iptables" "$table" "$chain" "exclude_set" "$protocols"
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
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"          # PREROUTING / OUTPUT
  local target_chain="${4:-}"   # $CHAIN_PREROUTING / $CHAIN_OUTPUT
  local protocols="${5:-}"

  local rule="-m conntrack ! --ctstate INVALID -g $target_chain"

  for proto in $protocols; do
    if ! $iptables -t "$table" -S "$target_chain" >/dev/null 2>&1; then
      return
    fi

    # shellcheck disable=SC2086
    if ! $iptables -t "$table" -C "$chain" -p "$proto" $rule >/dev/null 2>&1; then
      $iptables -w -t "$table" -A "$chain" -p "$proto" $rule
    fi
  done
}

set_proxy_router_rules()  {
  local iptables="${1:-}"
  local table="${2:-}"
  local protocols="${3:-}"

  set_chain_rules "$iptables" "$table" "$CHAIN_OUTPUT" "$protocols"
  goto_chain_rules "$iptables" "$table" OUTPUT "$CHAIN_OUTPUT" "$protocols"
}

release_version_ge5() {
  local major
  major=$(rci_post show/version | jsonfilter -e '@.release' 2>/dev/null | cut -d'.' -f1)

  if [ "$major" -lt 5 ]; then
    echoerr "Версия KeeneticOS ниже 5-ой" && return 1
  fi
}

tun_create() {
  local opkgtun_ip="${1:-}"
  local opkgtun_desc="${2:-}"
  local opkgtun_name="OpkgTun0"

  if [ -z "$opkgtun_ip" ] || [ -z "$opkgtun_desc" ]; then
    echomsg "Используйте следующий формат для создания интерфейса OpkgTun:"
    echomsg "skeen tun create <ipv4> <имя>"
    return
  fi

  case "$opkgtun_desc" in
  [!A-Za-z0-9_-]*)
    echoerr "Недопустимое имя, допустимые символы: A–Z, a–z, 0–9, _ и -"
    return
    ;;
  esac

  if ! is_valid_ipv4 "$opkgtun_ip"; then
    echoerr "Неверный IPv4 адрес: $opkgtun_ip"
    return
  fi
  opkgtun_ip="${opkgtun_ip%%/*}"

  local interface_data inface_list iface description address
  interface_data="$(rci_post show/interface)"
  inface_list=$(echo "$interface_data" | jsonfilter -e '$.interface[*].id' | grep 'OpkgTun' | sort -u)

  for iface in $inface_list; do
    description=$(echo "$interface_data" | jsonfilter -e "@.interface['$iface'].description")
    address=$(echo "$interface_data" | jsonfilter -e "@.interface['$iface'].address")

    if [ "$description" = "$opkgtun_desc" ]; then
      echoerr "Интерфейс с именем '$opkgtun_desc' уже существует"
      return
    fi

    if [ "$address" = "$opkgtun_ip" ]; then
      echoerr "IP адрес '$opkgtun_ip' уже используется"
      return
    fi
  done

  local opkgtun_ids id opkg_index

  opkgtun_ids=$(echo "$inface_list" | sed 's/OpkgTun//' | sort -nu)

  opkg_index=0
  for id in $opkgtun_ids; do
    if [ "$id" -eq "$opkg_index" ]; then
      opkg_index=$((opkg_index + 1))
    else
      break
    fi
  done
  opkgtun_name="OpkgTun${opkg_index}"

  local payload='[{"interface":{"'"$opkgtun_name"'":{"description":"'"$opkgtun_desc"'"}}},
  {"interface":{"'"$opkgtun_name"'":{"ip":{"address":{"address":"'"$opkgtun_ip"'","mask":"255.255.255.255"}}}}},
  {"interface":{"'"$opkgtun_name"'":{"ip":{"tcp":{"adjust-mss":{"pmtu":true}}}}}},
  {"ip":{"route":{"default":true,"gateway":"'"$opkgtun_ip"'","interface":"'"$opkgtun_name"'"}}},
  {"interface":{"'"$opkgtun_name"'":{"ip":{"global":{"auto":true}}}}},
  {"interface":{"'"$opkgtun_name"'":{"up":true}}},
  {"system":{"configuration":{"save":true}}}]'

  rci_post "" "$payload" >/dev/null 2>&1 || {
    echoerr "Не удалось создать интерфейс: $opkgtun_desc" && return
    release_version_ge5
  }

  local opkgtun_name_lower
  opkgtun_name_lower="$(echo "$opkgtun_name" | tr '[:upper:]' '[:lower:]')"

  echook "OpkgTun интерфейс с именем '$opkgtun_desc' был успешно создан"
  echo "Используйте имя $(green "\"$opkgtun_name_lower\"") для поля $(yellow "\"interface_name\"") в конфигурации tun"
}

tun_delete() {
  local opkgtun_desc="${1:-}"

  if [ -z "$opkgtun_desc" ]; then
    echoerr "Пожалуйста, укажите имя для интерфейса OpkgTun"
    echomsg "skeen tun delete <имя>"
    return
  fi

  local interface_data inface_list iface description
  interface_data="$(rci_post show/interface)"
  inface_list=$(echo "$interface_data" | jsonfilter -e '$.interface[*].id' | grep 'OpkgTun' | sort -u)

  for iface in $inface_list; do
    description="$(echo "$interface_data" | jsonfilter -e "@.interface['$iface'].description")"

    if [ "$opkgtun_desc" = "$description" ]; then
      rci_delete "interface/${iface}" >/dev/null 2>&1 || {
        echoerr "Ошибки при удалении интерфейса: $opkgtun_desc" && return
        release_version_ge5
      }
      rci_post "system/configuration/save" >/dev/null 2>&1

      echook "Интерфейс '$opkgtun_desc' был успешно удален"
      return
    fi
  done

  echoerr "OpkgTun интерфейс с именем '$opkgtun_desc' не существует"
}

tun_list() {
  local interface_data inface_list iface description address

  interface_data="$(rci_post show/interface)"
  inface_list=$(echo "$interface_data" | jsonfilter -e '$.interface[*].id' | grep 'OpkgTun' | sort -u)

  [ -z "$inface_list" ] && echomsg "Интерфейсы типа OpkgTun не найдены" && return

  is_tty && printf "\n  \033[1m%-10s | %-10s | %-15s\033[0m\n" "IFACE" "IP ADDRESS" "NAME"
  is_tty && printf "  %-10s-|-%-10s-|-%-15s\n" "----------" "----------" "---------------"

  for iface in $inface_list; do
    description=$(echo "$interface_data" | jsonfilter -e "$.interface['$iface'].description")
    address=$(echo "$interface_data" | jsonfilter -e "$.interface['$iface'].address")

    [ -z "$description" ] && description="-"
    [ -z "$address" ] && address="-"

    printf "  %-10s | %-10s | %-15s\n" "$iface" "$address" "$description"
  done
  is_tty && echo ""
}

set_tun_rules() {
  apply_rule() {
    table="$1"
    shift

    iptables -t "$table" -C "$@" 2>/dev/null || \
    iptables -t "$table" -A "$@"
  }

  iptables -t filter -N "$CHAIN_TUN" 2>/dev/null
  apply_rule filter INPUT -i opkgtun+ -j "$CHAIN_TUN"
  apply_rule filter "$CHAIN_TUN" -i opkgtun+ -j ACCEPT
  apply_rule filter "$CHAIN_TUN" -o opkgtun+ -j ACCEPT
  apply_rule nat POSTROUTING -o opkgtun+ -j MASQUERADE -m comment --comment "$CHAIN_TUN"
}

prepare_firewall() {
  local complete_msg
  local redirect_data
  local tproxy_data
  local has_opkgtun
  local route_all
  local intercept_ports
  local exclude_ports

  echomsg "Подготовка фаервола:"

  complete_msg="Подготовка фаервола завершена"

  get_sing_args_config

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

  cyan " - Обнаружен режим фаервола: $SKEEN_FIREWALL_MODE $has_opkgtun"

  get_firewall_config

  SKEEN_INTERCEPT_DNS_ENABLE="0"
  SKEEN_REDIRECT_DNS_ENABLE="0"
  SKEEN_REDIRECT_DNS_PORT=""

  if has_dns_servers; then
    local msg_dns_detect=" - Обнаружена конфигурация DNS:"
    if [ "$FIREWALL_REDIRECT_DNS_ENABLE" = "1" ]; then
      if [ -z "$FIREWALL_REDIRECT_DNS_PORT" ]; then
        echoerr "Включен редирект DNS, но порт не указан в конфигурации $SKEEN_NAME"
        press_any_key_to_menu "" 1
      fi
      check_port "$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_ENABLE="1"
      SKEEN_REDIRECT_DNS_PORT="$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_USE_POLICY="$FIREWALL_REDIRECT_DNS_USE_POLICY"
      [ "$SKEEN_FIREWALL_MODE" = "none" ] && SKEEN_FIREWALL_MODE="dns"
      cyan "$msg_dns_detect redirect"
    fi

    if [ "$FIREWALL_REDIRECT_DNS_ENABLE" = "1" ] && [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      echowarn "Включен редирект и перехват DNS, будет работать только редирект"
    elif [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      case "$SKEEN_FIREWALL_MODE" in
      tproxy | hybrid)
        SKEEN_INTERCEPT_DNS_ENABLE="1"
        cyan "$msg_dns_detect intercept"
      ;;
      *) echowarn "В режиме '$SKEEN_FIREWALL_MODE' перехват DNS не работает" ;;
      esac
    fi
  elif [ "$FIREWALL_REDIRECT_DNS_ENABLE" = "1" ] || [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
    echowarn "Заданы настройки DNS в ${SKEEN_NAME}, но $SINGBOX_NAME не нестроен"
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

      echo "logger -p notice -t \"$SKEEN_NAME\" \"Обновление \$type правил \$table таблицы\""

      echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""

      [ "$SKEEN_FIREWALL_MODE" = "tun" ] &&
        echo "export SKEEN_TUN_ENABLED=\"$SKEEN_TUN_ENABLED\""

      echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""

      if [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
        loading_modules xt_comment.ko
        [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] &&
          SKEEN_MARK_POLICY="$(get_mark_policy)"
        echo "export SKEEN_REDIRECT_DNS_ENABLE=\"$SKEEN_REDIRECT_DNS_ENABLE\""
        echo "export SKEEN_REDIRECT_DNS_PORT=\"$SKEEN_REDIRECT_DNS_PORT\""
        echo "export SKEEN_REDIRECT_DNS_USE_POLICY=\"$SKEEN_REDIRECT_DNS_USE_POLICY\""
        echo "export SKEEN_MARK_POLICY=\"${SKEEN_MARK_POLICY:-}\""
      fi

      echo "$SKEEN_PROC apply_firewall netfilter \"\$table\""
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

  cyan " - Проверка и загрузка модулей..."
  loading_modules

  SKEEN_MARK_POLICY="$(get_mark_policy)"

  route_all=1
  if [ "$POLICY_ENABLE" != "1" ]; then
    cyan " - Политика отключена в skeen.json"
  elif [ -z "$POLICY_NAME" ]; then
    cyan " - Имя политики не задано"
  elif [ -z "$SKEEN_MARK_POLICY" ]; then
    echowarn "Политика $POLICY_NAME не найдена"
  else
    cyan " - Маршрутизация для политики: $POLICY_NAME"
    route_all=0
  fi
  [ "$route_all" = 1 ] && echowarn "Маршрутизация для всего устройства"

  SKEEN_PROXY_ROUTER="0"
  [ "$FIREWALL_PROXY_ROUTER" = "1" ] && SKEEN_PROXY_ROUTER="1"

  SKEEN_USE_CONNMARK="0"
  [ "$FIREWALL_USE_CONNTRACK" = "1" ] && SKEEN_USE_CONNMARK="1"

  SKEEN_IPTABLES_LIST="$(get_iptables_list)"

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "Нет поддерживаемых iptables"
    press_any_key_to_menu "" 1
  fi

  setup_port_set() {
    local name_set="$1"
    local ports="$2"

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

  SKEEN_INTERCEPT_PORT="1"
  SKEEN_EXCLUDE_PORT="0"

  intercept_ports="$(get_validate_ports "intercept" "$(json_get_array '@.firewall.intercept.port')")"

  if [ -n "$intercept_ports" ]; then
    setup_port_set "$PORT_INTERCEPT_SET" "$intercept_ports"
    ipset destroy "$PORT_EXCLUDE_SET" -exist 2>/dev/null

    SKEEN_INTERCEPT_PORT="1"
    SKEEN_EXCLUDE_PORT="0"
  else
    exclude_ports="$(get_validate_ports "exclude" "$(json_get_array '@.firewall.exclude.port')")"

    if [ -n "$exclude_ports" ]; then
      setup_port_set "$PORT_EXCLUDE_SET" "$exclude_ports"
      SKEEN_EXCLUDE_PORT="1"
    fi

    ipset destroy "$PORT_INTERCEPT_SET" -exist 2>/dev/null
    SKEEN_INTERCEPT_PORT="0"
  fi

  setup_net_ipset() {
    local ipver="$1"
    local family="$2"
    local name_set="${NET_EXCLUDE_SET}${ipver}"
    local addresses

    ipset create "$name_set" hash:net family "$family" -exist
    ipset flush "$name_set"

    addresses=$(get_exclude_addresses "$ipver")

    if [ -n "$addresses" ]; then
      {
        for addr in $addresses; do
          printf "add %s %s -exist\n" "$name_set" "$addr"
        done
      } | ipset restore
    fi
  }

  if echo "$SKEEN_IPTABLES_LIST" | grep -q "iptables"; then
    setup_net_ipset 4 inet
  fi

  if echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6tables"; then
    setup_net_ipset 6 inet6
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
    elif [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
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

    echo "logger -p notice -t \"$SKEEN_NAME\" \"Обновление \$type правил \$table таблицы\""

    echo "export SKEEN_REDIRECT_PORT=\"$SKEEN_REDIRECT_PORT\""
    echo "export SKEEN_TPROXY_PORT=\"$SKEEN_TPROXY_PORT\""
    echo "export SKEEN_TPROXY_NETWORK=\"$SKEEN_TPROXY_NETWORK\""
    echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""
    echo "export SKEEN_FIREWALL_NETWORK=\"$SKEEN_FIREWALL_NETWORK\""
    echo "export SKEEN_POLICY_NAME=\"$POLICY_NAME\""
    echo "export SKEEN_MARK_POLICY=\"$SKEEN_MARK_POLICY\""
    echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""
    echo "export SKEEN_INTERCEPT_PORT=\"$SKEEN_INTERCEPT_PORT\""
    echo "export SKEEN_EXCLUDE_PORT=\"$SKEEN_EXCLUDE_PORT\""
    echo "export SKEEN_INTERCEPT_DNS_ENABLE=\"$SKEEN_INTERCEPT_DNS_ENABLE\""
    echo "export SKEEN_REDIRECT_DNS_ENABLE=\"$SKEEN_REDIRECT_DNS_ENABLE\""
    echo "export SKEEN_REDIRECT_DNS_PORT=\"$SKEEN_REDIRECT_DNS_PORT\""
    echo "export SKEEN_REDIRECT_DNS_USE_POLICY=\"$SKEEN_REDIRECT_DNS_USE_POLICY\""
    echo "export SKEEN_TUN_ENABLED=\"$SKEEN_TUN_ENABLED\""
    echo "export SKEEN_PROXY_ROUTER=\"$SKEEN_PROXY_ROUTER\""
    echo "export SKEEN_USE_CONNMARK=\"$SKEEN_USE_CONNMARK\""
    echo "$SKEEN_PROC apply_firewall netfilter \"\$table\""
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

  if [ "$SKEEN_FIREWALL_MODE" != "none" ] || [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
    echomsg "Применение правил фаервола..."
  fi

  # DNS redirect
  if [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ] && check_hook_table "nat" "$hook_table"; then
    local mark_option=""
    [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] && [ -n "$SKEEN_MARK_POLICY" ] &&
      mark_option="-m mark --mark $SKEEN_MARK_POLICY"

    local args="-i br+ $mark_option -m pkttype --pkt-type unicast \
      --dport $DNS_PORT -j REDIRECT --to-ports $SKEEN_REDIRECT_DNS_PORT \
      -m comment --comment skeen_dns"

    for iptables in $SKEEN_IPTABLES_LIST; do
      for proto in tcp udp; do
        # shellcheck disable=SC2086
        if ! $iptables -t nat -C "$CHAIN_DNS" -p "$proto" $args >/dev/null 2>&1; then
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
        protocols="$(get_protocols "$table")"
        set_chain_rules "$iptables" "$table" "$CHAIN_PREROUTING" "$protocols"
        goto_chain_rules "$iptables" "$table" PREROUTING "$CHAIN_PREROUTING" "$protocols"
        [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$table" "$protocols"
      done
    elif [ "$SKEEN_FIREWALL_MODE" = "tproxy" ] && check_hook_table "$TABLE_TPROXY" "$hook_table"; then
      protocols="$(get_protocols "$TABLE_TPROXY")"
      set_chain_rules "$iptables" "$TABLE_TPROXY" "$CHAIN_PREROUTING" "$protocols"
      goto_chain_rules "$iptables" "$TABLE_TPROXY" PREROUTING "$CHAIN_PREROUTING" "$protocols"
      [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$TABLE_TPROXY" "$protocols"
    elif [ "$SKEEN_FIREWALL_MODE" = "redirect" ] && check_hook_table "$TABLE_REDIRECT" "$hook_table"; then
      protocols="$(get_protocols "$TABLE_REDIRECT")"
      set_chain_rules "$iptables" "$TABLE_REDIRECT" "$CHAIN_PREROUTING" "$protocols"
      goto_chain_rules "$iptables" "$TABLE_REDIRECT" PREROUTING "$CHAIN_PREROUTING" "$protocols"
      [ "$SKEEN_PROXY_ROUTER" = "1" ] && set_proxy_router_rules "$iptables" "$TABLE_REDIRECT" "$protocols"
    fi
  done

  [ -f "$WAIT_ROUTE_FILE" ] && rm -f "$WAIT_ROUTE_FILE"

  echook "Правила фаервола применены"
}

clean_firewall() {
  echomsg "Очистка правил фаервола..."

  clean_chain() {
    local iptables="$1"
    local table="$2"
    local chain="$3"
    local parent="$4"

    if ! chain_exists "$iptables" "$table" "$chain"; then
      return 0
    fi

    $iptables -t "$table" -S "$parent" 2>/dev/null |
      grep -w "$chain" | sed "s/^-A/$iptables -w -t $table -D/" | sh 2>/dev/null

    $iptables -w -t "$table" -F "$chain" 2>/dev/null
    $iptables -w -t "$table" -X "$chain" 2>/dev/null
  }

  # 1. tun rules
  iptables -t nat -S POSTROUTING 2>/dev/null | \
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
      for ch in "$CHAIN_PREROUTING" "$CHAIN_DIVERT" "$CHAIN_DNS_PRE" "$CHAIN_TPROXY" "$CHAIN_REDIRECT"; do
        clean_chain "$ipt_cmd" "$table" "$ch" PREROUTING
      done

      # OUTPUT chains
      for ch in "$CHAIN_OUTPUT" "$CHAIN_DNS_OUT" "$CHAIN_MARK_OUT" "$CHAIN_REDIRECT"; do
        clean_chain "$ipt_cmd" "$table" "$ch" OUTPUT
      done
    done
  done

  # 5. routing cleanup
  ip -4 rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" 2>/dev/null
  ip -6 rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" 2>/dev/null
  ip route flush table "$TABLE_ID" 2>/dev/null

  # 6. ipset cleanup
  if command -v ipset >/dev/null 2>&1; then
    for ip_ver in 4 6; do
      set_name="${NET_EXCLUDE_SET}${ip_ver}"
      ipset flush "$set_name" -exist 2>/dev/null
      ipset destroy "$set_name" -exist 2>/dev/null
    done

    for port_set in "$PORT_EXCLUDE_SET" "$PORT_INTERCEPT_SET"; do
      ipset flush "$port_set" -exist 2>/dev/null
      ipset destroy "$port_set" -exist 2>/dev/null
    done
  fi

  # 7. cleanup hook
  rm -f "$FIREWALL_HOOK_FILE" 2>/dev/null

  echook "Очистка фаервола завершена"
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
  local timeout=40
  local status_start
  local msg

  echomsg "Запуск ${SINGBOX_NAME}..."

  # shellcheck disable=SC3045
  ulimit -n "$(get_ulimit_n)" || exiterr "Не удалось установить ulimit -n"

  get_sing_args_config
  # shellcheck disable=SC2086
  start-stop-daemon -S -b -x $SINGBOX_PROC -c root:$SKEEN_PROC -- $SINGBOX_ARGS
  status_start=$?

  if [ $status_start -ne 0 ]; then
    msg="Не удалось запустить $SINGBOX_NAME"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  while ! is_running && [ $timeout -gt 0 ]; do
    usleep 250000
    timeout=$((timeout - 1))
  done

  if ! is_running; then
    msg="$SINGBOX_NAME не запустился вовремя"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  echook "$SINGBOX_NAME запущен"
  logger_notice "$SINGBOX_NAME запущен"
  return 0
}

start() {
  get_sing_binary_config

  if [ ! -f "$SINGBOX_BIN" ]; then
    echoerr "$SINGBOX_NAME не найден, сначала установите его"
    press_any_key_to_menu "" 1
  fi

  if [ "$CALLER" = "init" ]; then
    get_auto_start_config
    if [ "$AUTO_START_ENABLE" = "0" ]; then
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
    echook "$SINGBOX_NAME уже запущен"
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
  local timeout=40
  local status_stop
  local msg

  echomsg "Остановка ${SINGBOX_NAME}..."

  get_sing_binary_config

  if ! is_running; then
    echook "$SINGBOX_NAME уже остановлен"
    return 0
  fi

  # shellcheck disable=SC2086
  start-stop-daemon -K -x $SINGBOX_PROC >/dev/null
  status_stop=$?

  if [ $status_stop -ne 0 ]; then
    msg="Не удалось отправить сигнал остановки $SINGBOX_NAME"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  while is_running && [ $timeout -gt 0 ]; do
    usleep 250000
    timeout=$((timeout - 1))
  done

  if is_running; then
    msg="$SINGBOX_NAME не остановился вовремя"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  msg="$SINGBOX_NAME остановлен"
  echook "$msg"
  logger_notice "$msg"
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
  get_sing_binary_config

  if ! is_running; then
    echook "$SINGBOX_NAME не запущен"
    return 0
  fi

  echo "Принудительная остановка ${SKEEN_PROC}..."
  killall -9 "$SINGBOX_PROC" 2>/dev/null
  clean_firewall
}

version() {
  local sk_version sb_version

  get_sing_binary_config
  sk_version="$(get_current_version "skeen")"
  sb_version="$(get_current_version "sing")"
  if [ "$CALLER" = "cli" ]; then
    echo "$DELIMETER"
    printf "${SKEEN_NAME}: %s\n" "$(cyan "v${sk_version}")"
    echo "$DELIMETER"

    printf "${SINGBOX_NAME}: %s\n" "$(cyan "v${sb_version}")" &&
      $SINGBOX_BIN version | sed -nE '/^(Environment|Tags|Revision|CGO):/p' &&
      echo "$DELIMETER"
  fi
}

switch_state() {
  get_sing_binary_config

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
  stop_singbox && start_singbox || exit 1
}

proc_uptime() {
  local pid="$1"
  local up
  local stat
  local runtime

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
  local pid
  local mem_used
  local mem_peak
  local threads

  get_sing_binary_config
  pid="$(pidof "$SINGBOX_PROC")"

  if [ -n "$pid" ]; then
    # shellcheck disable=SC2046
    set -- $(awk '$1=="VmRSS:"{r=$2} $1=="VmHWM:"{h=$2} $1=="Threads:"{t=$2} END{print r,h,t}' "/proc/$pid/status")
    mem_used="${1:-0}"
    mem_peak="${2:-0}"
    threads="${3:-0}"

    echo "Статус: $(green "running")"
    echo "PID: $pid"
    echo "Время работы: $(proc_uptime "$pid")"
    echo "Память: $((mem_used / 1024)) MB (пиковая: $((mem_peak / 1024)) MB)"
    echo "Потоки: $threads"
    echo "Файловые дескрипторы: $(find "/proc/${pid}/fd" -type l 2>/dev/null | wc -l) (лимит: $(awk '/Max open files/ {print $5}' "/proc/${pid}/limits" 2>/dev/null))"
  else
    echo "Статус: $(red "stopped")"
  fi
}

update_core() {
  check_free_space
  get_os_release
  get_architecture
  download_singbox || return 1
  if is_running; then stop || exit 1; fi
  install_singbox
  create_singbox_config
  echook "Ядро $SINGBOX_NAME успешно обновлено"
}

update_skeen() {
  local should_run="0"

  get_service_proxy_config
  get_firewall_config
  if [ "$SERVICE_PROXY_ENABLE" = "1" ] || [ "$FIREWALL_PROXY_ROUTER" = "1" ]; then
    should_run="1"
  fi
  if [ "$should_run" = "1" ]; then
    if ! is_running; then start || press_any_key_to_menu "" 1; fi
  elif is_running; then stop || press_any_key_to_menu "" 1; fi

  if download_skeen_script "update"; then
    echook "$SKEEN_NAME успешно обновлён"
    is_update_skeen=1
  else
    echoerr "Не удалось обновить $SKEEN_NAME"
  fi
}

ask_and_update() {
  local name="${1:-}"
  local proc="${2:-}"
  local api="${3:-}"
  local update_fn="${4:-}"
  local releases="${5:-}"
  local current_version opt
  latest_version=""

  echomsg "Проверка обновлений ${name}..."

  current_version=$(get_current_version "$proc")
  [ -z "$current_version" ] && current_version="не установлено"
  latest_version=$(get_latest_version "$api")
  [ -z "$latest_version" ] && echoerr "Не удалось получить номер последней версии" && return 1

  if [ "$latest_version" != "$current_version" ]; then
    printf '%s %s\n' "$(cyan "Текущая версия ${name}:")" "$(red "$current_version")"
    printf '%s %s\n' "$(cyan "Доступна новая версия:")" "$(green "$latest_version")"
    printf '%s %s\n' "$(cyan "Подробнее:")" "$(green "$releases")"

    while :; do
      printf 'Выполнить обновление? [y/n] (по умолчанию: n): ' >/dev/tty
      read -r opt </dev/tty
      [ -z "$opt" ] && opt=n

      case $opt in
      y | Y)
        "$update_fn" || return 1
        break
        ;;
      n | N) break ;;
      *) echoerr "Неверный вариант" ;;
      esac
    done
  else
    echook "Последняя версия $name $latest_version уже установлена"
  fi

  return 0
}

check_updates() {
  local optt

  check_tty

  is_update_skeen=0

  get_sing_binary_config
  get_curl_proxy_options

  # sing-box
  if [ "$SING_BINARY_ENABLE" != "1" ]; then
    ask_and_update "$SINGBOX_NAME" "sing" "$SINGBOX_API_URL" \
      update_core "https://github.com/SagerNet/sing-box/releases"
    if [ $? -eq 1 ] && [ ! -f "$SINGBOX_BIN" ] && [ -n "$latest_version" ]; then
      while :; do
        printf "Загрузить %s %s? [y/n] (по умолчанию: n): " "$SINGBOX_NAME" "$latest_version" >/dev/tty
        read -r optt </dev/tty
        [ -z "$optt" ] && optt=n

        case $optt in
        y | Y)
          update_core
          break
          ;;
        n | N) break ;;
        *) echoerr "Неверный вариант" ;;
        esac
      done
    fi
  fi

  # skeen
  ask_and_update "$SKEEN_NAME" "skeen" "$SKEEN_API_URL" \
    update_skeen "https://github.com/jinndi/SKeen/releases"
  [ $? -eq 1 ] && [ ! -f "$SKEEN_SCRIPT" ] && [ -n "$latest_version" ] && update_skeen

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

  cyan "Тест $ref $1 $2"

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

  [ "$SKEEN_USE_CONNMARK" = "1" ] && fw_test "$1" "$2" "$content" "ctdir REPLY" "REPLY accept"

  if [ "$1" = "mangle" ]; then
    case "$2" in
    "$CHAIN_PREROUTING")
      [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ] && comment="DNS intercept" || comment="DNS exclude"
      fw_test "$1" "$2" "$content" "dpt:${DNS_PORT}" "$comment"
      ;;
    "$CHAIN_OUTPUT")
      [ "$SKEEN_REDIRECT_DNS_ENABLE" != "1" ] && comment="DNS mark" || comment="DNS exclude"
      fw_test "$1" "$2" "$content" "dpt:${DNS_PORT}" "$comment"
      ;;
    esac
  fi

  if [ "$SKEEN_INTERCEPT_PORT" = "1" ]; then
    fw_test "$1" "$2" "$content" "$PORT_INTERCEPT_SET" "Port filter"
  elif [ "$SKEEN_EXCLUDE_PORT" = "1" ]; then
    # shellcheck disable=SC2015
    fw_test "$1" "$2" "$content" "$PORT_EXCLUDE_SET" "Port exclude"
  fi

  fw_test "$1" "$2" "$content" "$NET_EXCLUDE_SET" "Subnet exclude"

  if [ "$1" = "mangle" ] && [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "$CHAIN_MARK_OUT" "Mark set"
  elif [ "$1" = "nat" ] && [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "redir|$CHAIN_REDIRECT" "TCP Redirect"
  fi

  [ "$2" = "$CHAIN_OUTPUT" ] && return 0

  if [ "$1" = "mangle" ]; then
    fw_test "$1" "$2" "$content" "redirect|$CHAIN_TPROXY" "TProxy redirect"
  elif [ "$1" = "nat" ]; then
    fw_test "$1" "$2" "$content" "redir|$CHAIN_REDIRECT" "TCP Redirect"
  fi
}

test_firewall() {
  local tables

  get_sing_binary_config
  if ! is_running; then
    echoerr "Тестирование доступно только когда $SKEEN_NAME запущен"
    press_any_key_to_menu "" 1
  else
    if [ ! -f "$FIREWALL_HOOK_FILE" ]; then
      echoerr "Файл по пути $FIREWALL_HOOK_FILE отсутствует!"
      echomsg "Пожалуйста, перезагрузите $SINGBOX_NAME"
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
  elif [ "$SKEEN_REDIRECT_DNS_ENABLE" != "1" ]; then
    echowarn "Тестирование доступно в режимах tun, redirect, tproxy и hybrid"
    echowarn "А также при заданных параметрах редиректа DNS"
    press_any_key_to_menu "" 1
  fi

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "Утилита iptables не установлена?"
    press_any_key_to_menu "" 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ]; then
    fw_test_chain filter "$CHAIN_TUN" "iptables"
  else
    for iptables in $SKEEN_IPTABLES_LIST; do
      [ "$iptables" = "ip6tables" ] && echo "$DELIMETER"
      yellow "Тестирование: $(cyan "$iptables")"
      echo "$DELIMETER"

      [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ] && fw_test_chain nat "$CHAIN_DNS" "$iptables"

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
  local archive_path
  local parent_dir
  local folder_name
  local required_mb

  if [ -d "$WORK_DIR" ] && [ "$(ls -A "$WORK_DIR")" ]; then
    required_mb="$(du -sm "$WORK_DIR" | awk '{print $1}')"

    check_free_space "$required_mb"

    echomsg "Создание резервной копии конфигурации..."
    archive_path="${ENTWARE_DIR}/skeen_$(date '+%Y-%m-%d_%H%M%S').tar"
    parent_dir=$(dirname "$WORK_DIR")
    folder_name=$(basename "$WORK_DIR")
    if tar -cf "$archive_path" -C "$parent_dir" "$folder_name"; then
      echook "Резервная копия успешно создана: $archive_path"
    else
      echoerr "Ошибка создания резервной копии!"
      return 1
    fi
  else
    echowarn "Конфигурация не найдена, резервное копирование пропущено"
  fi
  return 0
}

backup_restore() {
  local tarname="${1:-}"
  local archive_path

  restore() {
    local archive_path="${ENTWARE_DIR}/${1:-}"
    local work_dir_backup
    local required_mb

    if [ -f "$archive_path" ] && tar -tf "$archive_path" | grep -q "^skeen/"; then
      required_mb="$(du -sm "$archive_path" | awk '{print $1}')"
      check_free_space "$required_mb"

      work_dir_backup="${ENTWARE_DIR}/skeen_backup"
      mv "$WORK_DIR" "$work_dir_backup"
      mkdir -p "$WORK_DIR"
      echomsg "Распаковка архива ${archive_path}..."
      if tar --strip-components=1 -xf "$archive_path" -C "$WORK_DIR"; then
        rm -rf "$work_dir_backup"
        echook "Резервная копия успешно восстановлена"
      else
        rm -rf "$WORK_DIR"
        mv "$work_dir_backup" "$WORK_DIR"
        echoerr "Ошибка распаковки архива $archive_path"
        return 1
      fi
    else
      echoerr "Архив отсутствует или папка 'skeen' не найдена"
      return 1
    fi

    return 0
  }

if is_tty && [ "$CALLER" = "cli" ] && [ -z "$tarname" ]; then
  while :; do
    printf "Введите имя файла резервного архива\n"
    printf "находящегося в корневом каталоге /opt,\n"
    printf "например %s: " "$(cyan "skeen.tar")" >/dev/tty
    read -r tarname </dev/tty
    [ -z "$tarname" ] && exit 1
    restore "$tarname" && break
  done
  elif [ -n "$tarname" ]; then
    restore "$tarname"
  else
    echoerr "Имя архива не указано"
    return 1
  fi
}

config_reset() {
  check_tty

  while :; do
    printf "Будет выполнен полный сброс конфигурации,\n"
    printf "с созданием резервной копии текущей\n"
    printf "Продолжить? [y/n]: " >/dev/tty
    read -r option </dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
    y | Y)
      if backup_create; then
        rm -rf "$WORK_DIR"
        mkdir -p "$WORK_DIR"
        create_singbox_config "force"
        create_skeen_config "force"
        echook "Сброс конфигурации выполнен"
      else
        echoerr "Не удалось сбросить конфигурацию!"
      fi
      break
      ;;
    n | N) break ;;
    *) echoerr "Неверный вариант" ;;
  esac
  done

  press_any_key_to_menu
}

clean_cache() {
  local experimental_file=""
  local cache_file=""
  local msg_not_found="Кэш файл не найден по пути"

  get_sing_args_config

  if [ "$SING_CONFIG_ENABLE" = "1" ] && [ -f "$SING_CONFIG_PATH" ]; then
    experimental_file="$SING_CONFIG_PATH"
  elif [ -d "$CONFIG_DIR" ] && [ -f "${CONFIG_DIR}/experimental.json" ]; then
    experimental_file="${CONFIG_DIR}/experimental.json"
  elif [ -d "$CONFIG_DIR" ]; then
    for file in "$CONFIG_DIR"/*.json; do
      [ -f "$file" ] || continue
      if jsonfilter -i "$file" -e '@.experimental.cache_file.enabled' >/dev/null 2>&1; then
        experimental_file="$file"
        break
      fi
    done
  fi

  if [ -z "$experimental_file" ]; then
    echoerr "Файл конфигурации с параметром experimental.cache_file не найден"
    return 0
  fi

  cache_file_enabled="$(jsonfilter -i "$experimental_file" -e '@.experimental.cache_file.enabled')"
  if [ "$cache_file_enabled" != "true" ]; then
    echowarn "Кэш файл отключен в конфигурации $SINGBOX_NAME"
  fi

  cache_file="$(jsonfilter -i "$experimental_file" -e '@.experimental.cache_file.path')"

  if [ -z "$cache_file" ]; then
    cache_file="${WORK_DIR}/cache.db"
  else
    if ! echo "$cache_file" | grep -q "^/"; then
      cache_file="${WORK_DIR}/${cache_file}"
      if [ ! -f "$cache_file" ]; then
        echoerr "${msg_not_found}: $cache_file"
        return 0
      fi
    elif [ ! -f "$cache_file" ]; then
      echoerr "${msg_not_found}: $cache_file"
      return 0
    fi
  fi

  rm -f "$cache_file"
  echook "Кэш очищен. Перезапустите $SKEEN_NAME для применения изменений"
}

check_skeen_config() {
  echomsg "Проверка конфигурации $SKEEN_NAME..."
  if jsonfilter -i "$SKEEN_CONFIG" -e '@.auto_start' >/dev/null; then
    echook "$SKEEN_NAME JSON корректен"
  else
    local err_msg="$SKEEN_NAME конфигурация не корректна"
    echoerr "$err_msg"
    [ "$CALLER" != "menu" ] && logger_error "$err_msg"
    exit 0
  fi
}

check_sing_config() {
  if get_sing_binary_config && [ -f "$SINGBOX_BIN" ]; then
    echomsg "Проверка конфигурации $SINGBOX_NAME..."

    # shellcheck disable=SC2086
    if get_sing_args_config && $SINGBOX_PROC check $SING_CONFIG_ARGS; then
      echook "Конфигурация $SINGBOX_NAME корректна"
    else
      local err_msg="$SINGBOX_NAME конфигурация не корректна"
      echoerr "$err_msg"
      [ "$CALLER" != "menu" ] && logger_error "$err_msg"
      press_any_key_to_menu "" "1"
    fi
  fi
}

check_config() {
  check_skeen_config
  check_sing_config
}

format_config() {
  get_sing_binary_config

  if [ -f "$SINGBOX_BIN" ]; then
    echomsg "Форматирование конфигурации ${SINGBOX_NAME}..."

    get_sing_args_config

    # shellcheck disable=SC2086
    if $SINGBOX_PROC format -w $SING_CONFIG_ARGS; then
      echook "Конфигурация отформатирована успешно"
    else
      echoerr "Ошибка форматирования конфигурации"
    fi
  else
    echoerr "Исполняемый файл $SINGBOX_NAME отсутствует"
  fi
}

sync_config() {
  local address="${1:-}"
  local config_tmp="${TMP_DIR}/sing_config_tmp.json"

  if [ -z "$address" ]; then
    local sync_url=""
    sync_url="$(jsonfilter -i "$SKEEN_CONFIG" -e '@.sing_config.sync_url')"

    [ -z "$sync_url" ] && echoerr "Адрес для синхронизации не указан" && return 1
  fi

  if ! echo "$address" | grep -qE '^https?://'; then
    echoerr "URL должен начинаться с http:// или https://" && return 1
  fi

  get_curl_proxy_options

  # shellcheck disable=SC2086
  if ! curl $CURL_PROXY_OPTIONS -fsL "$address" -o "$config_tmp"; then
    echoerr "Не удалось загрузить конфигурацию с $address" && return 1
  fi

  if is_tty && ! $SINGBOX_PROC check -c "$config_tmp"; then
    echoerr "$SINGBOX_NAME конфигурация недействительна, синхронизация отменена!"
    rm -f "$config_tmp"
    return 1
  fi

  get_sing_args_config

  if [ "$SING_CONFIG_ENABLE" != "1" ]; then
    echowarn "Установите параметр sing_config.enable в 1 в файле skeen.json"
  fi

  rm -f "$SING_CONFIG_PATH"
  mv "$config_tmp" "$SING_CONFIG_PATH"
  echook "Конфигурация синхронизирована, перезапустите $SKEEN_NAME для применения изменений"
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
  local autostart_status
  local running_status
  local running_text
  local output=""
  local version
  local ipv4=""
  local ipv6=""
  local sb_dns_work_text

  check_tty
  check_skeen_config && printf "\033[1A\033[2K\033[1A\033[2K"
  import_firewall_vars
  show_header
  get_auto_start_config
  get_sing_binary_config

  if [ "$AUTO_START_ENABLE" = "1" ]; then
    autostart_status="$(green "да")"
  else
    autostart_status="$(red "нет")"
  fi

  if is_running; then
    running_status="$(green "running")"
    running_text="Остановить"
  else
    running_status="$(red "stopped")"
    running_text="Запустить"
  fi

  output="$output\n Версия ${SKEEN_NAME}: $(cyan "v$(get_current_version "skeen")")"

  version="$(cyan "v$(get_current_version "sing")")"
  [ "$version" = "$(cyan "v")" ] && version="$(red "не установлен")"
  output="$output\n Версия ${SINGBOX_NAME}: ${version}"

  output="$output\n Состояние ${SINGBOX_NAME}: $running_status"

  output="$output\n Автоматический запуск: $autostart_status"

  if [ "$running_text" = "Остановить" ]; then
    if [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ] || [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
      sb_dns_work_text="$(green "да")"
    else
      sb_dns_work_text="$(red "нет")"
    fi
    output="$output\n ${SINGBOX_NAME} DNS работает: $sb_dns_work_text"

    if [ "$SKEEN_FIREWALL_MODE" != "none" ] && [ "$SKEEN_FIREWALL_MODE" != "tun" ]; then
      echo "$SKEEN_IPTABLES_LIST" | grep -q "ipt" && ipv4="$(cyan "4")"
      echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6t" && ipv6="$(cyan "6")"

      [ -n "$SKEEN_POLICY_NAME" ] &&
        output="$output\n Политика клиентов: $(cyan "$SKEEN_POLICY_NAME")"
      [ "$SKEEN_TUN_ENABLED" = "1" ] &&
        output="$output\n Используется OpkgTun: $(cyan "да")"
      output="$output\n Режим фаервола: $(cyan "$SKEEN_FIREWALL_MODE")"
      output="$output\n Сеть фаервола: $(cyan "$SKEEN_FIREWALL_NETWORK")"
      output="$output\n Версия IP фаервола: $ipv4 $ipv6"
    else
      output="$output\n Режим фаервола: $(cyan "$SKEEN_FIREWALL_MODE")"
    fi
  fi

  output="$output\n\n$(cyan "Выберите действие:")"
  output="$output\n  $(green "1.") $running_text"
  output="$output\n  $(green "2.") Перезапустить"
  output="$output\n  $(green "3.") Обновление"
  output="$output\n  $(green "4.") Тест фаервола"
  output="$output\n  $(green "5.") Удаление"
  output="$output\n  $(green "0.") Выход\n"

  printf "%b" "$output"

  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    printf "\nВведите ваш выбор [0-5]: " >/dev/tty
    read -r option </dev/tty

    printf "\n"

    if echo "$option" | grep -Eq '^[1-5]$'; then
      echo "$DELIMETER"

      case "$option" in
      1) switch_state ;;
      2) restart ;;
      3) check_updates ;;
      4) test_firewall ;;
      5) accept_uninstall ;;
    esac
    else
      [ "$option" = 0 ] && exit 0
      echoerr "Неверный вариант"
      attempt=$((attempt + 1))
    fi
  done

  exiterr "Достигнуто максимальное количество попыток, выход из меню."
}

show_help() {
  cat <<EOF

$SKEEN_NAME CLI Команды (используйте: 'skeen help' для этого списка):

Управление сервисом:
  start   - Запустить сервис
  stop    - Остановить сервис
  restart - Перезапустить сервис
  reload  - Перезапустить без изменения правил файрвола
  kill    - Принудительная остановка
  status  - Показать статус

Информация & обновления:
  version - Показать версию(и)
  iface   - Показать таблицу сетевых интерфейсов
  update  - Проверить и установить обновления

Проверка & тестирование:
  test    - Тестировать правила файрвола
  deps    - Проверить зависимости
  check   - Проверить конфигурацию
  format  - Отформатировать конфигурацию $SINGBOX_NAME

Резервное копирование & восстановление:
  backup  - Создать архив $WORK_DIR
  backups - Список созданных архивов в $ENTWARE_DIR
  restore - Восстановить $WORK_DIR из архива в $ENTWARE_DIR

Сброс & очистка:
  reset   - Сбросить $WORK_DIR в значение по умолчанию
  clean   - Очистить кэш файл $SINGBOX_NAME

Синхронизация:
  sync    - Синхронизировать конфигурацию $SINGBOX_NAME

Менеджер OpkgTun (KeeneticOS v5+):
  tun create <ipv4> <имя>  - Создать интерфейс с IP-адресом и именем
  tun delete <имя>         - Удалить интерфейс по имени
  tun list                 - Список всех интерфейсов OpkgTun
EOF
}

if [ -f "$SKEEN_SCRIPT" ]; then
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
    case "$2" in
    create) tun_create "$3" "$4" ;;
    delete) tun_delete "$3" ;;
    list) tun_list ;;
    *) show_help | awk '/OpkgTun / {flag=1} flag' ;;
    esac
    ;;
  apply_firewall) [ "$CALLER" = "netfilter" ] && apply_firewall "$3" ;;
  "") show_menu ;;
  help | *) show_help ;;
  esac
else
  install
fi

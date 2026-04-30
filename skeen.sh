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
export PATH

ACTION="${1:-}"
CALLER="${2:-}"

[ -z "$CALLER" ] && CALLER="cli"
[ -z "$ACTION" ] && CALLER="menu"

DEPENDENCIES="ndmc start-stop-daemon iptables ip-full ipset net-tools curl tar jsonfilter logger"

ENTWARE_DIR="/opt"
WORK_DIR="${ENTWARE_DIR}/etc/skeen"
CONFIG_DIR="${WORK_DIR}/config"
TMP_DIR="${ENTWARE_DIR}/tmp"
NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
MODULES_OS_DIR="/lib/modules"
MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"

SKEEN_NAME="SKeen"
SKEEN_VERSION="4.9.0"
SKEEN_PROC="skeen"
SKEEN_SCRIPT="${ENTWARE_DIR}/bin/${SKEEN_PROC}"
SKEEN_SCRIPT_URL="https://github.com/jinndi/SKeen/releases/latest/download/skeen"
SKEEN_API_URL="https://api.github.com/repos/jinndi/SKeen/releases/latest"
SKEEN_CONFIG="${WORK_DIR}/${SKEEN_PROC}.json"
SKEEN_AUTOSTART_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"

SINGBOX_NAME="Sing-box"
SINGBOX_PROC="skeen-box"
SINGBOX_ARGS="run -D $WORK_DIR -C $CONFIG_DIR"
SINGBOX_BIN="${ENTWARE_DIR}/bin/${SINGBOX_PROC}"
SINGBOX_API_URL="https://api.github.com/repos/SagerNet/sing-box/releases/latest"
SINGBOX_SPACE_MB=128

FIREWALL_HOOK_FILE="${NETFILTER_DIR}/${SKEEN_PROC}_firewall.sh"
WAIT_ROUTE_FILE="/tmp/${SKEEN_PROC}_wait_route"
BYPASS_NET_SET="skeen_bypass_net"
CHAIN_PREROUTING="skeen"
CHAIN_OUTPUT="skeen_mask"
CHAIN_TUN="skeen_tun"
CHAIN_DNS="_NDM_HOTSPOT_DNSREDIR"
TABLE_REDIRECT="nat"
TABLE_TPROXY="mangle"
TABLE_MARK="0x112"
TABLE_ID="112"
DNS_PORT=53

RCI="http://127.0.0.1:79/rci"

# IETF/IANA IPv4 Special-Purpose Address Registry
# https://www.iana.org/assignments/iana-ipv4-special-registry/
RESERVED_IPV4="
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
RESERVED_IPV6="
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

DELIMETER="------------------------------------------------"

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
    rm -f "$SKEEN_CONFIG"
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
    "check": ["1.1.1.1", "ya.ru", "223.5.5.5"],
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
      "port": [123, 137, 138, 139, 445],
      "ipv4_cidr": [],
      "ipv6_cidr": []
    },
    "redirect_dns": {
      "enable": 0,
      "to_port": "",
      "use_policy": 1
    }
  }
}
EOF

  [ ! -f "$SKEEN_AUTOSTART_SCRIPT" ] && create_autostart_script >/dev/null 2>&1

  echook "Configuration file $SKEEN_NAME created successfully"
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
  curl -kfsS -X POST \
    -H "Content-Type: application/json" \
    -d "${2:-{}}" \
    "${RCI}/${1:-}" 2>/dev/null || echo ""
}

loading_config() {
  if [ ! -f "$SKEEN_CONFIG" ]; then
    create_skeen_config
  fi

  eval "$(
    jsonfilter -i "$SKEEN_CONFIG" \
      -e AUTO_START_ENABLE='@.auto_start.enable' \
      -e AUTO_START_DELAY='@.auto_start.delay' \
      -e POLICY_ENABLE='@.policy.enable' \
      -e POLICY_NAME='@.policy.name' \
      -e NETWORK_IPV6='@.network.ipv6' \
      -e NETWORK_TUNING='@.network.tuning' \
      -e SING_CONFIG_ENABLE='@.sing_config.enable' \
      -e SING_CONFIG_PATH='@.sing_config.path' \
      -e SING_CONFIG_SYNC_URL='@.sing_config.sync_url' \
      -e SERVICE_PROXY_ENABLE='@.service_proxy.enable' \
      -e SERVICE_PROXY_PORT='@.service_proxy.port' \
      -e SERVICE_PROXY_USER='@.service_proxy.user' \
      -e SERVICE_PROXY_PASS='@.service_proxy.pass' \
      -e FIREWALL_INTERCEPT_DNS='@.firewall.intercept.dns' \
      -e FIREWALL_REDIRECT_DNS_ENABLE='@.firewall.redirect_dns.enable' \
      -e FIREWALL_REDIRECT_DNS_PORT='@.firewall.redirect_dns.to_port' \
      -e FIREWALL_REDIRECT_DNS_USE_POLICY='@.firewall.redirect_dns.use_policy'
  )"

  : "${AUTO_START_ENABLE:=1}"
  : "${AUTO_START_DELAY:=0}"
  : "${POLICY_ENABLE:=1}"
  : "${POLICY_NAME:=SKeen}"
  : "${NETWORK_IPV6:=1}"
  : "${NETWORK_TUNING:=0}"
  : "${SING_CONFIG_ENABLE:=0}"
  : "${SING_CONFIG_PATH:=/opt/etc/skeen/config.json}"
  : "${SING_CONFIG_SYNC_URL:=}"
  : "${SERVICE_PROXY_ENABLE:=0}"
  : "${SERVICE_PROXY_PORT:=}"
  : "${SERVICE_PROXY_USER:=}"
  : "${SERVICE_PROXY_PASS:=}"
  : "${FIREWALL_INTERCEPT_DNS:=1}"
  : "${FIREWALL_REDIRECT_DNS_ENABLE:=0}"
  : "${FIREWALL_REDIRECT_DNS_PORT:=}"
  : "${FIREWALL_REDIRECT_DNS_USE_POLICY:=1}"

  if [ "$SING_CONFIG_ENABLE" = "1" ]; then
    SINGBOX_ARGS="run -D $WORK_DIR -c $SING_CONFIG_PATH"
  fi
}

load_proxy_options() {
  local err_template

  [ "$CALLER" != "menu" ] && loading_config

  CURL_PROXY_OPTIONS="--connect-timeout 5 --max-time 720"
  if [ "$SERVICE_PROXY_ENABLE" = "1" ]; then
    err_template="Service proxy is enabled but"
    if [ -z "$SERVICE_PROXY_PORT" ]; then
      exiterr "$err_template 'service_proxy.port' is not set"
    elif ! is_running; then
      exiterr "$err_template $SINGBOX_NAME is not running"
    elif ! netstat -tuln 2>/dev/null | grep -q ":${SERVICE_PROXY_PORT}"; then
      exiterr "$err_template no process is listening on port ${SERVICE_PROXY_PORT}"
    else
      CURL_PROXY_OPTIONS="${CURL_PROXY_OPTIONS} --socks5-hostname 127.0.0.1:${SERVICE_PROXY_PORT}"
      if [ -n "$SERVICE_PROXY_USER" ] && [ -n "$SERVICE_PROXY_PASS" ]; then
        CURL_PROXY_OPTIONS="${CURL_PROXY_OPTIONS} --proxy-user ${SERVICE_PROXY_USER}:${SERVICE_PROXY_PASS}"
      fi
    fi
  else
    SING_CONFIG_SYNC_URL=""
  fi
}

get_current_version() {
  local proc="${1:-}"

  case "$proc" in
  "$SINGBOX_PROC")
    if [ -f "$SINGBOX_BIN" ]; then
      $SINGBOX_BIN version | awk 'NR==1 {print $3}' | xargs
    fi
    ;;
  "$SKEEN_PROC") echo "$SKEEN_VERSION" ;;
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

  [ -z "$ARCH" ] && exiterr "Unsupported CPU architecture"

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
  local version="${1:-}"
  local pkg_url

  if [ -z "$version" ]; then
    echomsg "Fetching the latest version..."
    version="$(get_latest_version "$SINGBOX_API_URL")"
    [ -z "$version" ] && echoerr "Failed to fetch the latest version" && exit 1

    echook "Latest version is $version"
  fi

  PKG_NAME="sing-box_${version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
  pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${version}/${PKG_NAME}"

  echomsg "Downloading ${PKG_NAME}..."

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR" || exit 1

  # shellcheck disable=SC2086
  if curl $CURL_PROXY_OPTIONS --fail -Lo "$PKG_NAME" "$pkg_url"; then
    echook "Downloaded $PKG_NAME successfully"
  else
    echoerr "Failed to download $PKG_NAME"
    [ -n "$version" ] && return 1 || exit 1
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

  echomsg "Installing $SINGBOX_NAME binary to $SINGBOX_BIN"
  [ -f "$SINGBOX_BIN" ] && rm -f "$SINGBOX_BIN"
  mv ./usr/bin/sing-box "$SINGBOX_BIN"
  chmod 755 "$SINGBOX_BIN"
  chmod +x "$SINGBOX_BIN"

  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${PKG_NAME}"

  echook "$SINGBOX_NAME binary installed successfully"
}

create_singbox_config() {
  local act="${1:-}"
  local key
  local value

  if [ "$act" != "force" ] && [ -d "$CONFIG_DIR" ] &&
    ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
    echomsg "Found configuration folder ${CONFIG_DIR}, skipping creation"
    return
  elif [ ! -d "$CONFIG_DIR" ] && [ -f "$SKEEN_CONFIG" ]; then
    get_sing_args_config
    if [ "$SING_CONFIG_ENABLE" = "1" ] && [ ! -f "$SING_CONFIG_PATH" ]; then
      echowarn "Configuration files for $SINGBOX_NAME not found"
    else
      echomsg "Configuration file $SINGBOX_NAME found, skipping creation"
      return
    fi
  fi

  echomsg "Creating $SINGBOX_NAME configuration files..."

  mkdir -p "$CONFIG_DIR"

  config_json='{"log":{"disabled":false,"level":"debug","output":"","timestamp":false},"dns":{"servers":[{"type":"tls","tag":"dns-proxy","detour":"proxy","domain_resolver":"dns-resolver","server":"one.one.one.one"},{"type":"https","tag":"dns-direct","domain_resolver":"dns-resolver","server":"common.dot.dns.yandex.net"},{"type":"udp","tag":"dns-resolver","server":"77.88.8.8"}],"rules":[{"rule_set":"adguard","action":"reject"},{"clash_mode":"Direct","server":"dns-direct"},{"clash_mode":"Global","server":"dns-proxy"},{"rule_set":"geosite-category-ru","server":"dns-direct"}],"final":"dns-proxy","strategy":"ipv4_only"},"inbounds":[{"type":"redirect","tag":"redirect-in","listen":"::","listen_port":65081,"tcp_fast_open":true},{"type":"tproxy","tag":"tproxy-in","listen":"::","listen_port":65082,"udp_timeout":"3m0s","udp_fragment":true,"network":"udp"}],"outbounds":[{"tag":"proxy","type":"selector","default":"auto","interrupt_exist_connections":true,"outbounds":["direct","auto","vless-out","naive-out"]},{"tag":"direct","type":"direct"},{"tag":"auto","type":"urltest","url":"http://www.gstatic.com/generate_204","interval":"5m","tolerance":100,"interrupt_exist_connections":true,"outbounds":["vless-out","naive-out"]},{"tag":"vless-out","type":"vless","uuid":"00000000-0000-0000-0000-00000000000","flow":"xtls-rprx-vision","packet_encoding":"xudp","server":"example.com","server_port":443,"tls":{"enabled":true,"server_name":"example.com","utls":{"enabled":true,"fingerprint":"firefox"}}},{"tag":"naive-out","type":"naive","username":"jinndi","password":"mypass","quic":true,"quic_congestion_control":"bbr","server":"example.com","server_port":10443,"tls":{"enabled":true,"server_name":"example.com"}}],"route":{"final":"proxy","auto_detect_interface":true,"default_domain_resolver":"dns-resolver","rules":[{"action":"sniff"},{"type":"logical","mode":"or","rules":[{"protocol":"dns"},{"port":53}],"action":"hijack-dns"},{"ip_is_private":true,"outbound":"direct"},{"clash_mode":"Direct","outbound":"direct"},{"clash_mode":"Global","outbound":"proxy"},{"protocol":"bittorrent","outbound":"direct"},{"rule_set":["geosite-category-ru","geoip-ru"],"outbound":"direct"}],"rule_set":[{"type":"remote","tag":"adguard","url":"https://github.com/jinndi/adguard-filter-list-srs/releases/latest/download/adguard-filter-list.srs","download_detour":"direct"},{"tag":"geoip-ru","type":"remote","url":"https://github.com/KaringX/karing-ruleset/raw/sing/geo/geoip/ru.srs","download_detour":"direct"},{"tag":"geosite-category-ru","type":"remote","url":"https://github.com/KaringX/karing-ruleset/raw/sing/geo/geosite/category-ru.srs","download_detour":"direct"}]},"experimental":{"clash_api":{"external_controller":"0.0.0.0:9999","external_ui":"zashboard","external_ui_download_url":"https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip","external_ui_download_detour":"direct","default_mode":"rule"},"cache_file":{"enabled":true,"path":"cache.db","store_fakeip":true,"store_rdrc":true}}}'

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

  echook "Configuration files $SINGBOX_NAME created successfully"
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
  local backup_script="${SKEEN_SCRIPT}.backup"

  echomsg "Downloading $SKEEN_NAME script at $SKEEN_SCRIPT"

  [ -f "$SKEEN_SCRIPT" ] && mv "$SKEEN_SCRIPT" "$backup_script"

  # shellcheck disable=SC2086
  if ! curl $CURL_PROXY_OPTIONS --fail -Lo "$SKEEN_SCRIPT" "$SKEEN_SCRIPT_URL"; then
    rm -f "$SKEEN_SCRIPT"
    [ -f "$backup_script" ] && mv "$backup_script" "$SKEEN_SCRIPT"
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
  pidof "$SINGBOX_PROC" >/dev/null 2>&1
}

install() {
  check_free_space
  get_os_release
  get_architecture
  install_dependencies
  download_singbox
  install_singbox
  create_singbox_config
  create_autostart_script
  create_skeen_group
  download_skeen_script
  create_skeen_config

  "$SINGBOX_BIN" version

  if [ "$SING_CONFIG_ENABLE" != "1" ] && [ -d "$CONFIG_DIR" ]; then
    echomsg "Configure $SINGBOX_NAME by editing: $CONFIG_DIR"
  fi

  echomsg "Configure $SKEEN_NAME by editing: $SKEEN_CONFIG"

  echook "Installation completed"

  press_any_key_to_menu
}

uninstall() {
  echomsg "Uninstalling ${SKEEN_NAME}..."

  is_running && stop

  echomsg "Removing $SINGBOX_NAME binary..."
  rm -f "$SINGBOX_BIN"

  echomsg "Removing auto-start script..."
  rm -f "$SKEEN_AUTOSTART_SCRIPT"

  echomsg "Removing firewall hook script..."
  rm -f "$FIREWALL_HOOK_FILE"

  echomsg "Removing $SKEEN_NAME script..."
  rm -f "$SKEEN_SCRIPT"

  echomsg "Delete group ${SKEEN_PROC}..."
  delgroup "$SKEEN_PROC"

  if [ -d "$WORK_DIR" ]; then
    echomsg "Configuration directory $WORK_DIR is retained"
    echomsg "If you want to remove it manually, run: rm -rf $WORK_DIR"
  fi
  echook "${SKEEN_NAME} has been uninstalled successfully"
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

  if [ -z "$port" ] && iptables -t mangle -nvL INPUT --line-numbers | grep -q 'tcp dpt:443'; then
    msg_err="HTTPS Port 443 is in use by Keenetic services."
    echoerr "$msg_err"
    logger_error "$msg_err"
    echoerr "TProxy requires a free port to work."
    echoerr "Please free it on the 'Users and Access' page of the router web interface"
    press_any_key_to_menu "" 1
  elif [ -n "$port" ]; then
    if netstat -lnt 2>/dev/null | grep -q ":$port\s"; then
      msg_err="Port $port is in use. Free it and try running again"
      echoerr "$msg_err"
      logger_error "$msg_err"
      press_any_key_to_menu "" 1
    fi
  fi

  return 0
}

is_owner_module_working() {
  [ -d "/sys/module/xt_owner" ] && return 0

  iptables -w -t mangle -A OUTPUT -m owner --gid-owner 65534 -j RETURN >/dev/null 2>&1 && \
  { iptables -w -t mangle -D OUTPUT -m owner --gid-owner 65534 >/dev/null 2>&1; return 0; }

  return 1
}

load_module() {
  local module="${1:-}"
  local modname="${module%.ko}"

  [ -d "/sys/module/$modname" ] && return 0

  local path_os="${MODULES_OS_DIR}/${module}"
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

  echoerr "Module '$module' not found or failed to load"
  return 1
}

loading_modules() {
  local modules="${1:-xt_TPROXY.ko xt_socket.ko xt_multiport.ko xt_owner.ko xt_comment.ko}"
  local err_msg="Please install router component: «Kernel modules for Netfilter»"
  local kernel_ver

  kernel_ver="$(uname -r)"
  MODULES_OS_DIR="${MODULES_OS_DIR}/${kernel_ver}"

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
      echowarn "IPv6 enabled in ${SKEEN_NAME}, but no IPv6 connectivity detected" >&2
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
    json_policy="$(rci show/ip/policy)"

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

set_route_rules() {
  check_default_route() {
    local target="1.1.1.1"
    [ "$IP_VERSION" = "6" ] && target="2606:4700:4700::1111"

    if [ "$IP_VERSION" = "6" ] && ! ip -6 route show default 2>/dev/null | grep -q .; then
      return 0
    fi

    if [ -n "$SKEEN_MARK_POLICY" ]; then
      ip -"$IP_VERSION" route get "$target" mark "$SKEEN_MARK_POLICY" 2>/dev/null | grep -Eq "via|dev"
    else
      ip -"$IP_VERSION" route get "$target" 2>/dev/null | grep -Eq "via|dev"
    fi
  }

  if ! check_default_route; then
    [ -f "$WAIT_ROUTE_FILE" ] || touch "$WAIT_ROUTE_FILE"

    local msg="Check your internet connection"
    [ -n "$SKEEN_MARK_POLICY" ] && msg="$msg for policy ${SKEEN_POLICY_NAME:-unknown}"

    echoerr "$msg"
    logger_warning "$msg"

    [ "$CALLER" = "netfilter" ] && exit 0

    press_any_key_to_menu "" 1; return 1
  fi

  [ "$SKEEN_FIREWALL_MODE" = "redirect" ] && return 0

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
  local msg_err="Invalid ${label} port:"
  local valid_ports=""
  local invalid_ports=""
  local ports
  local p
  local start
  local end

  msg_err="Invalid ${label} port:"
  valid_ports=""
  invalid_ports=""

  ports="$(printf '%s\n' "$input" | tr ', ' '\n' | sed '/^$/d')"

  for p in $ports; do
    case "$p" in
    *:*)
      start="${p%%:*}"
      end="${p##*:}"
      ;;
    *)
      start="$p"
      end="$p"
      ;;
    esac

    case "$start$end" in
    *[!0-9]* | '')
      invalid_ports="${invalid_ports:+$invalid_ports }$p"
      continue
      ;;
    esac

    if [ "$start" -lt 1 ] || [ "$end" -gt 65535 ] || [ "$start" -gt "$end" ]; then
      invalid_ports="${invalid_ports:+$invalid_ports }$p"
      continue
    fi

    valid_ports="${valid_ports:+$valid_ports }$p"
  done

  if [ -n "$invalid_ports" ]; then
    logger_warning "$msg_err $invalid_ports"
    is_tty && echowarn "$msg_err $invalid_ports"
  fi

  printf '%s' "$valid_ports"
}

get_eth_subnet() {
  local _ip_v="${1:-}"
  local addresses
  local prefix_length="32"
  local address
  local eth_ip

  [ "$_ip_v" = "6" ] && prefix_length="128"

  addresses="$(get_net_check_hosts "$_ip_v")"

  for address in $addresses; do
    eth_ip="$(ip -"$_ip_v" route get "$address" 2>/dev/null |
      awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
    [ -n "$eth_ip" ] && echo "${eth_ip}/${prefix_length}" && break
  done
}

get_exclude_addresses() {
  local ip_v="${1:-}"
  local eth_subnet
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

  all_list="$(get_eth_subnet "$ip_v")"

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
  # shellcheck disable=SC2068
  $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
}

apply_port_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local ports="${4:-}"
  local protos="${5:-}"
  local action="${6:-}"
  local proto chunk

  # shellcheck disable=SC2086
  set -- $ports

  while [ $# -gt 0 ]; do
    chunk=""
    local i=0

    while [ $i -lt 7 ] && [ $# -gt 0 ]; do
      chunk="${chunk}${chunk:+,}$1"
      shift
      i=$((i + 1))
    done

    for proto in $protos; do
      # shellcheck disable=SC2086
      add_rule "$iptables" "$table" "$chain" -p "$proto" -m multiport --dports "$chunk" $action
    done
  done
}

add_skeen_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"
  local ports="${4:-}"
  local type="${5:-}"
  local protos rule

  case "$type" in
  "exclude")
    protos="$SKEEN_FIREWALL_NETWORK"
    [ -n "$ports" ] && apply_port_rules "$iptables" "$table" "$chain" "$ports" "$protos" "-j ACCEPT"
    add_rule "$iptables" "$table" "$chain" -m set --match-set "${BYPASS_NET_SET}${IP_VERSION}" dst -j ACCEPT
    ;;
  "tproxy")
    protos="$SKEEN_TPROXY_NETWORK"
    rule="-j TPROXY --on-ip $PROXY_IP --on-port $SKEEN_TPROXY_PORT --tproxy-mark $TABLE_MARK"

    add_rule "$iptables" "$table" "$chain" -p tcp -m socket --transparent -j MARK --set-mark "$TABLE_MARK"
    add_rule "$iptables" "$table" "$chain" -p tcp -m socket --transparent -j ACCEPT

    if [ -z "$ports" ]; then
      # shellcheck disable=SC2086
      for p in $protos; do add_rule "$iptables" "$table" "$chain" -p "$p" $rule; done
    else
      apply_port_rules "$iptables" "$table" "$chain" "$ports" "$protos" "$rule"
    fi
    ;;
  "redirect")
      protos="tcp"
      rule="-j REDIRECT --to-port $SKEEN_REDIRECT_PORT"

      if [ -z "$ports" ]; then
        # shellcheck disable=SC2086
        add_rule "$iptables" "$table" "$chain" -p tcp $rule
      else
        apply_port_rules "$iptables" "$table" "$chain" "$ports" "$protos" "$rule"
      fi
      ;;
  esac
}

set_chain_rules() {
  local iptables="${1:-}"
  local table="${2:-}"
  local chain="${3:-}"

  $iptables -t "$table" -nL "$chain" >/dev/null 2>&1 && return 0
  $iptables -t "$table" -N "$chain" || return 0

  case "$chain" in
  "$CHAIN_PREROUTING")
    if [ "$table" = "mangle" ]; then
      for proto in $SKEEN_TPROXY_NETWORK; do
        if [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ]; then
          add_rule "$iptables" "$table" "$chain" \
            -p "$proto" --dport "$DNS_PORT" -j TPROXY --on-ip "$PROXY_IP" \
            --on-port "$SKEEN_TPROXY_PORT" --tproxy-mark "$TABLE_MARK"
        else
          add_rule "$iptables" "$table" "$chain" -p "$proto" --dport "$DNS_PORT" -j ACCEPT
        fi
      done

      add_skeen_rules "$iptables" "$table" "$chain" "$SKEEN_EXCLUDE_PORTS" "exclude"
      add_skeen_rules "$iptables" "$table" "$chain" "$SKEEN_INTERCEPT_PORTS" "tproxy"
    else
      add_skeen_rules "$iptables" "$table" "$chain" "$SKEEN_EXCLUDE_PORTS" "exclude"
      add_skeen_rules "$iptables" "$table" "$chain" "$SKEEN_INTERCEPT_PORTS" "redirect"
    fi
    ;;

  "$CHAIN_OUTPUT")
    add_skeen_rules "$iptables" "$table" "$chain" "$SKEEN_EXCLUDE_PORTS" "exclude"
    for proto in $SKEEN_TPROXY_NETWORK; do
      add_rule "$iptables" "$table" "$chain" -p "$proto" -j CONNMARK --set-mark "$TABLE_MARK"
    done
    ;;
  esac
}

set_prerouting_rule() {
  local iptables="${1:-}"
  local table="${2:-}"
  local connmark_option

  [ -n "$SKEEN_MARK_POLICY" ] &&
    connmark_option="-m connmark --mark $SKEEN_MARK_POLICY"

  local rule="PREROUTING \
    $connmark_option \
    -m conntrack ! --ctstate INVALID \
    -j $CHAIN_PREROUTING"

  # shellcheck disable=SC2086
  if ! $iptables -t "$table" -C $rule >/dev/null 2>&1; then
    $iptables -t "$table" -A $rule >/dev/null 2>&1
  fi
}

set_output_rule() {
  local iptables="$1"
  local table="$2"
  local proto

  case "$SKEEN_FIREWALL_MODE" in
  tproxy) proto='! -p icmp' ;;
  hybrid) proto='-p udp' ;;
  *) return 0 ;;
  esac

  local rule="-m owner ! --gid-owner $SKEEN_PROC \
    -m conntrack ! --ctstate INVALID $proto -j $CHAIN_OUTPUT"

  # shellcheck disable=SC2086
  if ! $iptables -t "$table" -C OUTPUT $rule >/dev/null 2>&1; then
    $iptables -t "$table" -I OUTPUT $rule >/dev/null 2>&1
  fi
}

release_version_ge5() {
  local major

  check_tty
  major=$(ndmc -c show version | awk -F'[:.]' '/release:/ {gsub(/ /,"",$2); print $2}')
  if [ "$major" -lt 5 ]; then
    echoerr "Release version KeeneticOS is lower than 5" && return 1
  fi
}

tun_create() {
  local opkgtun_ip="${1:-}"
  local opkgtun_desc="${2:-}"
  local opkgtun_name="OpkgTun0"
  local inface_list
  local opkgtun_ids
  local opkgtun_name_lower

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
  local opkgtun_desc="${1:-8888}"
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
  opkgtun_list="$(
    ndmc -c show interface | awk '/^Interface, name = "OpkgTun/ { print_block=1 }
      print_block { print }
      /^Interface, name =/ && $0 !~ /^Interface, name = "OpkgTun/ { print_block=0 }'
  )"
  [ -z "$opkgtun_list" ] && echomsg "No OpkgTun interfaces found" || echo "$opkgtun_list"
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
  apply_rule nat POSTROUTING -o opkgtun+ -j MASQUERADE
}

prepare_firewall() {
  local complete_msg
  local redirect_data
  local tproxy_data
  local has_opkgtun
  local route_all
  local intercept_ports
  local exclude_ports

  echomsg "Preparing a firewall:"

  complete_msg="Firewall preparation is complete"

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

  [ "$SKEEN_FIREWALL_MODE" = "tproxy" ] && check_port

  SKEEN_INTERCEPT_DNS_ENABLE="0"
  SKEEN_REDIRECT_DNS_ENABLE="0"
  SKEEN_REDIRECT_DNS_PORT=""

  if has_dns_servers; then
    local msg_dns_detect=" - Detected DNS configuration:"
    if [ "$FIREWALL_REDIRECT_DNS_ENABLE" = "1" ]; then
      if [ -z "$FIREWALL_REDIRECT_DNS_PORT" ]; then
        echoerr "DNS redirect enabled, but port is missing in $SKEEN_NAME config"
        press_any_key_to_menu "" 1
      fi
      check_port "$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_ENABLE="1"
      SKEEN_REDIRECT_DNS_PORT="$FIREWALL_REDIRECT_DNS_PORT"
      SKEEN_REDIRECT_DNS_USE_POLICY="$FIREWALL_REDIRECT_DNS_USE_POLICY"
      cyan "$msg_dns_detect redirect"
    fi

    if [ "$FIREWALL_REDIRECT_DNS_ENABLE" = "1" ] && [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      echowarn "DNS redirect/intercept conflict: using redirect only"
    elif [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
      case "$SKEEN_FIREWALL_MODE" in
      tproxy | hybrid)
        SKEEN_INTERCEPT_DNS_ENABLE="1"
        cyan "$msg_dns_detect intercept"
      ;;
      *) echowarn "DNS intercept does not work in '$SKEEN_FIREWALL_MODE' mode" ;;
      esac
    fi
  elif [ "$FIREWALL_REDIRECT_DNS_ENABLE" = "1" ] || [ "$FIREWALL_INTERCEPT_DNS" = "1" ]; then
    echowarn "DNS settings provided in ${SKEEN_NAME}, but $SINGBOX_NAME is not configured"
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ] || {
      [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ] &&
      [ "$SKEEN_FIREWALL_MODE" = "none" ]
  }; then
    {
      echo "#!/bin/sh"
      echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"

      local tables="nat|filter"
      if [ "$SKEEN_FIREWALL_MODE" = "none" ]; then
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

      if [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
        loading_modules xt_comment.ko
        [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] &&
          SKEEN_MARK_POLICY="$(get_mark_policy)"
        echo "export SKEEN_REDIRECT_DNS_ENABLE=\"$SKEEN_REDIRECT_DNS_ENABLE\""
        echo "export SKEEN_REDIRECT_DNS_PORT=\"$SKEEN_REDIRECT_DNS_PORT\""
        echo "export SKEEN_REDIRECT_DNS_USE_POLICY=\"$SKEEN_REDIRECT_DNS_USE_POLICY\""
        echo "export SKEEN_MARK_POLICY=\"${SKEEN_MARK_POLICY:-}\""
      fi

      echo "$SKEEN_PROC apply_firewall netfilter"
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
  if [ "$POLICY_ENABLE" != "1" ]; then
    cyan " - Policy disabled on skeen.json"
  elif [ -z "$POLICY_NAME" ]; then
    cyan " - Policy name not set"
  elif [ -z "$SKEEN_MARK_POLICY" ]; then
    cyan " - Policy $POLICY_NAME not found"
  else
    cyan " - Routing for the $POLICY_NAME policy"
    route_all=0
  fi
  [ "$route_all" = 1 ] && echowarn "Routing for the entire device"

  SKEEN_IPTABLES_LIST="$(get_iptables_list)"

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "No supported iptables found for the firewall mode?"
    press_any_key_to_menu "" 1
  fi

  SKEEN_INTERCEPT_PORTS=""
  SKEEN_EXCLUDE_PORTS=""
  intercept_ports="$(get_validate_ports "intercept" "$(json_get_array '@.firewall.intercept.port')")"
  if [ -n "$intercept_ports" ]; then
    SKEEN_INTERCEPT_PORTS="$intercept_ports"
  else
    exclude_ports="$(get_validate_ports "exclude" "$(json_get_array '@.firewall.exclude.port')")"
    [ -n "$exclude_ports" ] && SKEEN_EXCLUDE_PORTS="$exclude_ports"
  fi

  setup_bypass_ipset() {
    local ipver="$1"
    local family="$2"
    local name_set="${BYPASS_NET_SET}${ipver}"

    ipset create "$name_set" hash:net family "$family" -exist
    ipset flush "$name_set"

    get_exclude_addresses "$ipver" | tr ' ' '\n' | while read -r addr; do
      [ -z "$addr" ] && continue
      ipset add "$name_set" "$addr" -exist
    done
  }

  if echo "$SKEEN_IPTABLES_LIST" | grep -q "iptables"; then
    setup_bypass_ipset 4 inet
  fi

  if echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6tables"; then
    setup_bypass_ipset 6 inet6
  fi

  [ -f "$FIREWALL_HOOK_FILE" ] && rm -f "$FIREWALL_HOOK_FILE"

  {
    echo "#!/bin/sh"
    echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"

    echo "echo \"$SKEEN_IPTABLES_LIST\" | grep -q \"\$type\" || exit 0"

    local tun=""
    [ $SKEEN_TUN_ENABLED = "1" ] && tun="|filter"
    [ $SKEEN_FIREWALL_MODE = "tproxy" ] && tun="|filter|nat"
    local redirect="${TABLE_REDIRECT}${tun}"
    local hybrid="${TABLE_REDIRECT}|${TABLE_TPROXY}${tun}"
    local tproxy="${TABLE_TPROXY}${tun}"

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
    echo "export SKEEN_POLICY_NAME=\"$POLICY_NAME\""
    echo "export SKEEN_MARK_POLICY=\"$SKEEN_MARK_POLICY\""
    echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""
    echo "export SKEEN_INTERCEPT_PORTS=\"$SKEEN_INTERCEPT_PORTS\""
    echo "export SKEEN_EXCLUDE_PORTS=\"$SKEEN_EXCLUDE_PORTS\""
    echo "export SKEEN_INTERCEPT_DNS_ENABLE=\"$SKEEN_INTERCEPT_DNS_ENABLE\""
    echo "export SKEEN_REDIRECT_DNS_ENABLE=\"$SKEEN_REDIRECT_DNS_ENABLE\""
    echo "export SKEEN_REDIRECT_DNS_PORT=\"$SKEEN_REDIRECT_DNS_PORT\""
    echo "export SKEEN_TUN_ENABLED=\"$SKEEN_TUN_ENABLED\""

    echo "$SKEEN_PROC apply_firewall netfilter"
  } >"$FIREWALL_HOOK_FILE"

  chmod +x "$FIREWALL_HOOK_FILE"

  echook "$complete_msg"
}

apply_firewall() {
  local check iptables eth_subnet set_name

  check=$(echo "$SKEEN_IPTABLES_LIST" | sed 's/iptables//g; s/ip6tables//g; s/ //g')
  if [ -n "$check" ] || [ -z "$SKEEN_IPTABLES_LIST" ]; then
    local msg_err="Неизвестный iptables: ${iptables:-unknown}"
    logger_error "$msg_err"
    echoerr "$msg_err"
    press_any_key_to_menu "" 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" != "none" ] || [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
    echomsg "Applying firewall rules..."
  fi

  if [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
    local mark_option=""
    [ "$SKEEN_REDIRECT_DNS_USE_POLICY" = "1" ] && [ -n "$SKEEN_MARK_POLICY" ] &&
      mark_option="-m mark --mark $SKEEN_MARK_POLICY"

    for iptables in $SKEEN_IPTABLES_LIST; do
      for net in udp tcp; do
        local args="$CHAIN_DNS -p $net -i br+ $mark_option -m pkttype --pkt-type unicast \
          --dport 53 -j REDIRECT --to-ports $SKEEN_REDIRECT_DNS_PORT -m comment --comment skeen_dns"

        # shellcheck disable=SC2086
        if ! $iptables -t nat -C $args >/dev/null 2>&1; then
          $iptables -t nat -I $args
        fi
      done
    done
  fi

  [ "$SKEEN_FIREWALL_MODE" = "none" ] && return 0
  [ "$SKEEN_TUN_ENABLED" = "1" ] && set_tun_rules
  [ "$SKEEN_FIREWALL_MODE" = "tun" ] && return 0

  for iptables in $SKEEN_IPTABLES_LIST; do
    if [ "$iptables" = "iptables" ]; then
      IP_VERSION="4"
      PROXY_IP="127.0.0.1"
    elif [ "$iptables" = "ip6tables" ]; then
      IP_VERSION="6"
      PROXY_IP="::1"
    fi

    set_route_rules

    if [ -f "$WAIT_ROUTE_FILE" ]; then
      eth_subnet="$(get_eth_subnet "$IP_VERSION")"
      set_name="${BYPASS_NET_SET}${IP_VERSION}"
      ipset add "$set_name" "$eth_subnet" -exist
    fi

    if [ "$SKEEN_FIREWALL_MODE" = "hybrid" ]; then
      for table in "$TABLE_TPROXY" "$TABLE_REDIRECT"; do
        set_chain_rules "$iptables" "$table" "$CHAIN_PREROUTING"
        set_prerouting_rule "$iptables" "$table"
      done
    elif [ "$SKEEN_FIREWALL_MODE" = "tproxy" ]; then
      set_chain_rules "$iptables" "$TABLE_TPROXY" "$CHAIN_PREROUTING"
      set_prerouting_rule "$iptables" "$TABLE_TPROXY"
    elif [ "$SKEEN_FIREWALL_MODE" = "redirect" ]; then
      set_chain_rules "$iptables" "$TABLE_REDIRECT" "$CHAIN_PREROUTING"
      set_prerouting_rule "$iptables" "$TABLE_REDIRECT"
    fi

    if [ "$SKEEN_FIREWALL_MODE" != "redirect" ]; then
      set_chain_rules "$iptables" "$TABLE_TPROXY" "$CHAIN_OUTPUT"
      add_output_rule "$iptables" "$TABLE_TPROXY"
    fi
  done

  [ -f "$WAIT_ROUTE_FILE" ] && rm -f "$WAIT_ROUTE_FILE"

  echook "Firewall rules applied successfully"
}

clean_firewall() {
  echomsg "Cleaning firewall rules..."

  # 1. tun cleanup
  while iptables -t nat -D POSTROUTING -o opkgtun+ -j MASQUERADE 2>/dev/null; do :; done
  iptables -D INPUT -i opkgtun+ -j "$CHAIN_TUN" 2>/dev/null
  iptables -F "$CHAIN_TUN" 2>/dev/null
  iptables -X "$CHAIN_TUN" 2>/dev/null

  # 2. remove chains
  clean_chain() {
    local iptables="$1"
    local table="$2"
    local chain="$3"
    local parent="$4"
    local ip_ver set_name

    if ! $iptables -t "$table" -nL "$chain" >/dev/null 2>&1; then
      return 0
    fi

    $iptables -w -t "$table" -F "$chain" >/dev/null 2>&1

    while :; do
      rule_num=$(
        $iptables -w -t "$table" -nL "$parent" --line-numbers 2>/dev/null |
          awk -v ch="$chain" '$0 ~ ch {print $1; exit}'
      )
      [ -z "$rule_num" ] && break
      $iptables -w -t "$table" -D "$parent" "$rule_num" >/dev/null 2>&1
    done

    $iptables -w -t "$table" -X "$chain" >/dev/null 2>&1
  }

  for ipt_cmd in iptables ip6tables; do
    $ipt_cmd -w -t nat -S $CHAIN_DNS 2>/dev/null | \
    sed -n "s/^-A /${ipt_cmd} -w -t nat -D /p" | grep "skeen_dns" | sh

    clean_chain "$ipt_cmd" nat "$CHAIN_PREROUTING" PREROUTING
    clean_chain "$ipt_cmd" mangle "$CHAIN_PREROUTING" PREROUTING
    clean_chain "$ipt_cmd" mangle "$CHAIN_OUTPUT" OUTPUT
  done

  # 3. routing cleanup
  ip -4 rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" 2>/dev/null
  ip -6 rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" 2>/dev/null
  ip route flush table "$TABLE_ID" 2>/dev/null

  # 4. ipset cleanup
  if command -v ipset >/dev/null 2>&1; then
    for ip_ver in 4 6; do
      set_name="${BYPASS_NET_SET}${ip_ver}"
      ipset flush "$set_name" 2>/dev/null
      ipset destroy "$set_name" 2>/dev/null
    done
  fi

  # 5. cleanup hook
  rm -f "$FIREWALL_HOOK_FILE" 2>/dev/null

  echook "Firewall cleanup completed"
}

apply_sysctl_network_tuning() {
  {
    # IPv4 Forwarding & TProxy Support
    sysctl -w net.ipv4.ip_forward=1                  # Enable IPv4 routing
    sysctl -w net.ipv4.conf.all.src_valid_mark=0     # Accept TProxy marked packets
    sysctl -w net.ipv4.conf.lo.route_localnet=1      # Allow lo local routing (TProxy)
    sysctl -w net.ipv4.conf.all.send_redirects=0     # Disable ICMP redirects globally
    sysctl -w net.ipv4.conf.default.send_redirects=0 # Disable ICMP redirects by default
    sysctl -w net.ipv4.conf.all.route_localnet=1     # Allow TPROXY to route packets via 127.0.0.1
    sysctl -w net.ipv4.ip_nonlocal_bind=1            # Allow processes to bind to any IP

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

    # Network Buffers (TCP/UDP)
    sysctl -w net.core.rmem_max=6291456    # Max TCP/UDP receive buffer
    sysctl -w net.core.wmem_max=6291456    # Max TCP/UDP send buffer
    sysctl -w net.core.rmem_default=229376 # Default receive buffer
    sysctl -w net.core.wmem_default=229376 # Default send buffer

    # Interface Queues
    sysctl -w net.core.netdev_max_backlog=4096 # Max packets queued on interface
    sysctl -w net.core.somaxconn=512           # Max pending TCP connections

    # Connection Tracking
    sysctl -w net.netfilter.nf_conntrack_max=50000                   # Max tracked connections
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=600 # TCP established timeout
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=60              # UDP timeout without data
    sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=180      # UDP timeout with data
    sysctl -w net.netfilter.nf_conntrack_checksum=0                  # Skip checksum validation

    # TCP/UDP Memory & Buffers
    sysctl -w net.ipv4.tcp_moderate_rcvbuf=1         # autotuning
    sysctl -w net.ipv4.tcp_mem="8192 16384 32768"    # TCP memory thresholds
    sysctl -w net.ipv4.udp_mem="8192 16384 32768"    # UDP memory thresholds
    sysctl -w net.ipv4.tcp_rmem="4096 87380 6291456" # TCP per-socket read buffer min/def/max
    sysctl -w net.ipv4.tcp_wmem="4096 65536 6291456" # TCP per-socket write buffer min/def/max
    sysctl -w net.ipv4.udp_rmem_min=16384            # Min UDP receive buffer
    sysctl -w net.ipv4.udp_wmem_min=16384            # Min UDP send buffer
    sysctl -w net.ipv4.tcp_limit_output_bytes=262144 # Limit per-socket output burst

    # TCP Behavior / Optimizations
    sysctl -w net.ipv4.tcp_syncookies=1        # Enable SYN cookies (SYN flood protection)
    sysctl -w net.ipv4.tcp_tw_reuse=1          # Allow reuse of TIME_WAIT sockets
    sysctl -w net.ipv4.tcp_fin_timeout=15      # Shorten FIN timeout
    sysctl -w net.ipv4.tcp_keepalive_time=600  # TCP keepalive interval
    sysctl -w net.ipv4.tcp_keepalive_probes=5  # Keepalive probes count
    sysctl -w net.ipv4.tcp_keepalive_intvl=10  # Keepalive interval between probes
    sysctl -w net.ipv4.tcp_timestamps=0        # Disable TCP timestamps for performance
    sysctl -w net.ipv4.tcp_sack=1              # Enable selective ACKs
    sysctl -w net.ipv4.tcp_max_syn_backlog=512 # Max SYN backlog
    sysctl -w net.ipv4.tcp_max_tw_buckets=8192 # Max TIME_WAIT sockets
    sysctl -w net.ipv4.tcp_fastopen=3          # Enable TCP Fast Open
    sysctl -w net.ipv4.tcp_mtu_probing=0       # Disable TCP MTU probing

    # Local Ports
    sysctl -w net.ipv4.ip_local_port_range="10000 60001" # Set ephemeral port range
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
  local status_start
  local msg

  echomsg "Starting ${SINGBOX_NAME}..."

  # shellcheck disable=SC3045
  ulimit -n "$(get_ulimit_n)" || exiterr "Failed to set ulimit -n"

  # shellcheck disable=SC2086
  start-stop-daemon -S -b -x $SINGBOX_PROC -c root:$SKEEN_PROC -- $SINGBOX_ARGS
  status_start=$?

  if [ $status_start -ne 0 ]; then
    msg="Failed to start $SINGBOX_NAME"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  while ! is_running && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
  done

  if ! is_running; then
    msg="$SINGBOX_NAME did not start in time"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  echook "$SINGBOX_NAME started"
  logger_notice "$SINGBOX_NAME started"
  return 0
}

start() {
  if [ ! -f "$SINGBOX_BIN" ]; then
    echoerr "$SINGBOX_NAME binary not found, please install it first"
    press_any_key_to_menu "" 1
  fi

  if [ "$CALLER" = "init" ]; then
    loading_config
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
    echook "Already started"
    return 0
  fi

  check_config && echo "$DELIMETER"

  [ "$CALLER" != "init" ] && loading_config

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
  local status_stop
  local msg

  echomsg "Stopping ${SINGBOX_NAME}..."

  if ! is_running; then
    echook "$SINGBOX_NAME already stopped"
    return 0
  fi

  start-stop-daemon -K -x $SINGBOX_PROC >/dev/null
  status_stop=$?

  if [ $status_stop -ne 0 ]; then
    msg="Failed to send stop signal to $SINGBOX_NAME"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  while is_running && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
  done

  if is_running; then
    msg="$SINGBOX_NAME did not stop in time"
    echoerr "$msg"
    logger_error "$msg"
    return 1
  fi

  msg="$SINGBOX_NAME stopped"
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
  if ! is_running; then
    echook "$SINGBOX_NAME is not running"
    return 0
  fi

  echo "Killing ${SINGBOX_PROC}..."
  killall -9 "$SINGBOX_PROC" 2>/dev/null
  clean_firewall
}

version() {
  local sk_version
  local sb_version

  sk_version="$(get_current_version "$SKEEN_PROC")"
  sb_version="$(get_current_version "$SINGBOX_PROC")"
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

  pid="$(pidof $SINGBOX_PROC)"

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
  download_singbox "$latest" || return 1
  if is_running; then stop || exit 1; fi
  install_singbox
  create_singbox_config
  echook "$SINGBOX_NAME core has been successfully updated"
}

update_skeen() {
  if ! is_running && [ "$SERVICE_PROXY_ENABLE" = "1" ]; then
    start || exit 1
  elif [ "$SERVICE_PROXY_ENABLE" != "1" ]; then
    stop || exit 1
  fi

  if download_skeen_script "update"; then
    echook "$SKEEN_NAME has been successfully updated"
    is_update_skeen=1
  else
    echoerr "Failed to update $SKEEN_NAME"
  fi
}

ask_and_update() {
  local name="${1:-}"
  local proc="${2:-}"
  local api="${3:-}"
  local update_fn="${4:-}"
  local releases="${5:-}"
  local current
  local latest
  local opt

  echomsg "Checking $name for updates..."

  current=$(get_current_version "$proc")
  [ -z "$current" ] && current="not installed"
  latest=$(get_latest_version "$api")
  [ -z "$latest" ] && echoerr "Failed to fetch the latest version" && return 1

  if [ "$latest" != "$current" ]; then
    printf '%s %s\n' "$(cyan "Current version ${name}:")" "$(red "$current")"
    printf '%s %s\n' "$(cyan "New version is available:")" "$(green "$latest")"
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
    echook "The latest $name version $latest is already installed"
  fi

  return 0
}

check_updates() {
  local optt

  check_tty

  is_update_skeen=0

  load_proxy_options

  # sing-box
  ask_and_update "$SINGBOX_NAME" "$SINGBOX_PROC" "$SINGBOX_API_URL" \
    update_core "https://github.com/SagerNet/sing-box/releases"
  if [ $? -eq 1 ] && [ ! -f "$SINGBOX_BIN" ] && [ -n "$latest" ]; then
    while :; do
      printf "Download %s %s? [y/n] (default: n): " "$SINGBOX_NAME" "$latest" >/dev/tty
      read -r optt </dev/tty
      [ -z "$optt" ] && optt=n

      case $optt in
      y | Y)
        update_core
        break
        ;;
      n | N) break ;;
      *) echoerr "Incorrect option" ;;
      esac
    done
  fi

  # skeen
  ask_and_update "$SKEEN_NAME" "$SKEEN_PROC" "$SKEEN_API_URL" \
    update_skeen "https://github.com/jinndi/SKeen/releases"
  [ $? -eq 1 ] && [ ! -f "$SKEEN_SCRIPT" ] && [ -n "$latest" ] && update_skeen

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

  echomsg "Test $3 $2"

  content="$($3 -w -t "$1" -nvL "$2" 2>/dev/null)"

  fw_test "$1" "$2" "$content" "[1-9][0-9]* references" "Reference"

  if [ "$2" = "$CHAIN_DNS" ]; then
    fw_test "$1" "$2" "$content" "skeen_dns" "Redirect"
    return 0
  fi

  if [ "$2" = "$CHAIN_TUN" ]; then
    fw_test "$1" "$2" "$content" "ACCEPT .* opkgtun+" "Accept"
    fw_test "nat" "POSTROUTING" \
      "$(iptables-save | grep -E "POSTROUTING -o opkgtun+")" \
      "MASQUERADE" "Masquerade"
    return 0
  fi

  fw_test "$1" "$2" "$content" "$BYPASS_NET_SET" "Excludes"

  if [ "$1" = "mangle" ] && [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "CONNMARK" "Connmark"
  fi

  [ "$2" = "$CHAIN_OUTPUT" ] && return 0

  if [ "$1" = "mangle" ] && [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ]; then
    fw_test "$1" "$2" "$content" "dpt:!?${DNS_PORT}" "DNS intercept"
  fi

  if [ -n "$SKEEN_INTERCEPT_PORTS" ] || [ -n "$SKEEN_EXCLUDE_PORTS" ]; then
    # shellcheck disable=SC2015
    fw_test "$1" "$2" "$($3 -t "$1" -nvL 2>/dev/null)" "multiport" "Multiport"
  fi

  if [ "$1" = "mangle" ] && [ "$SKEEN_TPROXY_NETWORK" = "tcp" ]; then
    fw_test "$1" "$2" "$content" "socket" "Socket"
  fi

  fw_test "$1" "$2" "$content" "redir|redirect" "Redirect"
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
  elif [ "$SKEEN_REDIRECT_DNS_ENABLE" != "1" ]; then
    echowarn "Testing is available in tun, redirect, tproxy, and hybrid modes"
    echowarn "Also, with the specified DNS redirect parameters"
    press_any_key_to_menu "" 1
  fi

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "iptables utility is not installed"
    press_any_key_to_menu "" 1
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "tun" ] || [ "$SKEEN_TUN_ENABLED" = "1" ]; then
    fw_test_chain filter "$CHAIN_TUN" "iptables"
  else
    for iptables in $SKEEN_IPTABLES_LIST; do
      [ "$iptables" = "ip6tables" ] && echo "$DELIMETER"

      [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ] && fw_test_chain nat "$CHAIN_DNS" "$iptables"

      for table in $tables; do
        fw_test_chain "$table" "$CHAIN_PREROUTING" "$iptables"
      done

      [ "$tables" != "nat" ] && fw_test_chain mangle "$CHAIN_OUTPUT" "$iptables"
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
    local work_dir_backup
    local required_mb

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
        create_singbox_config "force"
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
  local experimental_file=""
  local cache_file=""
  local msg_not_found="Cache file not found at path"

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
    echoerr "Configuration file with 'experimental.cache_file' parameter not found"
    return 0
  fi

  cache_file_enabled="$(jsonfilter -i "$experimental_file" -e '@.experimental.cache_file.enabled')"
  if [ "$cache_file_enabled" != "true" ]; then
    echowarn "Cache file is disabled in $SINGBOX_NAME configuration"
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
  echook "Cache cleared. Restart $SKEEN_NAME to apply changes"
}

get_sing_args_config() {
  SING_CONFIG_ARGS="-C $CONFIG_DIR"
  SING_CONFIG_ENABLE="$(jsonfilter -i "$SKEEN_CONFIG" -e '@.sing_config.enable')"
  : "${SING_CONFIG_ENABLE:=0}"
  SING_CONFIG_PATH="/opt/etc/skeen/config.json"
  if [ "$SING_CONFIG_ENABLE" = "1" ]; then
    SING_CONFIG_PATH="$(jsonfilter -i "$SKEEN_CONFIG" -e '@.sing_config.path')"
    : "${SING_CONFIG_PATH:=/opt/etc/skeen/config.json}"
    SING_CONFIG_ARGS="-c $SING_CONFIG_PATH"
    SINGBOX_ARGS="run -D $WORK_DIR $SING_CONFIG_ARGS"
  fi
}

check_config() {
  local msg_err="Configuration check failed"
  local is_error=0

  if [ -f "$SINGBOX_BIN" ]; then
    echomsg "Checking $SINGBOX_NAME configuration..."

    get_sing_args_config

    # shellcheck disable=SC2086
    if $SINGBOX_PROC check $SING_CONFIG_ARGS; then
      echook "$SINGBOX_NAME configuration is valid"
    else
      is_error=1
      echoerr "$msg_err"
    fi
  fi

  echomsg "Checking $SKEEN_NAME configuration..."
  if jsonfilter -i "$SKEEN_CONFIG" -e '@.firewall' >/dev/null 2>&1; then
    echook "$SKEEN_NAME JSON valid"
  else
    is_error=1
    echoerr "$msg_err"
  fi

  if [ $is_error -eq 1 ] && [ "$CALLER" = "menu" ]; then
    press_any_key_to_menu
  elif [ $is_error -eq 1 ]; then
    logger_error "$msg"
    exit 1
  fi
}

format_config() {
  if [ -f "$SINGBOX_BIN" ]; then
    echomsg "Formatting ${SINGBOX_NAME} configuration..."

    get_sing_args_config

    # shellcheck disable=SC2086
    if $SINGBOX_PROC format -w $SING_CONFIG_ARGS; then
      echook "Configuration formatted successfully"
    else
      echoerr "Configuration formatting failed"
    fi
  else
    echoerr "The $SINGBOX_NAME executable is missing"
  fi
}

sync_config() {
  local address="${1:-$SING_CONFIG_SYNC_URL}"
  local config_tmp="${TMP_DIR}/sing_config_tmp.json"

  load_proxy_options

  if [ -z "$address" ]; then
    echoerr "No address provided for sync" && return 1
  elif ! echo "$address" | grep -qE '^https?://'; then
    echoerr "URL must start with http:// or https://" && return 1
  fi

  # shellcheck disable=SC2086
  if ! curl $CURL_PROXY_OPTIONS -fsL "$address" -o "$config_tmp"; then
    echoerr "Failed to download configuration from $address" && return 1
  fi

  if is_tty && ! $SINGBOX_PROC check -c "$config_tmp"; then
    echoerr "$SINGBOX_NAME configuration is invalid, cancel synchronization!"
    rm -f "$config_tmp"
    return 1
  fi

  get_sing_args_config

  if [ "$SING_CONFIG_ENABLE" != "1" ]; then
    echowarn "Set the parameter sing_config.enable to 1 in the skeen.json file"
  fi

  rm -f "$SING_CONFIG_PATH"
  mv "$config_tmp" "$SING_CONFIG_PATH"
  echook "Configuration synced, then restart $SKEEN_NAME to apply the changes"
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
  loading_config
  import_firewall_vars

  show_header

  if [ "$AUTO_START_ENABLE" = "1" ]; then
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

  output="$output\n $SKEEN_NAME version: $(cyan "v$(get_current_version "$SKEEN_PROC")")"

  version="$(cyan "v$(get_current_version "$SINGBOX_PROC")")"
  [ "$version" = "$(cyan "v")" ] && version="$(red "not installed")"
  output="$output\n $SINGBOX_NAME version: ${version}"

  output="$output\n $SINGBOX_NAME state: $running_status"

  output="$output\n Start automatically: $autostart_status"

  if [ "$running_text" = "Stop" ]; then
    if [ "$SKEEN_INTERCEPT_DNS_ENABLE" = "1" ] || [ "$SKEEN_REDIRECT_DNS_ENABLE" = "1" ]; then
      sb_dns_work_text="$(green yes)"
    else
      sb_dns_work_text="$(red no)"
    fi
    output="$output\n ${SINGBOX_NAME} DNS working: $sb_dns_work_text"

    if [ "$SKEEN_FIREWALL_MODE" != "none" ] && [ "$SKEEN_FIREWALL_MODE" != "tun" ]; then
      echo "$SKEEN_IPTABLES_LIST" | grep -q "ipt" && ipv4="$(cyan "4")"
      echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6t" && ipv6="$(cyan "6")"

      [ -n "$SKEEN_POLICY_NAME" ] &&
        output="$output\n Client policy:: $(cyan "$SKEEN_POLICY_NAME")"
      [ "$SKEEN_TUN_ENABLED" = "1" ] &&
        output="$output\n Uses OpkgTun: $(cyan "yes")"
      output="$output\n Firewall mode: $(cyan "$SKEEN_FIREWALL_MODE")"
      output="$output\n Firewall network: $(cyan "$SKEEN_FIREWALL_NETWORK")"
      output="$output\n Firewall IP ver.: $ipv4 $ipv6"
    else
      output="$output\n Firewall mode: $(cyan "$SKEEN_FIREWALL_MODE")"
    fi
  fi

  output="$output\n\n$(cyan "Select option:")"
  output="$output\n  $(green "1.") $running_text"
  output="$output\n  $(green "2.") Restart"
  output="$output\n  $(green "3.") Check Updates"
  output="$output\n  $(green "4.") Test Firewall"
  output="$output\n  $(green "5.") Uninstall"
  output="$output\n  $(green "0.") Exit\n"

  printf "%b" "$output"

  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    printf "\nEnter your selection [0-5]: " >/dev/tty
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
      echoerr "Incorrect option"
      attempt=$((attempt + 1))
    fi
  done

  exiterr "Maximum attempts reached, exiting menu."
}

show_help() {
  cat <<EOF

$SKEEN_NAME CLI Commands (use: 'skeen help' for this list):

Service Control:
  start   - Start service
  stop    - Stop service
  restart - Restart service
  reload  - Restart without changing firewall rules
  kill    - Force stop
  status  - Show status

Information & Updates:
  version - Show version(s)
  iface   - Show network interface table
  update  - Check and install updates

Checks & Testing:
  test    - Test firewall rules
  deps    - Check dependencies
  check   - Check configuration
  format  - Format $SINGBOX_NAME configuration

Backup & Restore:
  backup  - Create archive of $WORK_DIR
  backups - List created archives in $ENTWARE_DIR
  restore - Restore $WORK_DIR from archive in $ENTWARE_DIR

Reset & Cleanup:
  reset   - Reset $WORK_DIR to default
  clean   - Clear $SINGBOX_NAME cache file

Synchronization:
  sync    - Synchronize $SINGBOX_NAME configuration

OpkgTun manager (KeeneticOS v5+):
  tun create <ipv4> <name> - Create interface with IP address and name
  tun delete <name>        - Delete interface by name
  tun list                 - List all OpkgTun interfaces
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
    release_version_ge5 || exit 1
    case "$2" in
    create) tun_create "$3" "$4" ;;
    delete) tun_delete "$3" ;;
    list) tun_list ;;
    *) show_help | awk '/OpkgTun / {flag=1} flag' ;;
    esac
    ;;
  apply_firewall) [ "$CALLER" = "netfilter" ] && apply_firewall ;;
  "") show_menu ;;
  help | *) show_help ;;
  esac
else
  install
fi

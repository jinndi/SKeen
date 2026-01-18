#!/bin/sh
#
# https://github.com/jinndi/SKeen
#
# Copyright (c) 2026 Jinndi <alncores@gmail.ru>
#
# Released under the MIT License, see the accompanying file LICENSE
# or https://opensource.org/licenses/MIT
PATH="/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ACTION="$1"
CALLER="$2"
[ -z "$CALLER" ] && CALLER="cli"
[ -z "$ACTION" ] && CALLER="menu"

DEPENDENCIES="ndmc start-stop-daemon iptables jsonfilter curl tar"

ENTWARE_DIR="/opt"
WORK_DIR="${ENTWARE_DIR}/etc/skeen"
CONFIG_DIR="${WORK_DIR}/config"
TMP_DIR="${ENTWARE_DIR}/tmp"
NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
MODULES_OS_DIR="/lib/modules/$(uname -r)"
MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"

SKEEN_NAME="SKeen"
SKEEN_VERSION="3.2.0"
SKEEN_PROC="skeen"
SKEEN_SCRIPT="${ENTWARE_DIR}/bin/${SKEEN_PROC}"
SKEEN_SCRIPT_URL="https://raw.githubusercontent.com/jinndi/SKeen/main/install.sh"
SKEEN_ARCHIVE_URL="https://github.com/jinndi/SKeen/archive"
SKEEN_API_URL="https://api.github.com/repos/jinndi/SKeen/releases/latest"
SKEEN_CONFIG="${WORK_DIR}/${SKEEN_PROC}.conf"
SKEEN_AUTOSTART_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"

SINGBOX_NAME="Sing-box"
SINGBOX_PROC="skeen-box"
SINGBOX_ARGS="run -D $WORK_DIR -C $CONFIG_DIR"
SINGBOX_BIN="${ENTWARE_DIR}/bin/${SINGBOX_PROC}"
SINGBOX_API_URL="https://api.github.com/repos/SagerNet/sing-box/releases/latest"

FIREWALL_HOOK_FILE="${NETFILTER_DIR}/firewall_${SKEEN_PROC}.sh"
TMP_WAIT_DEFAULT_ROUTE="${TMP_DIR}/${SKEEN_PROC}_wait_dafault_route"
CHAIN_PREROUTING="skeen"
CHAIN_OUTPUT="skeen_mask"
TABLE_REDIRECT="nat"
TABLE_TPROXY="mangle"
TABLE_MARK="0x112"
TABLE_ID="112"
DNS_PORT=53

SYS_IPV4_TEST_HOSTS="1.1.1.1 77.88.8.8 223.5.5.5"
SYS_IPV6_TEST_HOSTS="2606:4700:4700::1111 2a02:6b8::feed:0ff 2400:3200::1"

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
192.88.99.2/32     # 6a44-relay anycast (RFC6751)
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

create_skeen_config(){
  mkdir -p "$(dirname "$SKEEN_CONFIG")"

  {
    echo "# Sing-box autostart on router reboot"
    echo "# 0 - disabled, 1 - enabled"
    echo "AUTO_START=1"
    echo
    echo "# Auto-start delay in seconds"
    echo "AUTO_START_DELAY=0"
    echo
    echo "# Domains or IPs for testing the internet connection (no more than 3)"
    echo "# List: ya.ru,77.88.8.8,... or ya.ru 77.88.8.8"
    echo "IPV4_TEST_HOSTS=\"$SYS_IPV4_TEST_HOSTS\""
    echo "IPV6_TEST_HOSTS=\"$SYS_IPV6_TEST_HOSTS\""
    echo
    echo "# Router policy name for $SKEEN_NAME traffic"
    echo "POLICY_NAME=\"${SKEEN_NAME}\""
    echo
    echo "# Ports to intercept and redirect via TProxy/Redirect (all ports if not specified)."
    echo "# List: port and port ranges use colon e.g. 80,443,1000:2000 or 80 443 1000:2000"
    echo "INTERCEPT_PORTS=\"\""
    echo
    echo "# Ports to excluded redirect via TProxy/Redirect"
    echo "# List: port and port ranges use colon e.g. 80,443,1000:2000 or 80 443 1000:2000"
    echo "EXCLUDE_PORTS=\"\""
    echo
    echo "# Excluded ip addreses for traffic redirection"
    echo "# List: 192.155.1.1,192.200.1.1,... or 192.155.1.1 192.200.1.1 ..."
    echo "EXCLUDE_IPV4_ADDRESES=\"\""
    echo "EXCLUDE_IPV6_ADDRESES=\"\""
    echo
    echo "# Excluded subnets for traffic redirection"
    echo "# List: 192.155.1.1/24,192.200.1.1/24,... or 192.155.1.1/24 192.200.1.1/24 ..."
    echo "EXCLUDE_IPV4_SUBNETS=\"\""
    echo "EXCLUDE_IPV6_SUBNETS=\"\""
  } > "$SKEEN_CONFIG"

  create_autostart_script > /dev/null 2>&1
}

[ -f "$SKEEN_CONFIG" ] || create_skeen_config
# shellcheck disable=SC1090
. "$SKEEN_CONFIG"

cyan()  { printf '\033[36m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

echomsg() { cyan "[INFO]: $1" >&2; }
echook() { green "[OK]: $1" >&2; }
echowarn() { yellow "[WARN]: $1" >&2; }
echoerr() { red "[ERROR]: $1" >&2; }
exiterr() { red "[FATAL]: $1" >&2; exit 1; }

logger_notice() { logger -p notice -t "$SKEEN_NAME" "$1"; }
logger_warning() { logger -p warning -t "$SKEEN_NAME" "$1"; }
logger_error() { logger -p error -t "$SKEEN_NAME" "$1"; }


get_current_version() {
  case "$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')" in
    "$SINGBOX_PROC")
      if [ -f "$SINGBOX_BIN" ]; then
        $SINGBOX_BIN version | awk 'NR==1 {print $3}' | xargs
      fi
    ;;
    "$SKEEN_PROC")
      echo "$SKEEN_VERSION"
    ;;
    *)
      echoerr "Unknown program: $1"
      return 1
    ;;
  esac
}


get_latest_version() {
  api_url=$1

  latest_release="$(curl --connect-timeout 5 --max-time 90 -s "$api_url")"
  curl_exit_status=$?

  if [ $curl_exit_status -ne 0 ]; then
    echoerr "Failed to fetch the latest version information."
    return 1
  fi

  if [ "$(echo "$latest_release" | grep -c tag_name)" -eq 0 ]; then
    echoerr "Failed to parse the latest version information:\n$(echo "$latest_release" | grep message)"
    return 1
  fi

  echo "$latest_release" | grep tag_name | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
}


show_header() {
  printf '\033[1;35m'
  cat <<EOF

░██████╗██╗░░██╗███████╗███████╗███╗░░██╗
██╔════╝██║░██╔╝██╔════╝██╔════╝████╗░██║
╚█████╗░█████═╝░█████╗░░█████╗░░██╔██╗██║
░╚═══██╗██╔═██╗░██╔══╝░░██╔══╝░░██║╚████║
██████╔╝██║░╚██╗███████╗███████╗██║░╚███║
╚═════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚══╝
EOF
  printf '\033[0m'
}


get_os_release(){
  release_path=$(command -v opkg)

  if [ "$release_path" != "/opt/bin/opkg" ]; then
    exiterr "Unsupported the system OS!"
  else
    PKG_OS="openwrt"
    PKG_SUFFIX=".ipk"
  fi
}


get_architecture() {
  case "$(uname -m | tr '[:upper:]' '[:lower:]')" in
    # ARM64
    *aarch64* | *arm64* | *armv8*)
      ARCH="aarch64"
      case "$(grep -i 'cpu part' /proc/cpuinfo | sed -e 's/.*: //' | tr '[:upper:]' '[:lower:]' | head -n1)" in
        *0xd03*) PKG_ARCH="${ARCH}_cortex-a53" ;;
        *0xd08*) PKG_ARCH="${ARCH}_cortex-a72" ;;
        *0xd0b*) PKG_ARCH="${ARCH}_cortex-a76" ;;
        *)       PKG_ARCH="${ARCH}_generic" ;;
      esac
    ;;

    # MIPS endian
    *mipsel*|*mipsle*) ARCH="mipsel" ;;
    *mips*)            ARCH="mips" ;;

    *) exiterr "Unsupported CPU architecture" ;;
  esac

  [ -n "$PKG_ARCH" ] && return

  # MIPS core
  case "$(grep -i 'cpu model' /proc/cpuinfo | sed -e 's/.*: //i' | tr '[:upper:]' '[:lower:]')" in
    *74k*|*34k*)    PKG_ARCH="${ARCH}_74kc" ;;
    *24kf*|*24k*f*) PKG_ARCH="${ARCH}_24kc_24kf" ;;
    *24k*|*1004*)   PKG_ARCH="${ARCH}_24kc" ;;
    *4kec*)         PKG_ARCH="${ARCH}_4kec" ;;
    *)              PKG_ARCH="${ARCH}_mips32" ;;
  esac
}


wait_input(){
  oldstty=$(stty -g < /dev/tty)
  stty -icanon -echo min 1 time 0 < /dev/tty
  dd bs=1 count=1 < /dev/tty 2>/dev/null
  stty "$oldstty" < /dev/tty
  echo > /dev/tty
}


install_dependencies() {
  pkg_missing=""

  echomsg "Checking dependencies"
  opkg update >/dev/null 2>&1

  for pkg_name in $DEPENDENCIES; do
    printf "Installing %s ... " "$pkg_name"

    if command -v "$pkg_name" >/dev/null 2>&1; then
      echook "Already installed"
      continue
    fi

    if opkg install "$pkg_name" >/dev/null 2>&1; then
      echook "OK"
    else
      echoerr "FAILED"
      pkg_missing="${pkg_missing:+$pkg_missing }$pkg_name"
    fi
  done

  if [ -n "$pkg_missing" ]; then
    exiterr "Missing dependencies: $pkg_missing"
  fi

  echook "All dependencies are installed"
}


download_singbox(){
  download_version="$1"

  if [ -z "$download_version" ]; then
    echomsg "Fetching the latest version number..."
    download_version="$(get_latest_version "$SINGBOX_API_URL")" || exit 1
    echook "Latest version is $download_version"
  fi

  PKG_NAME="sing-box_${download_version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
  pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${download_version}/${PKG_NAME}"

  echomsg "Downloading $PKG_NAME ..."

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR" || exit

  curl --fail --connect-timeout 5 --max-time 90 -Lo "$PKG_NAME" "$pkg_url"
  curl_exit_status=$?

  if [ $curl_exit_status -ne 0 ]; then
    if [ -n "$download_version" ]; then
      echoerr "Failed to download $PKG_NAME"
      return 1
    else
      exiterr "Failed to download $PKG_NAME"
    fi
  fi

  echook "Downloaded $PKG_NAME successfully."
}


install_singbox(){
  tmp_unpack_dir="${TMP_DIR}/sing-box-unpack"

  if [ -d "$tmp_unpack_dir" ]; then
    rm -rf "$tmp_unpack_dir"
  fi

  echomsg "Extracting $PKG_NAME"
  mkdir "$tmp_unpack_dir"
  cd "$tmp_unpack_dir" || exit
  tar -xf "../${PKG_NAME}"
  tar -xzf data.tar.gz
  echook "Extraction completed."

  echomsg "Installing $SINGBOX_NAME binary to $SINGBOX_BIN"
  [ -f "$SINGBOX_BIN" ] && rm -f "$SINGBOX_BIN"
  mv ./usr/bin/sing-box "$SINGBOX_BIN"
  chmod 755 "$SINGBOX_BIN"
  chmod +x "$SINGBOX_BIN"
  echook "$SINGBOX_NAME binary installed successfully."

  echomsg "Cleaning up temporary files..."
  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${PKG_NAME}"
  echook "Cleanup completed."
}


create_singbox_config(){
  if [ -d "$CONFIG_DIR" ] && ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
    echomsg "Configuration files already exist in $CONFIG_DIR, skipping creation."
    return
  fi

  echomsg "Creating default configuration files..."

  mkdir -p "$CONFIG_DIR"
  cat <<EOF > "$CONFIG_DIR/log.json"
{
  "log": {
    "disabled": false,
    "level": "debug",
    "timestamp": true
  }
}
EOF

  cat <<EOF > "$CONFIG_DIR/dns.json"
{
  "dns": {
    "servers": [
      {
        "tag": "dns-direct",
        "type": "tls",
        "server": "common.dot.dns.yandex.net",
        "domain_resolver": "dns-resolver"
      },
      {
        "tag": "fakeip",
        "type": "fakeip",
        "inet4_range": "198.18.0.0/15",
        "inet6_range": "fc00::/18"
      },
      {
        "tag": "dns-resolver",
        "type": "udp",
        "server": "77.88.8.8"
      }
    ],
    "rules": [
      {
        "rule_set": "adguard",
        "action": "reject"
      },
      {
        "query_type": [
          "A",
          "AAAA"
        ],
        "server": "fakeip"
      }
    ],
    "final": "dns-direct",
    "strategy": "prefer_ipv4",
    "independent_cache": true
  }
}
EOF

  cat <<EOF > "$CONFIG_DIR/inbounds.json"
{
  "inbounds": [
    {
      "type": "redirect",
      "listen": "::",
      "listen_port": 2081,
      "tcp_fast_open": true,
      "tcp_multi_path": true
    },
    {
      "type": "tproxy",
      "listen": "::",
      "listen_port": 2082,
      "network": "udp",
      "udp_fragment": true,
      "udp_timeout": "5m"
    }
  ]
}
EOF

  cat <<EOF > "$CONFIG_DIR/outbounds.json"
{
  "outbounds": [
    {
      "tag": "selector",
      "type": "selector",
      "default": "auto",
      "interrupt_exist_connections": false,
      "outbounds": [
        "auto",
        "VLESS",
        "direct"
      ]
    },
    {
      "tag": "auto",
      "type": "urltest",
      "url": "http://www.gstatic.com/generate_204",
      "interval": "5m",
      "tolerance": 50,
      "idle_timeout": "30m",
      "interrupt_exist_connections": false,
      "outbounds": [
        "VLESS"
      ]
    },
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "VLESS",
      "type": "vless",
      "uuid": "00000000-0000-0000-0000-00000000000",
      "flow": "xtls-rprx-vision",
      "packet_encoding": "xudp",
      "server": "example.com",
      "server_port": 443,
      "tls": {
        "alpn": [
          "h1", "h2"
        ],
        "enabled": true,
        "server_name": "example.com",
        "utls": {
          "enabled": true,
          "fingerprint": "firefox"
        }
      }
    }
  ]
}
EOF

  cat <<EOF > "$CONFIG_DIR/route.json"
{
  "route": {
    "default_domain_resolver": "dns-resolver",
    "auto_detect_interface": true,
    "final": "selector",
    "rules": [
      {
        "action": "sniff",
      },
      {
        "type": "logical",
        "mode": "or",
        "rules": [
          {
            "protocol": "dns"
          },
          {
            "port": 53
          }
        ],
        "action": "hijack-dns"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "type": "logical",
        "mode": "or",
        "rules": [
          {
            "network": "udp",
            "port": 443
          },
          {
            "protocol": "stun"
          },
          {
            "rule_set": "adguard"
          }
        ],
        "action": "reject"
      },
      {
        "action": "route",
        "clash_mode": "direct",
        "outbound": "direct"
      },
      {
        "action": "route",
        "rule_set": "geosite-cheburnet",
        "outbound": "direct"
      },
      {
        "action": "route",
        "clash_mode": "global",
        "outbound": "selector"
      }
    ],
    "rule_set": [
      {
        "type": "remote",
        "tag": "adguard",
        "format": "binary",
        "url": "https://github.com/jinndi/adguard-filter-list-srs/releases/latest/download/adguard-filter-list.srs",
        "download_detour": "direct",
        "update_interval": "24h0m0s"
      },
      {
        "type": "remote",
        "tag": "geosite-cheburnet",
        "format": "binary",
        "url": "https://github.com/jinndi/geosite-cheburnet/releases/latest/download/geosite-cheburnet.srs",
        "download_detour": "direct",
        "update_interval": "24h0m0s"
      }
    ]
  }
}
EOF

  cat <<EOF > "$CONFIG_DIR/experimental.json"
{
  "experimental": {
    "clash_api": {
      "external_controller": "0.0.0.0:9090",
      "external_ui_download_url": "https://github.com/Zephyruso/zashboard/archive/gh-pages.zip",
      "external_ui": "zashboard",
      "external_ui_download_detour": "direct",
      "default_mode": "rule"
    },
    "cache_file": {
      "enabled": true,
      "path": "cache.db",
      "store_fakeip": true,
      "store_rdrc": true
    }
  }
}
EOF

  echook "Configuration file created successfully."
}


create_autostart_script(){
  echomsg "Create $SKEEN_NAME autostart script at $SKEEN_AUTOSTART_SCRIPT"

  [ -f "$SKEEN_AUTOSTART_SCRIPT" ] && rm -f "$SKEEN_AUTOSTART_SCRIPT"

  {
    echo "#!/bin/sh"
    echo "PATH=$PATH"
    echo "$SKEEN_PROC start init"
  } > "$SKEEN_AUTOSTART_SCRIPT"

  chmod 755 "$SKEEN_AUTOSTART_SCRIPT"
  chmod +x "$SKEEN_AUTOSTART_SCRIPT"

  echook "Autostart script created successfully."
}


create_current_script(){
  [ -f "$SKEEN_SCRIPT" ] && rm -f "$SKEEN_SCRIPT"

  echomsg "Downloading current script at $SKEEN_SCRIPT"

  curl --fail --connect-timeout 5 --max-time 90 -Lo "$SKEEN_SCRIPT" "$SKEEN_SCRIPT_URL"
  curl_exit_status=$?

  if [ $curl_exit_status -ne 0 ]; then
    exiterr "Failed to download the current script"
  fi

  chmod 755 "$SKEEN_SCRIPT"
  chmod +x "$SKEEN_SCRIPT"

  echook "Current script created successfully."
}


press_any_key_to_menu(){
  [ "$CALLER" != "menu" ] && return 0

  echo "$DELIMETER"

  printf "Press any key to open menu..." > /dev/tty
  wait_input

  if [ "$1" = "reload" ];then
    exec sh "$SKEEN_SCRIPT"
  else
    show_menu
  fi
}


is_running(){
  if [ -n "$(pidof "$SINGBOX_PROC")" ]; then
    return 0
  else
    return 1
  fi
}


install(){
  echo "$DELIMETER"
  printf "Press any key to start installation..." > /dev/tty
  wait_input

  get_os_release
  get_architecture
  install_dependencies
  download_singbox
  install_singbox
  create_singbox_config
  create_autostart_script
  create_current_script

  printf "\n"
  echook "Installation completed, $SINGBOX_NAME version:"
  "$SINGBOX_BIN" version
  echomsg "Configure $SINGBOX_NAME by editing: $CONFIG_DIR"

  press_any_key_to_menu
}


uninstall(){
  echomsg "Uninstalling ${SKEEN_NAME}..."

  is_running && stop

  echomsg "Removing $SINGBOX_NAME binary..."
  rm -f "$SINGBOX_BIN"

  echomsg "Removing auto-start script..."
  rm -f "$SKEEN_AUTOSTART_SCRIPT"

  echomsg "Removing $SKEEN_NAME script..."
  rm -f "$SKEEN_SCRIPT"

  echomsg "Configuration directory $WORK_DIR is retained."
  echomsg "If you want to remove it manually, run: rm -rf '$WORK_DIR'"
  echook "${SKEEN_NAME} has been uninstalled successfully."
  exit 0
}


accept_uninstall(){
  max_attempts=3
  attempt=0

  while [ $attempt -lt $max_attempts ]; do
    printf "Uninstall, %s? [y/n]: " "$SKEEN_NAME" > /dev/tty
    read -r option < /dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
      y|Y)
        uninstall
      ;;
      n|N)
        break
      ;;
      *)
        echoerr "Incorrect option"
        attempt=$((attempt+1))
      ;;
    esac
  done

  show_menu
}


update_conf_var(){
  KEY=$1
  VALUE=$2

  [ -f "$SKEEN_CONFIG" ] || create_skeen_config

  if grep -q "^[[:space:]]*${KEY}[[:space:]]*=" "$SKEEN_CONFIG"; then
    sed -i "s|^[[:space:]]*${KEY}[[:space:]]*=.*|$KEY=$VALUE|" "$SKEEN_CONFIG"
  else
    echo "$KEY=$VALUE" >> "$SKEEN_CONFIG"
  fi

  # shellcheck disable=SC1090
  . "$SKEEN_CONFIG"
}


get_inet_tests_hosts() {
  ipv="$1"
  hosts=""
  sys_hosts=""
  max="3"

  if [ "$ipv" = "4" ]; then
    hosts="$IPV4_TEST_HOSTS"
    sys_hosts="$SYS_IPV4_TEST_HOSTS"
  else
    hosts="$IPV6_TEST_HOSTS"
    sys_hosts="$SYS_IPV6_TEST_HOSTS"
  fi

  if [ -z "$hosts" ]; then
    echo "$sys_hosts"
  else
    hosts="$(echo "$hosts" | \
      tr ',\t' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')"

    set -- "$hosts"

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
  hosts="$(get_inet_tests_hosts "4")"
  max_attempts="3"
  delay="5"

  for host in $hosts; do
    attempt=1
    while [ $attempt -le "$max_attempts" ]; do
      if ping -c 1 "$host" >/dev/null 2>&1; then
        logger_notice "Internet is available via ${host}"
        return 0
      else
        logger_warning "Internet is not available (${host}), attempt ${attempt}/${max_attempts}..."
      fi
      attempt=$((attempt + 1))
      sleep "$delay"
    done
  done

  msg="Internet is not available via any of the checked hosts"
  logger_error "$msg"
  exiterr "$msg"
}


get_inbounds_data() {
  type="$1"

  json_files="$(find "$CONFIG_DIR" -name '*.json')"

  for file in $json_files; do

    port=$(jsonfilter -i "$file" \
      -e '@.inbounds[@.type="'"$type"'"].listen_port' \
      | head -n1 2>/dev/null)

    [ -z "$port" ] && continue

    if [ "$type" = "redirect" ]; then
      echo "${port}|tcp"
      return 0
    fi

    network=$(jsonfilter -i "$file" \
      -e '@.inbounds[@.type="'"$type"'"].network' \
      | head -n1 2>/dev/null)

    if [ -n "$network" ]; then
      echo "${port}|${network}"
    else
      echo "${port}|tcpudp"
    fi

    return 0
  done

  return 0
}


has_dns_servers() {
  for file in "$CONFIG_DIR"/*.json; do
    [ -f "$file" ] || continue
    if jsonfilter -i "$file" -e '@.dns.servers[0]' >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}


check_router_port() {
  port_ssl=$(curl -kfsS "127.0.0.1:79/rci/ip/http/ssl" 2>/dev/null | jsonfilter -e '@.port')

  if [ "$port_ssl" = "443" ]; then
    echoerr "Port 443 is occupied by router services"
    echoerr "Free it on the 'Users and Access'"
    logger_error "Port 443 must be freed"
    press_any_key_to_menu
    exit 1
  fi
}


is_owner_module_working() {
  chain="TEST_OWNER_CHAIN"

  iptables -w -t mangle -N "$chain" >/dev/null 2>&1 || return 1

  if iptables -w -t mangle -A "$chain" -m owner --gid-owner 65534 -j RETURN >/dev/null 2>&1; then
    result=0
  else
    result=1
  fi

  iptables -w -t mangle -F "$chain" >/dev/null 2>&1
  iptables -w -t mangle -X "$chain" >/dev/null 2>&1

  return "$result"
}


load_module() {
  module="$1"
  modname="${module%.ko}"

  if lsmod | grep -q "^$modname"; then
    return 0
  fi

  path_entware="${MODULES_ENTWARE_DIR}/${module}"
  path_os="${MODULES_OS_DIR}/${module}"

  if [ -f "$path_entware" ]; then
    insmod "$path_entware" >/dev/null 2>&1 && return 0
  fi

  if [ -f "$path_os" ]; then
    mkdir -p "$MODULES_ENTWARE_DIR"
    cp "$path_os" "$path_entware" 2>/dev/null
    insmod "$path_os" >/dev/null 2>&1 && return 0
  fi

  echoerr "Module '$module' not found"
  return 1
}


loading_modules() {
  error=0
  modules="xt_TPROXY.ko xt_socket.ko xt_owner.ko xt_multiport.ko"

  case "$SKEEN_FIREWALL_MODE" in
    tproxy|hybrid)
      echomsg "Loading modules: xt_TPROXY.ko xt_socket.ko"
    ;;
  esac

  if [ "$SKEEN_USE_DNS_CONFIG" = "1" ]; then
    if is_owner_module_working; then
      echomsg "Loading modules: xt_owner.ko"
    else
      SKEEN_USE_DNS_CONFIG=0
      echowarn "iptables owner module is unavailable"
      echowarn "$SINGBOX_NAME DNS functionality will be disabled"
    fi
  fi

  if [ -n "$INTERCEPT_PORTS" ] || [ -n "$EXCLUDE_PORTS" ]; then
    echomsg "Loading modules: xt_multiport.ko"
  fi

  modules="$(echo "$modules" | tr ' ' '\n' | sort -u)"

  for module in $modules; do
    load_module "$module" || error=1
  done

  if [ "$error" -ne 0 ]; then
    echoerr "The '$SKEEN_FIREWALL_MODE' mode requires kernel modules"
    echoerr "Install router component: Netfilter Subsystem Kernel Modules"
    logger_error "Missing Netfilter kernel modules"
    press_any_key_to_menu
    exit 1
  fi

  return 0
}


get_iptables_list(){
  ipt4="$(ip -4 addr show | grep -q "inet " && \
    command -v iptables >/dev/null 2>&1 && echo iptables)"

  ipt6="$(ip -6 addr show | grep -q "inet6 " && \
    command -v ip6tables >/dev/null 2>&1 && echo ip6tables)"

  # shellcheck disable=SC2086
  set -- $ipt4 $ipt6
  ipt_list="$*"

  echomsg "Detected iptables: $ipt_list"
  echo "$ipt_list"
}


get_mark_policy(){
  [ -n "$POLICY_NAME" ] && \
  mark=$(ndmc -c show ip policy | awk -v d="$(printf '%s' "$POLICY_NAME" | tr '[:upper:]' '[:lower:]')" '
    /description =/ { f = (tolower($0) ~ "description = " d) }
    f && /mark:/ { print $2; exit }')

  if [ -z "$POLICY_NAME" ]; then
    echowarn "Policy name (POLICY_NAME var) not set"
  elif [ -z "$mark" ]; then
    echowarn "Policy $POLICY_NAME not found"
  else
    echomsg "Detected policy mark: $mark"
    echomsg "Routing for the $POLICY_NAME policy"

    echo "0x${mark}"
    return 0
  fi

  echowarn "Routing for the entire device"
  return 0
}


set_route_rules() {
  if [ -n "$SKEEN_MARK_POLICY" ]; then
    source_table=$(ip rule show |
      awk -v p="$SKEEN_MARK_POLICY" '$0 ~ p && /lookup/ && !/blackhole/ {print $NF; exit}' | sed -n '1p')
    policy_table="$source_table"
  else
    source_table="main"
    policy_table=""
  fi

  check_default_route() {
    if [ "$IP_VERSION" = "6" ] && ! ip -6 route show default 2>/dev/null | grep -q .; then
      return 0
    fi

    if [ "$source_table" = "main" ]; then
      ip -"$IP_VERSION" route show default 2>/dev/null | grep -q '^default'
    else
      ip -"$IP_VERSION" route show table all 2>/dev/null |
      grep -E "^[[:space:]]*default .* table $policy_table( |$)" |
      grep -vq 'unreachable'
    fi
  }

  i=0
  until check_default_route; do
    [ -f "$TMP_WAIT_DEFAULT_ROUTE" ] || touch "$TMP_WAIT_DEFAULT_ROUTE"

    msg="Waiting for default route in table '$source_table' (IPv$IP_VERSION), attempt $((i+1))/10"
    echowarn "$msg"
    logger_warning "$msg"

    i=$((i+1))
    if [ "$i" -ge 10 ]; then
      msg="Check your internet connection"
      if [ -n "$SKEEN_MARK_POLICY" ]; then
        msg="$msg for policy $POLICY_NAME"
      fi
      logger_error "$msg"
      exiterr "$msg"
    fi
    sleep 5
  done

  [ "$i" -eq 0 ] || {
    msg="Default route found in table '$source_table' (IPv$IP_VERSION)"
    echook "$msg"
    logger_notice "$msg"
  }

  ip -"$IP_VERSION" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1
  ip -"$IP_VERSION" route flush table "$TABLE_ID" >/dev/null 2>&1

  ip -"$IP_VERSION" route add local default dev lo table "$TABLE_ID"
  ip -"$IP_VERSION" rule add fwmark "$TABLE_MARK" lookup "$TABLE_ID"

  ip -"$IP_VERSION" route show table "$source_table" 2>/dev/null |
  while read -r r; do
    case "$r" in
      default*|blackhole*|unreachable*) continue ;;
    esac
    ip -"$IP_VERSION" route add table "$TABLE_ID" "$r" 2>/dev/null
  done
}


get_exclude_addresses() {
  ip_v="$1"
  eth_subnet=""
  reserved_subnets=""
  user_exclude=""

  [ "$ip_v" = "4" ] && prefix_length_default="32" || prefix_length_default="128"

  is_valid_ipv4() {
      addr="${1%%/*}"
      IFS=. read -r o1 o2 o3 o4 <<EOF
$addr
EOF
    for o in $o1 $o2 $o3 $o4; do
      [ "$o" -ge 0 ] 2>/dev/null || return 1
      [ "$o" -le 255 ] 2>/dev/null || return 1
    done

    return 0
  }

  is_valid_ipv6() {
    addr="$1"
    if ip -6 addr add "$addr" dev lo 2>/dev/null; then
      ip -6 addr del "$addr" dev lo
      return 0
    fi

    return 1
  }

  get_eth_subnet() {
    _ip_v="$1"
    addresses="$(get_inet_tests_hosts "$_ip_v")"
    prefix_length="32"
    [ "$_ip_v" = "6" ] && prefix_length="128"

    for address in $addresses; do
      eth_ip="$(ip -"$_ip_v" route get "$address" 2>/dev/null |
                awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
      [ -n "$eth_ip" ] && echo "${eth_ip}/${prefix_length}" && break
    done
  }

  if [ "$ip_v" = "4" ]; then
    eth_subnet="$(get_eth_subnet "$ip_v")"
    reserved_subnets="$RESERVED_IPV4"
    user_exclude="${EXCLUDE_IPV4_ADDRESES},${EXCLUDE_IPV4_SUBNETS}"
  else
    eth_subnet="$(get_eth_subnet "$ip_v")"
    reserved_subnets="$RESERVED_IPV6"
    user_exclude="${EXCLUDE_IPV6_ADDRESES},${EXCLUDE_IPV6_SUBNETS}"
  fi

  user_exclude="$(echo "$user_exclude" | \
    tr ',\t' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')"

  all_list="$eth_subnet"

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

  for addr in $user_exclude; do
    case "$ip_v" in
      4)
        [ "${addr#*/}" = "$addr" ] && addr="${addr}/${prefix_length_default}"
        if is_valid_ipv4 "$addr"; then
          all_list="$all_list $addr"
        else
          echowarn "Invalid IPv4 exclude address: $addr"
        fi
      ;;
      6)
        [ "${addr#*/}" = "$addr" ] && addr="${addr}/${prefix_length_default}"
        if is_valid_ipv6 "$addr"; then
          all_list="$all_list $addr"
        else
          echowarn "Invalid IPv6 exclude address: $addr"
        fi
      ;;
    esac
  done

  echo "$all_list" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}


set_exclude_rules() {
  iptables="$1"
  table="$2"
  chain="$3"

  use_dns=0
  [ "$chain" != "$CHAIN_OUTPUT" ] && [ "$SKEEN_USE_DNS_CONFIG" = "1" ] && use_dns=1

  ipt() {
    $iptables -w -t "$table" -A "$chain" -d "$exclude" "$@" -j RETURN >/dev/null 2>&1
  }

  for exclude in $EXCLUDE_ADDRESSES; do
    if [ "$exclude" = "192.168.0.0/16" ] && [ "$use_dns" -eq 1 ]; then
      case "$SKEEN_FIREWALL_MODE:$table" in
        hybrid:mangle)
          ipt -p tcp --dport "$DNS_PORT"
          ipt -p udp ! --dport "$DNS_PORT"
        ;;
        hybrid:nat)
          ipt -p tcp ! --dport "$DNS_PORT"
          ipt -p udp --dport "$DNS_PORT"
        ;;
        tproxy:mangle)
          ipt -p tcp ! --dport "$DNS_PORT"
          ipt -p udp ! --dport "$DNS_PORT"
        ;;
      esac
    else
      ipt
    fi
  done
}


set_iptables_rules() {
  iptables="$1"
  table="$2"
  chain="$3"

  if ! $iptables -t "$table" -nL "$chain" >/dev/null 2>&1; then
    $iptables -t "$table" -N "$chain" || return 0

    set_exclude_rules "$iptables" "$table" "$chain"

    case "$SKEEN_FIREWALL_MODE" in
      hybrid)
        if [ "$table" = "$TABLE_REDIRECT" ]; then
          set -- -p tcp -j REDIRECT --to-port "$SKEEN_REDIRECT_PORT"
          $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
        else
          set -- -p udp -m socket --transparent \
                -j MARK --set-mark "$TABLE_MARK"
          $iptables -w -t "$table" -I "$chain" "$@" >/dev/null 2>&1

          set -- -p udp -j TPROXY \
                --on-ip "$PROXY_IP" \
                --on-port "$SKEEN_TPROXY_PORT" \
                --tproxy-mark "$TABLE_MARK"
          $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
        fi
      ;;
      tproxy)
        for net in $SKEEN_FIREWALL_NETWORK; do
          set -- -p "$net" -m socket --transparent \
                  -j MARK --set-mark "$TABLE_MARK"
          $iptables -w -t "$table" -I "$chain" "$@" >/dev/null 2>&1

          set -- -p "$net" -j TPROXY \
                --on-ip "$PROXY_IP" \
                --on-port "$SKEEN_TPROXY_PORT" \
                --tproxy-mark "$TABLE_MARK"
          $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
        done
      ;;
      redirect)
        set -- -p tcp -j REDIRECT --to-port "$SKEEN_REDIRECT_PORT"
        $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
      ;;
      *) return 0 ;;
    esac
  fi

  if [ "$table" = "$TABLE_TPROXY" ]; then
    chain="$CHAIN_OUTPUT"

    if ! $iptables -t "$table" -nL "$chain" >/dev/null 2>&1; then
      $iptables -t "$table" -N "$chain" || return 0

      set_exclude_rules "$iptables" "$table" "$chain"

      for net in $SKEEN_FIREWALL_NETWORK; do
        set -- -p "$net" -j CONNMARK --set-mark "$TABLE_MARK"
        $iptables -w -t "$table" -A "$chain" "$@" >/dev/null 2>&1
      done
    fi
  fi
}


set_prerouting_rules() {
  iptables="$1"
  base_table="$2"
  connmark_option=""

  for net in $SKEEN_FIREWALL_NETWORK; do
    table="$base_table"
    proto_arg=""

    if [ "$SKEEN_FIREWALL_MODE" = "hybrid" ]; then
      case "$net" in
        tcp)
          table="$TABLE_REDIRECT"
          proto_arg="-p tcp"
        ;;
        udp)
          table="$TABLE_TPROXY"
          proto_arg="-p udp"
        ;;
        *) continue ;;
      esac
    fi

    [ -n "$SKEEN_MARK_POLICY" ] &&
      connmark_option="-m connmark --mark $SKEEN_MARK_POLICY"

    ports=""
    dports_op=""

    if [ -n "$INTERCEPT_PORTS" ]; then
      ports="$INTERCEPT_PORTS"
      dports_op="--dports"
    elif [ -n "$EXCLUDE_PORTS" ]; then
      ports="$EXCLUDE_PORTS"
      dports_op="! --dports"
    fi

    if [ -z "$ports" ]; then
      # shellcheck disable=SC2086
      set -- PREROUTING \
        $connmark_option \
        -m conntrack ! --ctstate INVALID \
        $proto_arg \
        -j "$CHAIN_PREROUTING"

      if ! $iptables -t "$table" -C "$@" >/dev/null 2>&1; then
        $iptables -t "$table" -A "$@" >/dev/null 2>&1
      fi
      continue
    fi

    validate_ports() {
      for p in $(echo "$1" | tr ', ' '\n' | sed '/^$/d'); do
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
          *[!0-9]*|'') return 1 ;;
        esac

        [ "$start" -ge 1 ] && [ "$end" -le 65535 ] && [ "$start" -le "$end" ] || return 1
      done
      return 0
    }

    if ! validate_ports "$ports"; then
      stop
      exiterr "Invalid ports definition: $ports"
    fi

    ports_list="$(printf '%s\n' "$ports" | tr ', ' '\n' | sed '/^$/d')"
    total=$(printf '%s' "$ports_list" | wc -l)
    i=1

    while [ "$i" -le "$total" ]; do
      chunk="$(printf '%s\n' "$ports_list" |
              sed -n "${i},$((i+6))p" |
              tr '\n' ',' |
              sed 's/,$//')"

      [ -z "$chunk" ] && break

      # shellcheck disable=SC2086
      set -- PREROUTING \
        $connmark_option \
        -m conntrack ! --ctstate INVALID \
        $proto_arg \
        -m multiport $dports_op "$chunk" \
        -j "$CHAIN_PREROUTING"

      if ! $iptables -t "$table" -C "$@" >/dev/null 2>&1; then
        $iptables -t "$table" -A "$@" >/dev/null 2>&1
      fi

      i=$((i + 7))
    done
  done
}


add_output_rules() {
  iptables="$1"
  table="$2"

  case "$SKEEN_FIREWALL_MODE" in
    tproxy)
      set -- OUTPUT \
          -m owner ! --gid-owner skeen-box \
          -m conntrack ! --ctstate INVALID \
          ! -p icmp \
          -j "$CHAIN_OUTPUT"
    ;;
    hybrid)
      set -- OUTPUT \
          -m owner ! --gid-owner skeen-box \
          -m conntrack ! --ctstate INVALID \
          -p udp \
          -j "$CHAIN_OUTPUT"
    ;;
    *) return 0 ;;
  esac

  if ! $iptables -t "$table" -C "$@" >/dev/null 2>&1; then
    $iptables -t "$table" -A "$@" >/dev/null 2>&1
  fi
}


prepare_firewall(){
  ip_v4=0
  ip_v6=0

  echomsg "Preparing a firewall..."

  complete_msg="Firewall preparation is complete"

  redirect_data="$(get_inbounds_data "redirect")"
  SKEEN_REDIRECT_PORT="$(echo "$redirect_data" | cut -d'|' -f1)"

  tproxy_data="$(get_inbounds_data "tproxy")"
  SKEEN_TPROXY_PORT="$(echo "$tproxy_data" | cut -d'|' -f1)"
  SKEEN_TPROXY_NETWORK="$(echo "$tproxy_data" | cut -d'|' -f2)"

  SKEEN_USE_DNS_CONFIG="0"
  if has_dns_servers; then
    SKEEN_USE_DNS_CONFIG="1"
    echomsg "Detected use of DNS configuration"
  fi

  if [ -n "$SKEEN_TPROXY_PORT" ] && [ "$SKEEN_TPROXY_NETWORK" = "tcpudp" ]; then
    SKEEN_FIREWALL_MODE="tproxy"
  elif [ -n "$SKEEN_REDIRECT_PORT" ] && [ -n "$SKEEN_TPROXY_PORT" ] && [ "$SKEEN_TPROXY_NETWORK" != "tcp" ]; then
    SKEEN_FIREWALL_MODE="hybrid"
  elif [ -n "$SKEEN_REDIRECT_PORT" ]; then
    SKEEN_FIREWALL_MODE="redirect"
  else
    SKEEN_FIREWALL_MODE="none"
  fi
  echomsg "Detected firewall mode: $SKEEN_FIREWALL_MODE"

  if [ "$SKEEN_FIREWALL_MODE" = "none" ]; then
    echook "$complete_msg"
    return 0
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "redirect" ]; then
    SKEEN_FIREWALL_NETWORK="tcp"
  else
    SKEEN_FIREWALL_NETWORK="tcp udp"

    check_router_port
  fi

  loading_modules

  echomsg "Detected firewall networks: $SKEEN_FIREWALL_NETWORK"

  SKEEN_MARK_POLICY="$(get_mark_policy)"

  SKEEN_IPTABLES_LIST="$(get_iptables_list)"

  SKEEN_EXCLUDE_v4_ADDRESSES=""
  if echo "$SKEEN_IPTABLES_LIST" | grep -q "iptables"; then
    ip_v4=1
    SKEEN_EXCLUDE_v4_ADDRESSES="$(get_exclude_addresses "4")"
  fi

  SKEEN_EXCLUDE_v6_ADDRESSES=""
  if echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6tables"; then
    ip_v6=1
    SKEEN_EXCLUDE_v6_ADDRESSES="$(get_exclude_addresses "6")"
  fi

  [ -f "$FIREWALL_HOOK_FILE" ] && rm -f "$FIREWALL_HOOK_FILE"

  {
    echo "#!/bin/sh"
    echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"

    echo "[ -z \"\$(pidof \"$SINGBOX_PROC\")\" ] && exit 0"

    echo "[ -f \"$TMP_WAIT_DEFAULT_ROUTE\" ] && exit 0"

    echo "export SKEEN_REDIRECT_PORT=\"$SKEEN_REDIRECT_PORT\""
    echo "export SKEEN_TPROXY_PORT=\"$SKEEN_TPROXY_PORT\""
    echo "export SKEEN_TPROXY_NETWORK=\"$SKEEN_TPROXY_NETWORK\""
    echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""
    echo "export SKEEN_FIREWALL_NETWORK=\"$SKEEN_FIREWALL_NETWORK\""
    echo "export SKEEN_MARK_POLICY=\"$SKEEN_MARK_POLICY\""
    echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""
    [ $ip_v4 -eq 1 ] && echo "export SKEEN_EXCLUDE_v4_ADDRESSES=\"$SKEEN_EXCLUDE_v4_ADDRESSES\""
    [ $ip_v6 -eq 1 ] && echo "export SKEEN_EXCLUDE_v6_ADDRESSES=\"$SKEEN_EXCLUDE_v6_ADDRESSES\""
    echo "export SKEEN_USE_DNS_CONFIG=\"$SKEEN_USE_DNS_CONFIG\""

    echo "echo \"\$SKEEN_IPTABLES_LIST\" | grep -q \"\$type\" || exit 0"
    echo "[ \"\$table\" != \"$TABLE_TPROXY\" ] && [ \"\$table\" != \"$TABLE_REDIRECT\" ] && exit 0"
    [ "$SKEEN_FIREWALL_NETWORK" = "redirect" ] && echo "[ \"\$table\" != \"$TABLE_REDIRECT\" ] && exit 0"
    [ "$SKEEN_FIREWALL_NETWORK" = "tproxy" ] && echo "[ \"\$table\" != \"$TABLE_TPROXY\" ] && exit 0"

    echo "logger -p notice -t \"$SKEEN_NAME\" \"Updating \$type rules for \$table\""

    echo "$SKEEN_SCRIPT apply_firewall"
  } > "$FIREWALL_HOOK_FILE"

  chmod +x "$FIREWALL_HOOK_FILE"

  echook "$complete_msg"
}


apply_firewall(){
  is_running || return 0

  [ "$SKEEN_FIREWALL_MODE" = "none" ] && return 0

  echomsg "Applying firewall rules..."

  for iptables in $SKEEN_IPTABLES_LIST; do
    if [ "$iptables" = "ip6tables" ]; then
      IP_VERSION="6"
      PROXY_IP="::1"
      EXCLUDE_ADDRESSES="$SKEEN_EXCLUDE_v6_ADDRESSES"
    elif [ "$iptables" = "iptables" ]; then
      IP_VERSION="4"
      PROXY_IP="127.0.0.1"
      EXCLUDE_ADDRESSES="$SKEEN_EXCLUDE_v4_ADDRESSES"
    else
      exiterr "Unknown iptables: $iptables"
    fi

    set_route_rules

    if [ -f "$TMP_WAIT_DEFAULT_ROUTE" ]; then
      EXCLUDE_ADDRESSES="$(get_exclude_addresses "$IP_VERSION")"
      sed -i "/SKEEN_EXCLUDE_v${IP_VERSION}/c\export SKEEN_EXCLUDE_v${IP_VERSION}_ADDRESSES=\"$EXCLUDE_ADDRESSES\"" "$FIREWALL_HOOK_FILE"
    fi

    if [ "$SKEEN_FIREWALL_MODE" = "hybrid" ]; then
      for table in "$TABLE_TPROXY" "$TABLE_REDIRECT"; do
        set_iptables_rules "$iptables" "$table" "$CHAIN_PREROUTING"
        set_prerouting_rules "$iptables" "$table"
      done
    elif [ "$SKEEN_FIREWALL_MODE" = "tproxy" ]; then
      set_iptables_rules "$iptables" "$TABLE_TPROXY" "$CHAIN_PREROUTING"
      set_prerouting_rules "$iptables" "$TABLE_TPROXY"
    elif [ "$SKEEN_FIREWALL_MODE" = "redirect" ]; then
      set_iptables_rules "$iptables" "$TABLE_REDIRECT" "$CHAIN_PREROUTING"
      set_prerouting_rules "$iptables" "$TABLE_REDIRECT"
    fi

    if [ "$SKEEN_FIREWALL_MODE" != "redirect" ]; then
      set_iptables_rules "$iptables" "$TABLE_TPROXY" "$CHAIN_OUTPUT"
      add_output_rules "$iptables"
    fi
  done

  [ -f "$TMP_WAIT_DEFAULT_ROUTE" ] && rm -f "$TMP_WAIT_DEFAULT_ROUTE"

  echook "Firewall rules applied successfully."
}


clean_firewall(){
  [ -f "$FIREWALL_HOOK_FILE" ] && : > "$FIREWALL_HOOK_FILE"

  clean_chain() {
    iptables="$1"
    table="$2"
    chain="$3"
    parent="$4"

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
    for tbl in nat mangle; do
      clean_chain "$ipt_cmd" "$tbl" "$CHAIN_PREROUTING" PREROUTING
      clean_chain "$ipt_cmd" "$tbl" "$CHAIN_OUTPUT"     OUTPUT
    done
  done

  if command -v ip >/dev/null 2>&1; then
    for ip_ver in 4 6; do
      if ip -"$ip_ver" rule show | grep -q "fwmark $TABLE_MARK lookup $TABLE_ID"; then
        ip -"$ip_ver" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1
        ip -"$ip_ver" route flush table "$TABLE_ID" >/dev/null 2>&1
      fi
    done
  fi
}


start() {
  if [ "$CALLER" = "init" ]; then
    if [ "$AUTO_START" = "0" ]; then
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
    echook "$SINGBOX_NAME already started"
    return 0
  fi

  echomsg "Starting ${SINGBOX_NAME}..."

  $SINGBOX_PROC check -C $CONFIG_DIR || press_any_key_to_menu

  prepare_firewall

  if ! id "skeen-box" >/dev/null 2>&1; then
    adduser -D -H -u 3228 "skeen-box"
    sed -i "/^skeen-box:/c\skeen-box:x:0:3228:::" /opt/etc/passwd
  fi

  # shellcheck disable=SC2086
  start-stop-daemon -S -b -x $SINGBOX_PROC -c "skeen-box" -- $SINGBOX_ARGS
  status_start=$?

  sleep 1

  if [ $status_start -eq 0 ]; then
    [ "$SKEEN_FIREWALL_MODE" != "none" ] && apply_firewall
    echook "$SINGBOX_NAME started."
    logger_notice "$SINGBOX_NAME started"
    return 0
  fi

  [ "$SKEEN_FIREWALL_MODE" != "none" ] && clean_firewall
  echoerr "Failed to start $SINGBOX_NAME"
  logger_error "$SINGBOX_NAME failed to start"
  return 1
}


stop(){
  echomsg "Stopping ${SINGBOX_NAME}..."

  clean_firewall

  if ! is_running; then
    echook "$SINGBOX_NAME already stopped"
    return 0
  fi

  start-stop-daemon -K -x $SINGBOX_PROC >/dev/null
  status_stop=$?

  sleep 1

  if [ $status_stop -eq 0 ]; then
    echook "$SINGBOX_NAME stopped."
    logger_notice "Stopped"
    return 0
  else
    echoerr "Failed to stop $SINGBOX_NAME"
    logger_error "Failed to stop"
    return 1
  fi
}


kill_proc(){
  if ! is_running; then
    echook "$SINGBOX_NAME is not running"
    return 0
  fi

  echo "Killing ${SINGBOX_PROC}..."
  killall -9 "$SINGBOX_PROC" 2>/dev/null
  clean_firewall
}


switch_state(){
  if is_running; then
    stop
  else
    start
  fi
  press_any_key_to_menu
}


restart() {
  stop; start
  press_any_key_to_menu
}


switch_autostart(){
  if [ "$AUTO_START" = "1" ]; then
    update_conf_var "AUTO_START" "0"
    echook "Autostart disabled"
  else
    update_conf_var "AUTO_START" "1"
    echook "Autostart enabled"
  fi

  press_any_key_to_menu
}


update_core(){
  is_running && stop
  get_os_release
  get_architecture
  download_singbox "$latest_sb_ver" || return 1
  install_singbox

  echook "The $SINGBOX_NAME core has been successfully updated"
}


update_skeen(){
  pkg_name="${SKEEN_NAME}-v${latest_sk_ver}.tar.gz"
  pkg_url="${SKEEN_ARCHIVE_URL}/${pkg_name}"

  echomsg "Downloading $pkg_name ..."

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR" || exit

  curl --fail --connect-timeout 5 --max-time 90 -Lo "$pkg_name" "$pkg_url"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    echoerr "Failed to download $pkg_name"
    return 1
  fi
  echook "Downloaded $pkg_name successfully."

  tmp_unpack_dir="${TMP_DIR}/${SKEEN_NAME}-unpack"

  if [ -d "$tmp_unpack_dir" ]; then
    rm -rf "$tmp_unpack_dir"
  fi

  echomsg "Extracting $pkg_name"
  mkdir "$tmp_unpack_dir"
  cd "$tmp_unpack_dir" || exit
  tar -xf "../${pkg_name}" --strip-components=1
  echook "Extraction completed."

  echomsg "Installing $SKEEN_NAME to $SKEEN_SCRIPT"
  mkdir -p "$(dirname "$SKEEN_SCRIPT")"

  [ -f "$SKEEN_SCRIPT" ] && rm -f "$SKEEN_SCRIPT"

  if [ -f "install.sh" ]; then
    mv ./install.sh "$SKEEN_SCRIPT"
    chmod 755 "$SKEEN_SCRIPT"
    chmod +x "$SKEEN_SCRIPT"
    echook "$SKEEN_NAME installed successfully."
  else
    echoerr "install.sh not found in archive!"
  fi

  echomsg "Cleaning up temporary files..."
  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${pkg_name}"
  echook "Cleanup completed."

  echook "The $SKEEN_NAME has been successfully updated"
}


check_update(){
  echomsg "Checking $SINGBOX_NAME for updates..."

  current_sb_ver="$(get_current_version "$SINGBOX_PROC")"
  latest_sb_ver="$(get_latest_version "$SINGBOX_API_URL")"

  if [ -z "$current_sb_ver" ]; then
    if [ -f "$SINGBOX_BIN" ]; then
      echoerr "Failed to get $SINGBOX_NAME version"
    else
      update_core
      current_sb_ver="$(get_current_version "$SINGBOX_PROC")"
      latest_sb_ver="$current_sb_ver"
    fi
  fi

  if [ -n "$latest_sb_ver" ] && [ -n "$current_sb_ver" ]; then
    if [ "$latest_sb_ver" != "$current_sb_ver" ]; then
      printf "%s %s\n" "$(cyan "New version of the $SINGBOX_NAME core is available:")" "$(green "$latest_sb_ver")"
      printf "%s %s\n" "$(cyan "Current installed version:")" "$(red "$current_sb_ver")"
      printf "%s %s\n" "$(cyan "More details:")" "$(green "https://github.com/SagerNet/sing-box/releases")"

      while :; do
        printf "Perform the update? [y/n] (default: n): " > /dev/tty
        read -r option < /dev/tty

        [ -z "$option" ] && option="n"

        case "$option" in
          y|Y)
            update_core
            break
          ;;
          n|N)
            break
          ;;
          *)
            echoerr "Incorrect option"
          ;;
        esac
      done
    else
      echook "The latest $SINGBOX_NAME version $latest_sb_ver is already installed"
    fi
  fi

  echomsg "Checking $SKEEN_NAME for updates..."

  current_sk_ver="$(get_current_version "skeen")"
  latest_sk_ver="$(get_latest_version "$SKEEN_API_URL")"

  if [ -z "$current_sk_ver" ]; then
    echoerr "Failed to get $SKEEN_NAME version"
  fi

  if [ -n "$latest_sk_ver" ] && [ -n "$current_sk_ver" ]; then
    if [ "$latest_sk_ver" != "$current_sk_ver" ]; then
      printf "%s %s\n" "$(cyan "New version $SKEEN_NAME script is available:")" "$(green "$latest_sk_ver")"
      printf "%s %s\n" "$(cyan "Current installed version:")" "$(red "$current_sk_ver")"
      printf "%s %s\n" "$(cyan "More details:")" "$(green "https://github.com/jinndi/SKeen/releases")"

      while :; do
        printf "Perform the update? [y/n] (default: n): " > /dev/tty
        read -r option < /dev/tty

        [ -z "$option" ] && option="n"

        case "$option" in
          y|Y)
            update_skeen
            break
          ;;
          n|N)
            break
          ;;
          *)
            echoerr "Incorrect option"
          ;;
        esac
      done
    else
      echook "The latest $SKEEN_NAME version $latest_sk_ver is already installed"
    fi
  fi

  press_any_key_to_menu "reload"
}


show_menu(){
  show_header

  if [ "$AUTO_START" = "1" ]; then
    autostart_status="$(green "yes")"
    autostart_text="Disable"
  else
    autostart_status="$(red "no")"
    autostart_text="Enable"
  fi

  if is_running; then
    set -a
    eval "$(grep '^export ' "$FIREWALL_HOOK_FILE" | sed 's/^export //')"
    set +a
    running_status="$(green "running")"
    running_text="Stop"
  else
    running_status="$(red "stopped")"
    running_text="Start"
  fi

  printf "\n %s %s" "$SKEEN_NAME version:" "$(cyan "v$(get_current_version "skeen")")"
  printf "\n %s %s" "$SINGBOX_NAME version:" "$(cyan "v$(get_current_version "$SINGBOX_PROC")")"
  printf "\n %s %s" "$SINGBOX_NAME state:" "$running_status"
  printf "\n %s %s" "Start automatically:" "$autostart_status"
  if [ "$running_text" = "Stop" ]; then
    echo "$SKEEN_IPTABLES_LIST" | grep -q "ipt" && ipv4="$(cyan "4")"
    echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6t" && ipv6="$(cyan "6")"

    sb_dns_work_text="$(red "no")"
    if [ "$SKEEN_USE_DNS_CONFIG" = "1" ]; then
      sb_dns_work_text="$(green "yes")"
    fi

    printf "\n %s %s" "${SINGBOX_NAME} DNS working:" "$sb_dns_work_text"
    printf "\n %s %s" "Firewall mode:" "$(cyan "$SKEEN_FIREWALL_MODE")"
    printf "\n %s %s" "Firewall network:" "$(cyan "$SKEEN_FIREWALL_NETWORK")"
    printf "\n %s %s" "Firewall IP ver.:" "$ipv4 $ipv6"
  fi

  printf "\n\n%s\n" "$(cyan "Select option:")"
  printf "  %s $running_text ${SINGBOX_NAME}\n" "$(green "1.")"
  printf "  %s Restart ${SINGBOX_NAME}\n" "$(green "2.")"
  printf "  %s $autostart_text Autostart\n" "$(green "3.")"
  printf "  %s Check Updates\n" "$(green "4.")"
  printf "  %s Uninstall ${SKEEN_NAME}\n" "$(green "5.")"
  printf "  %s Exit\n" "$(green "6.")"

  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    printf "\nEnter your selection [1-6]: " > /dev/tty
    read -r option < /dev/tty

    printf "\n"

    if echo "$option" | grep -Eq '^[1-5]$'; then
      echo "$DELIMETER"

      case "$option" in
        1) switch_state ;;
        2) restart ;;
        3) switch_autostart ;;
        4) check_update ;;
        5) accept_uninstall ;;
      esac
    else
      [ "$option" = 6 ] && exit 0
      echoerr "Incorrect option"
      attempt=$((attempt+1))
    fi
  done

  exiterr "Maximum attempts reached, exiting menu."
 }


if [ -f "$SKEEN_SCRIPT" ]; then
  case "$ACTION" in
    start)   start ;;
    stop)    stop ;;
    restart) restart ;;
    status)  if is_running; then echook "running"; else echoerr "stopped"; fi ;;
    kill)    kill_proc ;;
    version) echomsg "$SKEEN_NAME v$(get_current_version "skeen")" ;;
    apply_firewall) apply_firewall ;;
    clean_firewall) clean_firewall ;;
    "") show_menu ;;
    *) echomsg "Usage: skeen (start|stop|restart|status|kill|version)" ;;
  esac
else
  install
fi

#!/bin/sh
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

DEPENDENCIES="ndmc start-stop-daemon iptables curl tar jsonfilter logger"

ENTWARE_DIR="/opt"
WORK_DIR="${ENTWARE_DIR}/etc/skeen"
CONFIG_DIR="${WORK_DIR}/config"
TMP_DIR="${ENTWARE_DIR}/tmp"
NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
MODULES_OS_DIR="/lib/modules"
MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"

SKEEN_NAME="SKeen"
SKEEN_VERSION="3.6.10"
SKEEN_PROC="skeen"
SKEEN_SCRIPT="${ENTWARE_DIR}/bin/${SKEEN_PROC}"
SKEEN_SCRIPT_URL="https://github.com/jinndi/SKeen/releases/latest/download/skeen"
SKEEN_API_URL="https://api.github.com/repos/jinndi/SKeen/releases/latest"
SKEEN_CONFIG="${WORK_DIR}/${SKEEN_PROC}.conf"
SKEEN_AUTOSTART_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"

SINGBOX_NAME="Sing-box"
SINGBOX_PROC="skeen-box"
SINGBOX_ARGS="run -D $WORK_DIR -C $CONFIG_DIR"
SINGBOX_BIN="${ENTWARE_DIR}/bin/${SINGBOX_PROC}"
SINGBOX_API_URL="https://api.github.com/repos/SagerNet/sing-box/releases/latest"

FIREWALL_HOOK_FILE="${NETFILTER_DIR}/${SKEEN_PROC}_firewall.sh"
WAIT_ROUTE_FILE="${TMP_DIR}/${SKEEN_PROC}_wait_route"
CHAIN_PREROUTING="skeen"
CHAIN_OUTPUT="skeen_mask"
TABLE_REDIRECT="nat"
TABLE_TPROXY="mangle"
TABLE_MARK="0x112"
TABLE_ID="112"
DNS_PORT=53

SYS_INET_TEST_IPV4_HOSTS="1.1.1.1 77.88.8.8 223.5.5.5"
SYS_INET_TEST_IPV6_HOSTS="2606:4700:4700::1111 2a02:6b8::feed:0ff 2400:3200::1"
SYS_HIJACK_DNS_IPV4_SUBNET="192.168.0.0/16"
SYS_HIJACK_DNS_IPV6_SUBNET="fe80::/10"

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


setup_traps() {
  cleanup() { stty sane < /dev/tty 2>/dev/null || true; }
  trap cleanup EXIT TERM
  trap 'printf "\n"; cleanup; exit 130' INT
}

setup_traps


create_skeen_config(){
  mkdir -p "$(dirname "$SKEEN_CONFIG")"
  [ -f "$SKEEN_CONFIG" ] && rm -f "$SKEEN_CONFIG"

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
    echo "INET_TEST_IPV4_HOSTS=\"$SYS_INET_TEST_IPV4_HOSTS\""
    echo "INET_TEST_IPV6_HOSTS=\"$SYS_INET_TEST_IPV6_HOSTS\""
    echo
    echo "# Subnet for intercepting DNS queries (maximum one per IP version)"
    echo "HIJACK_DNS_IPV4_SUBNET=\"$SYS_HIJACK_DNS_IPV4_SUBNET\""
    echo "HIJACK_DNS_IPV6_SUBNET=\"$SYS_HIJACK_DNS_IPV6_SUBNET\""
    echo
    echo "# Router policy name for $SKEEN_NAME traffic"
    echo "POLICY_NAME=\"${SKEEN_NAME}\""
    echo
    echo "# Ports to intercept and redirect via TProxy/Redirect (all ports if not specified)"
    echo "# List: port and port ranges use colon e.g. 80,443,1000:2000 or 80 443 1000:2000"
    echo "INTERCEPT_PORTS=\"\""
    echo
    echo "# Ports to be excluded from redirect via TProxy/Redirect"
    echo "# List: port and port ranges use colon e.g. 8080,1443,1300:2300 or 8080 1443 1300:2300"
    echo "EXCLUDE_PORTS=\"\""
    echo
    echo "# Excluded ip addresses for traffic redirection"
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

loading_config(){
  [ -f "$SKEEN_CONFIG" ] || create_skeen_config
  # shellcheck disable=SC1090
  . "$SKEEN_CONFIG"
}

[ "$ACTION" != "apply_firewall" ] && loading_config

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
  case "$1" in
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
  cyan "

░█▀▀▀█ ░█ ▄▀ █▀▀ █▀▀ █▀▀▄
─▀▀▀▄▄ ░█▀▄  █▀▀ █▀▀ █  █
░█▄▄▄█ ░█ ░█ ▀▀▀ ▀▀▀ ▀  ▀"
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
  opkg_arch=$(opkg print-architecture 2>/dev/null | \
    grep -E 'mipsel|mipsle|mips64el|mips64le|mips64|mips|aarch64|arm64|armv8' | \
    head -n1 | awk '{print $2}' | tr '[:upper:]' '[:lower:]')

  case "$opkg_arch" in
    *aarch64*|*arm64*|*armv8*) ARCH="aarch64" ;;
    *mipsel*|*mipsle*)         ARCH="mipsel" ;;
    *mips64el*|*mips64le*)     ARCH="mips64el" ;;
    *mips64*)                  ARCH="mips64" ;;
    *mips*)                    ARCH="mips" ;;
    *)                         ARCH="" ;;
  esac

  [ -z "$ARCH" ] && exiterr "Unsupported CPU architecture"

  cpu_info=$(tr '[:upper:]' '[:lower:]' </proc/cpuinfo)

  case "$ARCH" in
    aarch64)
      case "$(echo "$cpu_info" | grep -m1 'cpu part')" in
        *0xd03*) PKG_ARCH="${ARCH}_cortex-a53" ;;
        *0xd08*) PKG_ARCH="${ARCH}_cortex-a72" ;;
        *0xd0b*) PKG_ARCH="${ARCH}_cortex-a76" ;;
        *)       PKG_ARCH="${ARCH}_generic" ;; # fallback
      esac
    ;;
    mipsel)
      case "$cpu_info" in
        *74k*)   PKG_ARCH="${ARCH}_74kc" ;;
        *24kf*)  PKG_ARCH="${ARCH}_24kc_24kf" ;;
        *24k*)   PKG_ARCH="${ARCH}_24kc" ;;
        *) PKG_ARCH="${ARCH}_mips32" ;; # fallback 1004, 34k, ...
      esac
    ;;
    mips)
      case "$cpu_info" in
        *24k*)   PKG_ARCH="${ARCH}_24kc" ;;
        *4kec*)  PKG_ARCH="${ARCH}_4kec" ;;
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

  echook "Detected PKG ARCH: $PKG_ARCH"
}


wait_input(){
  oldstty=$(stty -g < /dev/tty)
  stty -icanon -echo min 1 time 0 < /dev/tty
  dd bs=1 count=1 < /dev/tty 2>/dev/null
  stty "$oldstty" < /dev/tty
  echo > /dev/tty
}


install_dependencies() {
  echomsg "Checking dependencies"

  opkg update >/dev/null 2>&1

  for pkg_name in $DEPENDENCIES; do
    printf "%s ... " "$pkg_name"

    if command -v "$pkg_name" >/dev/null 2>&1; then
      echook "Already installed"
      continue
    fi

    if opkg install "$pkg_name" >/dev/null 2>&1; then
      echook "Installed"
    else
      exiterr "Installation error"
    fi
  done

  echook "All dependencies are installed"
}


download_singbox(){
  version="${1:-}"

  if [ -z "$version" ]; then
    echomsg "Fetching the latest version number..."
    version="$(get_latest_version "$SINGBOX_API_URL")" || exit 1
    echook "Latest version is $version"
  fi

  PKG_NAME="sing-box_${version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
  pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${version}/${PKG_NAME}"

  echomsg "Downloading ${PKG_NAME}..."

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR" || exit

  if curl --fail --connect-timeout 5 --max-time 90 -Lo "$PKG_NAME" "$pkg_url"; then
    echook "Downloaded $PKG_NAME successfully"
  else
    echoerr "Failed to download $PKG_NAME"
    [ -n "$version" ] && return 1 || exit 1
  fi
}


install_singbox(){
  tmp_unpack_dir="${TMP_DIR}/sing-box-unpack"

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


create_singbox_config(){
  act="${1:-}"

  if [ "$act" != "force" ] && [ -d "$CONFIG_DIR" ] && \
    ls "$CONFIG_DIR"/*.json >/dev/null 2>&1;
  then
    echomsg "Configuration files already exist in ${CONFIG_DIR}, skipping creation"
    return
  fi

  echomsg "Creating default configuration files..."

  mkdir -p "$CONFIG_DIR"

  cat <<EOF > "$CONFIG_DIR/log.json"
{"log":{"disabled":false,"level":"debug","timestamp":true}}
EOF

  cat <<EOF > "$CONFIG_DIR/dns.json"
{"dns":{"servers":[{"type":"tls","tag":"dns-proxy","detour":"proxy","domain_resolver":"dns-resolver","server":"one.one.one.one"},{"type":"https","tag":"dns-direct","domain_resolver":"dns-resolver","server":"common.dot.dns.yandex.net"},{"type":"fakeip","tag":"fakeip","inet4_range":"198.18.0.0/15","inet6_range":"fc00::/18"},{"type":"udp","tag":"dns-resolver","server":"77.88.8.8"}],"rules":[{"rule_set":"adguard","action":"reject"},{"clash_mode":"Direct","server":"dns-direct"},{"rule_set":"geosite-cheburnet","server":"dns-direct"},{"query_type":["A","AAAA"],"disable_cache":true,"server":"fakeip"},{"clash_mode":"Global","server":"dns-proxy"}],"final":"dns-proxy","strategy":"prefer_ipv4","independent_cache":true}}
EOF

  cat <<EOF > "$CONFIG_DIR/inbounds.json"
{"inbounds":[{"type":"redirect","listen":"::","listen_port":2081,"tcp_fast_open":true,"tcp_multi_path":true},{"type":"tproxy","listen":"::","listen_port":2082,"network":"udp","udp_fragment":true,"udp_timeout":"5m"}]}
EOF

  cat <<EOF > "$CONFIG_DIR/outbounds.json"
{"outbounds":[{"tag":"proxy","type":"selector","default":"auto","interrupt_exist_connections":false,"outbounds":["auto","VLESS","direct"]},{"tag":"auto","type":"urltest","url":"http://www.gstatic.com/generate_204","interval":"5m","tolerance":50,"idle_timeout":"30m","interrupt_exist_connections":false,"outbounds":["VLESS"]},{"tag":"direct","type":"direct"},{"tag":"VLESS","type":"vless","uuid":"00000000-0000-0000-0000-00000000000","flow":"xtls-rprx-vision","packet_encoding":"xudp","server":"example.com","server_port":443,"tls":{"enabled":true,"alpn":["http/1.1","h2"],"server_name":"example.com","utls":{"enabled":true,"fingerprint":"firefox"}}}]}
EOF

  cat <<EOF > "$CONFIG_DIR/route.json"
{"route":{"rules":[{"action":"sniff","timeout":"500ms"},{"type":"logical","mode":"or","rules":[{"protocol":"dns"},{"port":53}],"action":"hijack-dns"},{"clash_mode":"Direct","outbound":"direct"},{"ip_is_private":true,"outbound":"direct"},{"type":"logical","mode":"or","rules":[{"network":"udp","port":443},{"protocol":"stun"}],"action":"reject"},{"clash_mode":"Global","outbound":"proxy"},{"rule_set":"geosite-cheburnet","outbound":"direct"}],"rule_set":[{"type":"remote","tag":"geosite-cheburnet","url":"https://github.com/jinndi/geosite-cheburnet/releases/latest/download/geosite-cheburnet.srs","download_detour":"direct","update_interval":"24h0m0s"},{"type":"remote","tag":"adguard","url":"https://github.com/jinndi/adguard-filter-list-srs/releases/latest/download/adguard-filter-list.srs","download_detour":"direct","update_interval":"24h0m0s"}],"final":"proxy","default_domain_resolver":"dns-resolver"}}
EOF

  cat <<EOF > "$CONFIG_DIR/experimental.json"
{"experimental":{"cache_file":{"enabled":true,"path":"cache.db","store_fakeip":true,"store_rdrc":true},"clash_api":{"external_controller":"0.0.0.0:9090","external_ui":"zashboard","external_ui_download_url":"https://github.com/Zephyruso/zashboard/archive/gh-pages.zip","external_ui_download_detour":"direct","default_mode":"rule"}}}
EOF

  $SINGBOX_PROC format -w -C $CONFIG_DIR

  echook "Configuration file created successfully"
}


create_autostart_script(){
  echomsg "Create $SKEEN_NAME autostart script at $SKEEN_AUTOSTART_SCRIPT"

  [ -f "$SKEEN_AUTOSTART_SCRIPT" ] && rm -f "$SKEEN_AUTOSTART_SCRIPT"

  mkdir -p "$(dirname "$SKEEN_AUTOSTART_SCRIPT")"

  {
    echo "#!/bin/sh"
    echo "PATH=$PATH"
    echo "$SKEEN_PROC start init"
  } > "$SKEEN_AUTOSTART_SCRIPT"

  chmod 755 "$SKEEN_AUTOSTART_SCRIPT"
  chmod +x "$SKEEN_AUTOSTART_SCRIPT"

  echook "Autostart script created successfully"
}


create_singbox_user(){
  if ! id "$SINGBOX_PROC" >/dev/null 2>&1; then
    echomsg "Create $SINGBOX_PROC user..."

    adduser -D -H -u 3228 "$SINGBOX_PROC"
    sed -i "/^${SINGBOX_PROC}:/c\\${SINGBOX_PROC}:x:0:3228:::" /opt/etc/passwd

    if id "$SINGBOX_PROC" >/dev/null 2>&1; then
      echook "$SINGBOX_PROC user created successfully"
    else
      exiterr "Failed to create $SINGBOX_PROC user"
    fi

    echook "Autostart script created successfully"
  fi
}


download_skeen_script(){
  action="${1:-}"
  backup_script="${SKEEN_SCRIPT}.backup"

  echomsg "Downloading $SKEEN_NAME script at $SKEEN_SCRIPT"

  [ -f "$SKEEN_SCRIPT" ] && mv "$SKEEN_SCRIPT" "$backup_script"

  if ! curl --fail --connect-timeout 5 --max-time 90 -Lo "$SKEEN_SCRIPT" "$SKEEN_SCRIPT_URL"; then
    [ -f "$SKEEN_SCRIPT" ] && rm -f "$SKEEN_SCRIPT"
    mv "$backup_script" "$SKEEN_SCRIPT"
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


press_any_key_to_menu(){
  [ "$CALLER" != "menu" ] && exit 1

  action="${1:-}"

  echo "$DELIMETER"

  printf "Press any key to open menu..." > /dev/tty
  wait_input

  if [ "$action" = "reload" ]; then
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
  create_singbox_user
  download_skeen_script

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

  echomsg "Removing firewall hook script..."
  rm -f "$FIREWALL_HOOK_FILE"

  echomsg "Removing $SKEEN_NAME script..."
  rm -f "$SKEEN_SCRIPT"

  echomsg "Delete user ${SINGBOX_PROC}..."
  deluser "$SINGBOX_PROC"

  if [ -d "$WORK_DIR" ]; then
    echomsg "Configuration directory $WORK_DIR is retained"
    echomsg "If you want to remove it manually, run: rm -rf $WORK_DIR"
  fi
  echook "${SKEEN_NAME} has been uninstalled successfully"
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
      y|Y) uninstall ;;
      n|N) break ;;
      *) echoerr "Incorrect option"; attempt=$((attempt+1)) ;;
    esac
  done

  show_menu
}


update_config_var(){
  key="${1:-}"
  val="${2:-}"

  [ -f "$SKEEN_CONFIG" ] || create_skeen_config

  if grep -q "^[[:space:]]*${key}[[:space:]]*=" "$SKEEN_CONFIG"; then
    sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|$key=$val|" "$SKEEN_CONFIG"
  else
    echo "$key=$val" >> "$SKEEN_CONFIG"
  fi

  loading_config
}


get_inet_tests_hosts() {
  ipv="${1:-}"
  hosts=""
  sys_hosts=""
  max="3"

  if [ "$ipv" = "4" ]; then
    hosts="$INET_TEST_IPV4_HOSTS"
    sys_hosts="$SYS_INET_TEST_IPV4_HOSTS"
  else
    hosts="$INET_TEST_IPV6_HOSTS"
    sys_hosts="$SYS_INET_TEST_IPV6_HOSTS"
  fi

  if [ -z "$hosts" ]; then
    echo "$sys_hosts"
  else
    hosts="$(echo "$hosts" | \
      tr ',\t' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')"

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
  hosts="$(get_inet_tests_hosts "4")"
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
  host="${1:-127.0.0.1}"
  port="${2:-443}"

  if (echo quit | telnet "$host" "$port" 2>/dev/null | grep -q "Connected"); then
    msg_err="Port $port must be freed"
    echoerr "$msg_err"
    echoerr "Free it and try running again"
    logger_error "$msg_err"
    press_any_key_to_menu
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
  path_os="${MODULES_OS_DIR}/$(uname -r)/${module}"

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
  modules="xt_TPROXY.ko xt_socket.ko xt_multiport.ko"

  case "$SKEEN_FIREWALL_MODE" in
    tproxy|hybrid)
      echomsg "Loading modules: xt_TPROXY.ko xt_socket.ko"
    ;;
  esac

  if [ -n "$INTERCEPT_PORTS" ] || [ -n "$EXCLUDE_PORTS" ]; then
    echomsg "Loading modules: xt_multiport.ko"
  fi

  if [ "$SKEEN_DNS_SUPPORTED" = "1" ] && ! is_owner_module_working; then
    echomsg "Loading modules: xt_owner.ko"
    load_module "xt_owner.ko"

    if ! is_owner_module_working; then
      SKEEN_DNS_SUPPORTED=0
      echowarn "iptables owner module is not working"
      echowarn "$SINGBOX_NAME DNS functionality will be disabled"
    fi
  fi

  modules="$(echo "$modules" | tr ' ' '\n' | sort -u)"

  for module in $modules; do
    if ! load_module "$module"; then
      echoerr "The '$SKEEN_FIREWALL_MODE' mode requires kernel modules"
      echoerr "Install router component: Kernel modules for Netfilter"
      logger_error "Missing Kernel modules for Netfilter"
      press_any_key_to_menu
    fi
  done

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

  if ! check_default_route; then
    [ -f "$WAIT_ROUTE_FILE" ] || touch "$WAIT_ROUTE_FILE"

    msg="Default route in table '$source_table' (IPv$IP_VERSION) not found"

    msg2="Check your internet connection"
    if [ -n "$SKEEN_MARK_POLICY" ]; then
      msg2="$msg2 for policy ${POLICY_NAME:-unknown}"
    fi

    echowarn "$msg"
    echowarn "$msg2"
    logger_warning "$msg"

    [ "$CALLER" != "menu" ] && exit 0

    press_any_key_to_menu
  fi

  ip -"$IP_VERSION" rule del fwmark "$TABLE_MARK" lookup "$TABLE_ID" >/dev/null 2>&1 || true
  ip -"$IP_VERSION" route flush table "$TABLE_ID" >/dev/null 2>&1 || true

  ip -"$IP_VERSION" route add local default dev lo table "$TABLE_ID"
  ip -"$IP_VERSION" rule add fwmark "$TABLE_MARK" lookup "$TABLE_ID"

  ip -"$IP_VERSION" route show table "$source_table" 2>/dev/null |
  while read -r r; do
    case "$r" in
      default*|blackhole*|unreachable*) continue ;;
    esac
    ip -"$IP_VERSION" route add table "$TABLE_ID" "$r" 2>/dev/null || true
  done
}


is_valid_ipv4() {
  addr="${1:-}"
  ip="${addr%%/*}"
  cidr="${addr#*/}"
  IFS=. read -r o1 o2 o3 o4 <<EOF
$ip
EOF

  [ "$o1" ] && [ "$o2" ] && [ "$o3" ] && [ "$o4" ] || return 1

  for o in $o1 $o2 $o3 $o4; do
    [ "$o" -ge 0 ] 2>/dev/null || return 1;
    [ "$o" -le 255 ] 2>/dev/null || return 1;
  done

  if [ "$ip" != "$addr" ]; then
    case "$cidr" in ''|[0-9]|[1-2][0-9]|3[0-2]) ;; *) return 1 ;; esac
  fi
}


is_valid_ipv6() {
  addr="${1:-}"
  ip_only="${addr%%/*}"
  cidr="${addr#*/}"

  ip -6 route get "$ip_only" >/dev/null 2>&1 || return 1

  if [ "$ip_only" != "$addr" ]; then
    case "$cidr" in
      ''|[0-9]|[1-9][0-9]|1[0-2][0-8]) ;;
      *) return 1 ;;
    esac
  fi
}


get_hijack_dns_subnet() {
  ipv="${1:-}"
  subnet=""
  sys_subnet=""

  case "$ipv" in
    4)
      validator=is_valid_ipv4
      subnet="$HIJACK_DNS_IPV4_SUBNET"
      sys_subnet="$SYS_HIJACK_DNS_IPV4_SUBNET"
    ;;
    6)
      validator=is_valid_ipv6
      subnet="$HIJACK_DNS_IPV6_SUBNET"
      sys_subnet="$SYS_HIJACK_DNS_IPV6_SUBNET"
    ;;
  esac

  if $validator "$subnet"; then
    echo "$subnet"
  else
    echowarn "HIJACK_DNS is using the default subnet: $sys_subnet"
    echo "$sys_subnet"
  fi
}


get_exclude_addresses() {
  ip_v="${1:-}"
  eth_subnet=""
  reserved_subnets=""
  user_exclude=""

  [ "$ip_v" = "4" ] && prefix_length_default="32" || prefix_length_default="128"

  get_eth_subnet() {
    _ip_v="${1:-}"
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
    [ "${addr#*/}" = "$addr" ] && addr="$addr/$prefix_length_default"

    case "$ip_v" in
      4) validator=is_valid_ipv4 ;;
      6) validator=is_valid_ipv6 ;;
    esac

    if $validator "$addr"; then
      all_list="$all_list $addr"
    else
      echowarn "Invalid IPv$ip_v exclude address: $addr"
    fi
  done

  echo "$all_list" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}


set_exclude_rules() {
  iptables="${1:-}"
  table="${2:-}"
  chain="${3:-}"

  set_ipt() {
    $iptables -w -t "$table" -A "$chain" -d "$exclude" "$@" -j RETURN >/dev/null 2>&1
  }

  if [ "$chain" != "$CHAIN_OUTPUT" ] && \
    [ "$SKEEN_DNS_SUPPORTED" = "1" ] && \
    [ -n "$HIJACK_DNS_SUBNET" ];
  then
    exclude="$HIJACK_DNS_SUBNET"

    case "$SKEEN_FIREWALL_MODE:$table" in
      hybrid:mangle)
        set_ipt -p tcp --dport "$DNS_PORT"
        set_ipt -p udp ! --dport "$DNS_PORT"
      ;;
      hybrid:nat)
        set_ipt -p tcp ! --dport "$DNS_PORT"
        set_ipt -p udp --dport "$DNS_PORT"
      ;;
      tproxy:mangle)
        set_ipt -p tcp ! --dport "$DNS_PORT"
        set_ipt -p udp ! --dport "$DNS_PORT"
      ;;
    esac
  fi

  for exclude in $EXCLUDE_ADDRESSES; do
    [ "$HIJACK_DNS_SUBNET" = "$exclude" ] && continue
    set_ipt
  done
}


set_iptables_rules() {
  iptables="$1"
  table="$2"
  chain="$3"

  if [ "$chain" = "$CHAIN_PREROUTING" ] && \
    ! $iptables -t "$table" -nL "$chain" >/dev/null 2>&1;
  then
    $iptables -t "$table" -N "$chain" || return 0

    set_exclude_rules "$iptables" "$table" "$chain"

    case "$SKEEN_FIREWALL_MODE" in
      hybrid)
        if [ "$table" = "$TABLE_REDIRECT" ]; then
          rule="-p tcp -j REDIRECT --to-port $SKEEN_REDIRECT_PORT"
          # shellcheck disable=SC2086
          $iptables -w -t "$table" -A "$chain" $rule >/dev/null 2>&1
        else
          rule="-p udp -m socket --transparent \
                -j MARK --set-mark $TABLE_MARK"
          # shellcheck disable=SC2086
          $iptables -w -t "$table" -I "$chain" $rule >/dev/null 2>&1

          rule="-p udp -j TPROXY \
                --on-ip $PROXY_IP \
                --on-port $SKEEN_TPROXY_PORT \
                --tproxy-mark $TABLE_MARK"
          # shellcheck disable=SC2086
          $iptables -w -t "$table" -A "$chain" $rule >/dev/null 2>&1
        fi
      ;;
      tproxy)
        for net in $SKEEN_TPROXY_NETWORK; do
          rule="-p $net -m socket --transparent \
                  -j MARK --set-mark $TABLE_MARK"
          # shellcheck disable=SC2086
          $iptables -w -t "$table" -I "$chain" $rule >/dev/null 2>&1
          # shellcheck disable=SC2086
          rule="-p $net -j TPROXY \
                --on-ip $PROXY_IP \
                --on-port $SKEEN_TPROXY_PORT \
                --tproxy-mark $TABLE_MARK"
          # shellcheck disable=SC2086
          $iptables -w -t "$table" -A "$chain" $rule >/dev/null 2>&1
        done
      ;;
      redirect)
        rule="-p tcp -j REDIRECT --to-port $SKEEN_REDIRECT_PORT"
        # shellcheck disable=SC2086
        $iptables -w -t "$table" -A "$chain" $rule >/dev/null 2>&1
      ;;
      *) return 0 ;;
    esac
  fi

  if [ "$chain" = "$CHAIN_OUTPUT" ] && \
    ! $iptables -t "$table" -nL "$chain" >/dev/null 2>&1;
  then
    $iptables -t "$table" -N "$chain" || return 0

    set_exclude_rules "$iptables" "$table" "$chain"

    for net in $SKEEN_TPROXY_NETWORK; do
      rule="-p $net -j CONNMARK --set-mark $TABLE_MARK"
      # shellcheck disable=SC2086
      $iptables -w -t "$table" -A "$chain" $rule >/dev/null 2>&1
    done
  fi
}


set_prerouting_rules() {
  iptables="$1"
  base_table="$2"
  connmark_option=""

  case "$SKEEN_FIREWALL_MODE:$base_table" in
    hybrid:mangle|tproxy:mangle)
      rule="-j CONNMARK --restore-mark"
      # shellcheck disable=SC2086
      if ! $iptables -t "$base_table" -C PREROUTING $rule >/dev/null 2>&1; then
        $iptables -t "$base_table" -I PREROUTING 1 $rule >/dev/null 2>&1
      fi
    ;;
  esac

  for net in $SKEEN_FIREWALL_NETWORK; do
    table="$base_table"

    case "$net" in
      tcp)
        [ "$SKEEN_FIREWALL_MODE" = "tproxy" ] && \
        table="$TABLE_TPROXY" || \
        table="$TABLE_REDIRECT"
        proto_arg="-p tcp"
      ;;
      udp)
        table="$TABLE_TPROXY"
        proto_arg="-p udp"
      ;;
      *) continue ;;
    esac

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
      rule="PREROUTING \
        $connmark_option \
        -m conntrack ! --ctstate INVALID \
        $proto_arg \
        -j $CHAIN_PREROUTING"

      # shellcheck disable=SC2086
      if ! $iptables -t "$table" -C $rule >/dev/null 2>&1; then
        $iptables -t "$table" -A $rule >/dev/null 2>&1
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

    # shellcheck disable=SC2086
    set -- $ports_list
    total=$#
    i=1

    while [ "$i" -le "$total" ]; do
      chunk="$(printf '%s\n' "$ports_list" |
              sed -n "${i},$((i+6))p" |
              tr '\n' ',' |
              sed 's/,$//')"

      [ -z "$chunk" ] && break

      rule="PREROUTING \
        $connmark_option \
        -m conntrack ! --ctstate INVALID \
        $proto_arg \
        -m multiport $dports_op $chunk \
        -j $CHAIN_PREROUTING"

      # shellcheck disable=SC2086
      if ! $iptables -t "$table" -C $rule >/dev/null 2>&1; then
        $iptables -t "$table" -A $rule >/dev/null 2>&1
      fi

      i=$((i + 7))
    done
  done
}


add_output_rules() {
  iptables="$1"
  table="$2"

  case "$SKEEN_FIREWALL_MODE" in
    tproxy) proto='! -p icmp' ;;
    hybrid) proto='-p udp' ;;
    *) return 0 ;;
  esac

  rule="OUTPUT \
    -m owner ! --gid-owner $SINGBOX_PROC \
    -m conntrack ! --ctstate INVALID \
    $proto \
    -j $CHAIN_OUTPUT"

  # shellcheck disable=SC2086
  if ! $iptables -t "$table" -C $rule >/dev/null 2>&1; then
    $iptables -t "$table" -A $rule >/dev/null 2>&1
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

  if [ -n "$SKEEN_TPROXY_PORT" ] && [ "$SKEEN_TPROXY_NETWORK" = "tcpudp" ]; then
    SKEEN_FIREWALL_MODE="tproxy"
    SKEEN_TPROXY_NETWORK="tcp udp"
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

  SKEEN_DNS_SUPPORTED="0"
  if has_dns_servers; then
    echomsg "Detected use of DNS configuration"

    case "$SKEEN_FIREWALL_MODE" in
      tproxy|hybrid) SKEEN_DNS_SUPPORTED="1" ;;
      *) echowarn "In redirect mode, the DNS configuration is not used" ;;
    esac
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

  SKEEN_EXCLUDE_IPV4_ADDRESSES=""
  SKEEN_HIJACK_DNS_IPV4_SUBNET=""
  if echo "$SKEEN_IPTABLES_LIST" | grep -q "iptables"; then
    ip_v4=1
    SKEEN_EXCLUDE_IPV4_ADDRESSES="$(get_exclude_addresses "4")"
    SKEEN_HIJACK_DNS_IPV4_SUBNET="$(get_hijack_dns_subnet "4")"
  fi

  SKEEN_EXCLUDE_IPV6_ADDRESSES=""
  SKEEN_HIJACK_DNS_IPV6_SUBNET=""
  if echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6tables"; then
    ip_v6=1
    SKEEN_EXCLUDE_IPV6_ADDRESSES="$(get_exclude_addresses "6")"
    SKEEN_HIJACK_DNS_IPV6_SUBNET="$(get_hijack_dns_subnet "6")"
  fi

  [ -f "$FIREWALL_HOOK_FILE" ] && rm -f "$FIREWALL_HOOK_FILE"

  {
    echo "#!/bin/sh"
    echo "# $SKEEN_NAME v${SKEEN_VERSION} firewall hook"

    echo "[ -z \"\$(pidof \"$SINGBOX_PROC\")\" ] && exit 0"

    echo "export SKEEN_REDIRECT_PORT=\"$SKEEN_REDIRECT_PORT\""
    echo "export SKEEN_TPROXY_PORT=\"$SKEEN_TPROXY_PORT\""
    echo "export SKEEN_TPROXY_NETWORK=\"$SKEEN_TPROXY_NETWORK\""
    echo "export SKEEN_FIREWALL_MODE=\"$SKEEN_FIREWALL_MODE\""
    echo "export SKEEN_FIREWALL_NETWORK=\"$SKEEN_FIREWALL_NETWORK\""
    echo "export SKEEN_MARK_POLICY=\"$SKEEN_MARK_POLICY\""
    echo "export SKEEN_IPTABLES_LIST=\"$SKEEN_IPTABLES_LIST\""
    [ $ip_v4 -eq 1 ] && echo "export SKEEN_EXCLUDE_IPV4_ADDRESSES=\"$SKEEN_EXCLUDE_IPV4_ADDRESSES\""
    [ $ip_v6 -eq 1 ] && echo "export SKEEN_EXCLUDE_IPV6_ADDRESSES=\"$SKEEN_EXCLUDE_IPV6_ADDRESSES\""
    echo "export SKEEN_DNS_SUPPORTED=\"$SKEEN_DNS_SUPPORTED\""
    if [ "$SKEEN_DNS_SUPPORTED" = "1" ]; then
      [ $ip_v4 -eq 1 ] && echo "export SKEEN_HIJACK_DNS_IPV4_SUBNET=\"$SKEEN_HIJACK_DNS_IPV4_SUBNET\""
      [ $ip_v6 -eq 1 ] && echo "export SKEEN_HIJACK_DNS_IPV6_SUBNET=\"$SKEEN_HIJACK_DNS_IPV6_SUBNET\""
    fi
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

  for iptables in ${SKEEN_IPTABLES_LIST:-}; do
    if [ "$iptables" = "iptables" ]; then
      IP_VERSION="4"
      PROXY_IP="127.0.0.1"
      EXCLUDE_ADDRESSES="${SKEEN_EXCLUDE_IPV4_ADDRESSES:-}"
      HIJACK_DNS_SUBNET="${SKEEN_HIJACK_DNS_IPV4_SUBNET:-}"
    elif [ "$iptables" = "ip6tables" ]; then
      IP_VERSION="6"
      PROXY_IP="::1"
      EXCLUDE_ADDRESSES="${SKEEN_EXCLUDE_IPV6_ADDRESSES:-}"
      HIJACK_DNS_SUBNET="${SKEEN_HIJACK_DNS_IPV6_SUBNET:-}"
    else
      exiterr "Unknown iptables: $iptables"
    fi

    set_route_rules

    if [ -f "$WAIT_ROUTE_FILE" ]; then
      EXCLUDE_ADDRESSES="$(get_exclude_addresses "$IP_VERSION")"
      [ -n "${FIREWALL_HOOK_FILE:-}" ] && \
      sed -i "/SKEEN_EXCLUDE_IPV${IP_VERSION}/c\export SKEEN_EXCLUDE_IPV${IP_VERSION}_ADDRESSES=\"$EXCLUDE_ADDRESSES\"" "$FIREWALL_HOOK_FILE"
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
      add_output_rules "$iptables" "$TABLE_TPROXY"
    fi
  done

  [ -f "$WAIT_ROUTE_FILE" ] && rm -f "$WAIT_ROUTE_FILE"

  echook "Firewall rules applied successfully"
}


clean_firewall(){
  echomsg "Cleaning firewall rules..."

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

    if [ "$table" = "mangle" ] && [ "$parent" = "PREROUTING" ]; then
      while $iptables -w -t "$table" -D "$parent" -j CONNMARK --restore-mark >/dev/null 2>&1; do
        :
      done
    fi

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

  echook "Firewall cleanup completed"
}


start_singbox(){
  timeout=10

  echomsg "Starting ${SINGBOX_NAME}..."

  if [ -r /proc/sys/fs/file-max ]; then
    file_max=$(cat /proc/sys/fs/file-max)
    ulimit_n=$((file_max / 2))
  else
    # shellcheck disable=SC3045
    ulimit_n=$(ulimit -Hn)
  fi
  [ "$ulimit_n" -lt 4096 ] && ulimit_n=4096
  # shellcheck disable=SC3045
  ulimit -n "$ulimit_n" || exiterr "Failed to set ulimit -n"

  # shellcheck disable=SC2086
  start-stop-daemon -S -b -x $SINGBOX_PROC -c $SINGBOX_PROC -- $SINGBOX_ARGS
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

  check_config && echo "$DELIMETER"

  prepare_firewall && echo "$DELIMETER"

  start_singbox

  [ "$SKEEN_FIREWALL_MODE" != "none" ] && \
  echo "$DELIMETER" && apply_firewall

  return 0
}


stop_singbox(){
  timeout=10
  echomsg "Stopping ${SINGBOX_NAME}..."

  if ! is_running; then
    clean_firewall
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


stop(){
  stop_singbox && clean_firewall
  [ "$on_restart" = "1" ] && echo "$DELIMETER"
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
  on_restart=1
  stop
  [ "$CALLER" = "menu" ] && loading_config
  start
  on_restart=0
  press_any_key_to_menu
}


reload(){
  check_config && echo "$DELIMETER"
  stop_singbox && start_singbox
}


switch_autostart(){
  if [ "$AUTO_START" = "1" ]; then
    update_config_var "AUTO_START" "0"
    echook "Autostart disabled"
  else
    update_config_var "AUTO_START" "1"
    echook "Autostart enabled"
  fi

  press_any_key_to_menu
}


update_core(){
  is_running && stop && is_stopped=1
  get_os_release
  get_architecture
  download_singbox "$latest_sb_ver" || return 1
  install_singbox
  echook "The $SINGBOX_NAME core has been successfully updated"
}


update_skeen(){
  if download_skeen_script "update"; then
    echook "The $SKEEN_NAME has been successfully updated"
    is_update_skeen=1
  else
    echoerr "Failed to update $SKEEN_NAME"
  fi
}


check_updates(){
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

  is_stopped=0

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
          y|Y) update_core; break ;;
          n|N) break ;;
          *) echoerr "Incorrect option" ;;
        esac
      done
    else
      echook "The latest $SINGBOX_NAME version $latest_sb_ver is already installed"
    fi
  fi

  echomsg "Checking $SKEEN_NAME for updates..."

  current_sk_ver="$(get_current_version "$SKEEN_PROC")"
  latest_sk_ver="$(get_latest_version "$SKEEN_API_URL")"

  if [ -z "$current_sk_ver" ]; then
    echoerr "Failed to get $SKEEN_NAME version"
  fi

  is_update_skeen=0

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
          y|Y) update_skeen; break ;;
          n|N) break ;;
          *) echoerr "Incorrect option" ;;
        esac
      done
    else
      echook "The latest $SKEEN_NAME version $latest_sk_ver is already installed"
    fi
  fi

  [ "$is_stopped" = "1" ] && start

  [ "$CALLER" = "cli" ] && exit 0

  if [ $is_update_skeen -eq 1 ]; then
    exec sh "$SKEEN_SCRIPT" deps menu
  else
    press_any_key_to_menu "reload"
  fi
}


import_firewall_vars(){
  if [ -f "$FIREWALL_HOOK_FILE" ]; then
    set -a
    eval "$(grep '^export ' "$FIREWALL_HOOK_FILE" | sed 's/^export //')"
    set +a
  fi
}


fw_test() {
  # $1 — table
  # $2 — chain
  # $3 — content
  # $4 — grep pattern
  # $5 — test name (human readable)

  if echo "$3" | grep -Eq "$4"; then
    printf "[$1/$2] $5: %s\n" "$(green "exists")"
  else
    printf "[$1/$2] $5: %s\n" "$(red "missing")"
  fi
}


fw_test_chain() {
  # $1 — table
  # $2 — chain
  # $3 — iptables

  echomsg "Testing $3: $1 $2 chain"

  content="$($3 -w -t "$1" -nvL "$2" 2>/dev/null)"

  fw_test "$1" "$2" "$content" "[1-9][0-9]* references" "Chain reference"

  fw_test "$1" "$2" "$content" "$test_exclude_address" "Exclude addresses rule"

  if [ "$1" = "mangle" ] && [ "$2" = "$CHAIN_OUTPUT" ]; then
    fw_test "$1" "$2" "$content" "CONNMARK" "CONNMARK set rule"
  fi

  if [ "$1" = "mangle" ]; then
    fw_test "$1" "$2" "$($3 -t "$1" -nvL PREROUTING 2>/dev/null)" "CONNMARK restore" "CONNMARK restore rule"
  fi

  [ "$2" = "$CHAIN_OUTPUT" ] && return 0

  fw_test "$1" "$2" "$content" "redir|redirect" "Redirect rule"

  if [ "$SKEEN_DNS_SUPPORTED" = "1" ]; then
    fw_test "$1" "$2" "$content" "dpt:!?${DNS_PORT}" "DNS port ${DNS_PORT} rule"
  fi

  if [ -n "$INTERCEPT_PORTS" ] || [ -n "$EXCLUDE_PORTS" ]; then
    # shellcheck disable=SC2015
    fw_test "$1" "$2" "$($3 -t "$1" -nvL 2>/dev/null)" "multiport" "Multiport rule"
  fi
}


test_firewall() {
  if ! is_running; then
    echoerr "Testing are available only when $SINGBOX_NAME is running"
    press_any_key_to_menu
  else
    import_firewall_vars
  fi

  if [ ! -f "$FIREWALL_HOOK_FILE" ]; then
    echoerr "The file at path $FIREWALL_HOOK_FILE is missing!"
    echomsg "Please reboot $SINGBOX_NAME"
    press_any_key_to_menu
  fi

  if [ "$SKEEN_FIREWALL_MODE" = "none" ]; then
    echowarn "Testing is available in redirect, tproxy, and hybrid modes"
    press_any_key_to_menu
  elif [ "$SKEEN_FIREWALL_MODE" = "hybrid" ]; then
    tables="nat mangle"
  elif [ "$SKEEN_FIREWALL_MODE" = "tproxy" ]; then
    tables="mangle"
  else
    tables="nat"
  fi

  if [ -z "$SKEEN_IPTABLES_LIST" ]; then
    echoerr "iptables utility is not installed"
    press_any_key_to_menu
  fi

  for iptables in $SKEEN_IPTABLES_LIST; do
    if [ "$iptables" = "ip6tables" ]; then
      echo "$DELIMETER"
      test_exclude_address="2002::/16"
    elif [ "$iptables" = "iptables" ]; then
      test_exclude_address="0.0.0.0/8"
    fi

    for table in $tables; do
      fw_test_chain "$table" "$CHAIN_PREROUTING" "$iptables"
    done

    [ "$tables" != "nat"  ] && fw_test_chain mangle "$CHAIN_OUTPUT" "$iptables"
  done

  press_any_key_to_menu
}


backup_config(){
  if [ -d "$WORK_DIR" ] && [ "$(ls -A "$WORK_DIR")" ]; then
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


restore_config(){
  while :; do
    printf "Enter the name of the backup archive file\n"
    printf "located in the /opt root directory,\n"
    printf "for example %s: " "$(cyan "skeen.tar")" > /dev/tty
    read -r tarname < /dev/tty

    [ -z "$tarname" ] && press_any_key_to_menu

    archive_path="/opt/${tarname}"

    if [ -f "$archive_path" ] && tar -tf "$archive_path" | grep -q "^skeen/"; then
      rm -rf "${ENTWARE_DIR}/skeen"

      echomsg "Extracting archive..."

      if tar -xf "$archive_path" -C "$ENTWARE_DIR"; then
        rm -rf "$WORK_DIR"
        mv "${ENTWARE_DIR}/skeen" "$WORK_DIR"

        echook "Backup successfully restored"
      else
        echoerr "Error extracting archive $archive_path"
      fi
    else
      echoerr "Archive missing or 'skeen' folder not found"
      continue
    fi

    break
  done

  press_any_key_to_menu
}


reset_config(){
  while :; do
    printf "A full configuration reset will be performed,\n"
    printf "with a backup of the current configuration created\n"
    printf "Continue? [y/n]: " > /dev/tty
    read -r option < /dev/tty

    [ -z "$option" ] && option="n"

    case "$option" in
      y|Y)
        if backup_config; then
          rm -rf "$WORK_DIR"
          mkdir -p "$WORK_DIR"
          create_singbox_config "force"
          create_skeen_config
          echook "Configuration reset completed"
        else
          echoerr "Failed to reset configuration!"
        fi
        break
      ;;
      n|N) break ;;
      *) echoerr "Incorrect option" ;;
    esac
  done

  press_any_key_to_menu
}


check_config(){
  echomsg "Checking Sing-box configuration..."

  if $SINGBOX_PROC check -C $CONFIG_DIR; then
    echook "Configuration is valid"
  else
    msg="Configuration check failed"
    echoerr "$msg"
    if [ "$CALLER" = "menu" ]; then
      press_any_key_to_menu
    else
      logger_error "$msg"
      exit 1
    fi
  fi
}


format_config(){
  echomsg "Formatting Sing-box configuration..."

  if $SINGBOX_PROC format -w -C $CONFIG_DIR; then
    echook "Configuration formatted successfully"
  else
    echoerr "Configuration formatting failed"
  fi
}


show_menu(){
  show_header

  import_firewall_vars

  if [ "$AUTO_START" = "1" ]; then
    autostart_status="$(green "yes")"
    autostart_text="Disable"
  else
    autostart_status="$(red "no")"
    autostart_text="Enable"
  fi

  if is_running; then
    running_status="$(green "running")"
    running_text="Stop"
  else
    running_status="$(red "stopped")"
    running_text="Start"
  fi

  printf "\n %s %s" "$SKEEN_NAME version:" "$(cyan "v$(get_current_version "$SKEEN_PROC")")"
  printf "\n %s %s" "$SINGBOX_NAME version:" "$(cyan "v$(get_current_version "$SINGBOX_PROC")")"
  printf "\n %s %s" "$SINGBOX_NAME state:" "$running_status"
  printf "\n %s %s" "Start automatically:" "$autostart_status"
  if [ "$running_text" = "Stop" ] && [ "$SKEEN_FIREWALL_MODE" != "none" ]; then
    echo "$SKEEN_IPTABLES_LIST" | grep -q "ipt" && ipv4="$(cyan "4")"
    echo "$SKEEN_IPTABLES_LIST" | grep -q "ip6t" && ipv6="$(cyan "6")"

    [ "$SKEEN_DNS_SUPPORTED" = "1" ] && \
      sb_dns_work_text="$(green "yes")" || \
      sb_dns_work_text="$(red "no")"

    printf "\n %s %s" "${SINGBOX_NAME} DNS working:" "$sb_dns_work_text"
    printf "\n %s %s" "Firewall mode:" "$(cyan "$SKEEN_FIREWALL_MODE")"
    printf "\n %s %s" "Firewall network:" "$(cyan "$SKEEN_FIREWALL_NETWORK")"
    printf "\n %s %s" "Firewall IP ver.:" "$ipv4 $ipv6"
  elif [ "$running_text" = "Stop" ] && [ "$SKEEN_FIREWALL_MODE" = "none" ]; then
    printf "\n %s %s" "Firewall mode:" "$(cyan "none")"
  fi

  printf "\n\n%s\n" "$(cyan "Select option:")"
  printf "  %s $running_text ${SINGBOX_NAME}\n" "$(green "1.")"
  printf "  %s Restart ${SINGBOX_NAME}\n" "$(green "2.")"
  printf "  %s $autostart_text Autostart\n" "$(green "3.")"
  printf "  %s Check Updates\n" "$(green "4.")"
  printf "  %s Test Firewall\n" "$(green "5.")"
  printf "  %s Uninstall ${SKEEN_NAME}\n" "$(green "6.")"
  printf "  %s Exit\n" "$(green "7.")"

  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    printf "\nEnter your selection [1-7]: " > /dev/tty
    read -r option < /dev/tty

    printf "\n"

    if echo "$option" | grep -Eq '^[1-6]$'; then
      echo "$DELIMETER"

      case "$option" in
        1) switch_state ;;
        2) restart ;;
        3) switch_autostart ;;
        4) check_updates ;;
        5) test_firewall ;;
        6) accept_uninstall ;;
      esac
    else
      [ "$option" = 7 ] && exit 0
      echoerr "Incorrect option"
      attempt=$((attempt+1))
    fi
  done

  exiterr "Maximum attempts reached, exiting menu."
 }


show_help(){
cat <<EOF

$SKEEN_NAME CLI Commands (use: help for this list):

Service Control:
  start   - Starts $SINGBOX_NAME. Checks configuration and will not start again if already running
  stop    - Stops $SINGBOX_NAME. If the process is not found, reports that the daemon is already stopped
  restart - Stops and then starts $SINGBOX_NAME again
  reload  - Reload $SINGBOX_NAME (full restart, not a hot reload) without touching firewall rules
  kill    - Forcefully terminates the $SINGBOX_NAME process (kill -9)
  status  - Shows the current status of the $SINGBOX_NAME process

Information & Updates:
  version - Displays the current application version
  update  - Checks for updates of $SINGBOX_NAME core and $SKEEN_NAME script, and allows updating

Checks & Testing:
  test    - Checks whether iptables rules are correctly applied (requires $SINGBOX_NAME running and mode ≠ none)
  deps    - Checks if all dependencies are installed (installs missing ones)
  check   - Checks $SINGBOX_NAME configuration in $CONFIG_DIR for syntax and logical errors
  format  - Formats $SINGBOX_NAME configuration in $CONFIG_DIR without changing its behavior

Backup & Restore:
  backup  - Creates a backup of $WORK_DIR and places it in $ENTWARE_DIR
  restore - Restores a backup of $WORK_DIR by archive name from $ENTWARE_DIR

Reset Configuration:
  reset   - Resets $CONFIG_DIR and skeen.conf to defaults, performing a backup first

EOF
}


if [ -f "$SKEEN_SCRIPT" ]; then
  case "$ACTION" in
    start)   start ;;
    stop)    stop ;;
    restart) restart ;;
    reload)  reload ;;
    status)  if is_running; then green "running"; else red "stopped"; fi ;;
    kill)    kill_proc ;;
    version)
      printf "${SKEEN_NAME}: %s\n" "$(cyan "v$(get_current_version "$SKEEN_PROC")")";
      printf "${SINGBOX_NAME}: %s\n" "$(cyan "v$(get_current_version "$SINGBOX_PROC")")";
    ;;
    update) check_updates ;;
    test) test_firewall ;;
    deps) install_dependencies; press_any_key_to_menu ;;
    backup) backup_config ;;
    restore) restore_config ;;
    reset) reset_config ;;
    check) check_config ;;
    format) format_config ;;
    apply_firewall) apply_firewall ;;
    "") show_menu ;;
    help|*) show_help ;;
  esac
else
  install
fi

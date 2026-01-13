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

DEPENDENCIES="curl tar ndmc start-stop-daemon"
# + jsonfilter

ENTWARE_DIR="/opt"
WORK_DIR="${ENTWARE_DIR}/etc/skeen"
CONFIG_DIR="${WORK_DIR}/config"
TMP_DIR="${ENTWARE_DIR}/tmp"
# NETFILTER_DIR="${ENTWARE_DIR}/etc/ndm/netfilter.d"
# MODULES_OS_DIR="/lib/modules/$(uname -r)"
# MODULES_ENTWARE_DIR="${ENTWARE_DIR}/lib/modules"

SKEEN_NAME="SKeen"
SKEEN_VERSION="2.1.6"
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

create_skeen_config(){
  mkdir -p "$(dirname "$SKEEN_CONFIG")"

  {
    echo "# Sing-box autostart on router reboot"
    echo "# 0 - disabled, 1 - enabled"
    echo "AUTO_START=1"
    echo "# Router policy name for $SKEEN_NAME traffic"
    echo "# POLICY_NAME=\"${SKEEN_NAME}\""
  } > "$SKEEN_CONFIG"

  create_autostart_script > /dev/null 2>&1
}

[ -f "$SKEEN_CONFIG" ] || create_skeen_config
. "$SKEEN_CONFIG"

cyan()  { printf '\033[36m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

echomsg() { [ -n "$2" ] && printf '\n' >&2; cyan "$1" >&2; }
echook() { green "$1" >&2; }
echowarn() { yellow "$1" >&2; }
echoerr() { red "$1" >&2; }
exiterr() { red "$1" >&2; exit 1; }

logger_notice() { logger -p notice -t "$SKEEN_NAME" "$1"; }
logger_error() { logger -p error -t "$SKEEN_NAME" "$1"; }

get_current_version() {
  case "$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')" in
    "$SINGBOX_PROC")
      if [ -f "$SINGBOX_BIN" ]; then
        echo "$("$SINGBOX_BIN" version | awk 'NR==1 {print $3}' | xargs)"
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

  if [ "$(echo "$latest_release" | grep tag_name | wc -l)" -eq 0 ]; then
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
    *24k*f*|*24kf*) PKG_ARCH="${ARCH}_24kc_24kf" ;;
    *24k*|*1004*)   PKG_ARCH="${ARCH}_24kc" ;;
    *4kec*)         PKG_ARCH="${ARCH}_4kec" ;;
    *)              PKG_ARCH="${ARCH}_mips32" ;;
  esac
}

check_dependencies() {
  missing=""

  for cmd in $DEPENDENCIES; do
    command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
  done

  [ -n "$missing" ] && exiterr "Missing dependencies: $missing"
}

download_singbox(){
  download_version="$1"

  if [ -z "$download_version" ]; then
    echomsg "Fetching the latest version number..." 1
    download_version="$(get_latest_version "$SINGBOX_API_URL")" || exit 1
    echook "Latest version is $download_version"
  fi

  PKG_NAME="sing-box_${download_version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
  pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${download_version}/${PKG_NAME}"

  echomsg "Downloading $PKG_NAME ..." 1

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"

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

  echomsg "Extracting $PKG_NAME" 1
  mkdir "$tmp_unpack_dir"
  cd "$tmp_unpack_dir"
  tar -xf "../${PKG_NAME}"
  tar -xzf data.tar.gz
  echook "Extraction completed."

  echomsg "Installing $SINGBOX_NAME binary to $SINGBOX_BIN" 1
  [ -f "$SINGBOX_BIN" ] && rm -f "$SINGBOX_BIN"
  mv ./usr/bin/sing-box "$SINGBOX_BIN"
  chmod 755 "$SINGBOX_BIN"
  chmod +x "$SINGBOX_BIN"
  echook "$SINGBOX_NAME binary installed successfully."

  echomsg "Cleaning up temporary files..." 1
  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${PKG_NAME}"
  echook "Cleanup completed."
}

create_singbox_config(){
  if [ -d "$CONFIG_DIR" ] && ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
    echomsg "Configuration files already exist in $CONFIG_DIR, skipping creation." 1
    return
  fi

  echomsg "Creating default configuration files..." 1

  mkdir -p "$CONFIG_DIR"
  cat <<EOF > "$CONFIG_DIR/log.json"
{
  "log": {
    "disabled": false,
    "level": "error",
    "timestamp": true
  }
}
EOF

  cat <<EOF > "$CONFIG_DIR/dns.json"
{
  "dns": {
    "servers": [
      {
        "tag": "dns-local",
        "type": "local"
      }
    ],
    "rules": [
    ],
    "final": "dns-local",
    "strategy": "prefer_ipv4"
  }
}
EOF

  cat <<EOF > "$CONFIG_DIR/inbounds.json"
{
  "inbounds": [
    {
      "type": "mixed",
      "listen": "::",
      "listen_port": 2080
    },
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
    "auto_detect_interface": true,
    "default_domain_resolver": "dns-local",
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
      }
    ]
  }
}
EOF

  cat <<EOF > "$CONFIG_DIR/inbounds.json"
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
      "path": "cache.db"
    }
  }
}
EOF

  echook "Configuration file created successfully."
}

create_autostart_script(){
  echomsg "Create $SKEEN_NAME autostart script at $SKEEN_AUTOSTART_SCRIPT" 1

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

create_proxy_interface(){
  echomsg "Creating proxy interface Proxy0 in ndmc" 1

  ndmc -c interface Proxy0 && 
  ndmc -c interface Proxy0 proxy protocol socks5 && 
  ndmc -c interface Proxy0 proxy socks5-udp && 
  ndmc -c interface Proxy0 proxy upstream 127.0.0.1 2080 && 
  ndmc -c interface Proxy0 description Sing-box && 
  ndmc -c interface Proxy0 ip global auto && 
  ndmc -c interface Proxy0 up && 
  ndmc -c system configuration save

  echook "Proxy interface Proxy0 created successfully."
}

create_current_script(){
  [ -f "$SKEEN_SCRIPT" ] && rm -f "$SKEEN_SCRIPT"

  echomsg "Downloading current script at $SKEEN_SCRIPT" 1

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

  echomsg "------------------------------------------------"
  printf "Press any key to open menu..."
  read -r -n 1 </dev/tty

  if [ "$1" = "reload" ];then
    exec sh "$0"
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
  echomsg "------------------------------------------------"
  printf "Press any key to start installation..."
  read -r -n 1 </dev/tty

  get_os_release
  get_architecture
  check_dependencies
  download_singbox
  install_singbox
  create_singbox_config
  create_autostart_script
  create_proxy_interface
  create_current_script

  printf "\n"
  echook "Installation completed, $SINGBOX_NAME version:"
  "$SINGBOX_BIN" version
  echomsg "Configure $SINGBOX_NAME by editing: $CONFIG_DIR" 1

  press_any_key_to_menu
}

uninstall(){
  echomsg "Uninstalling ${SKEEN_NAME}..." 1

  is_running && stop

  echomsg "Removing $SINGBOX_NAME binary..."
  rm -f "$SINGBOX_BIN"

  echomsg "Removing init script..."
  rm -f "$INIT_SCRIPT"

  echomsg "Removing $SKEEN_NAME script..."
  rm -f "$SKEEN_SCRIPT"

  echomsg "Removing proxy interface Proxy0 from ndmc..."
  ndmc -c interface Proxy0 down  &&
  ndmc -c no interface Proxy0 &&
  ndmc -c system configuration save
  echomsg "Configuration directory $WORK_DIR is retained."

  echomsg "If you want to remove it manually, run: rm -rf '$WORK_DIR'"
  echook "${SKEEN_NAME} has been uninstalled successfully."
  exit 0
}

accept_uninstall(){
  max_attempts=3
  attempt=0

  while [ $attempt -lt $max_attempts ]; do
    printf "Uninstall ${SKEEN_NAME}? [y/n]: " > /dev/tty
    read option < /dev/tty

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

  if grep -q "^[[:space:]]*$KEY[[:space:]]*=" "$SKEEN_CONFIG"; then
    sed -i "s|^[[:space:]]*$KEY[[:space:]]*=.*|$KEY=$VALUE|" "$SKEEN_CONFIG"
  else
    echo "$KEY=$VALUE" >> "$SKEEN_CONFIG"
  fi

  . "$SKEEN_CONFIG"
}

start() {
  [ "$CALLER" = "init" ] && [ "$AUTO_START" = "0" ] && return 0

  if is_running; then
    echook "$SINGBOX_NAME already started"
    return 0
  fi

  echomsg "Starting ${SINGBOX_NAME}..."

  $SINGBOX_PROC check -C $CONFIG_DIR
  [ $? -ne 0 ] && press_any_key_to_menu

  start-stop-daemon -S -b -x $SINGBOX_PROC -- $SINGBOX_ARGS
  status_start=$?

  sleep 1

  if [ $status_start -eq 0 ]; then
    echook "$SINGBOX_NAME started."
    logger_notice "Started"
    return 0
  fi

  echoerr "Failed to start $SINGBOX_NAME"
  logger_error "Failed to start"
  return 1
}

stop(){
  echomsg "Stopping ${SINGBOX_NAME}..."

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

  echomsg "Downloading $pkg_name ..." 1

  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"

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

  echomsg "Extracting $pkg_name" 1
  mkdir "$tmp_unpack_dir"
  cd "$tmp_unpack_dir"
  tar -xf "../${pkg_name}" --strip-components=1
  echook "Extraction completed."

  echomsg "Installing $SKEEN_NAME to $SKEEN_SCRIPT" 1
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

  echomsg "Cleaning up temporary files..." 1
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
        read option < /dev/tty

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

  echomsg "Checking $SKEEN_NAME for updates..." 1

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
        read option < /dev/tty

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

  is_running || start

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
    running_status="$(green "running")"
    running_text="Stop"
  else
    running_status="$(red "stopped")"
    running_text="Start"
  fi

  printf "\n%s %s" "$SKEEN_NAME version:" "$(cyan "v$(get_current_version "skeen")")"
  printf "\n%s %s" "$SINGBOX_NAME version:" "$(cyan "v$(get_current_version "$SINGBOX_PROC")")"
  printf "\n%s %s\n" "$SINGBOX_NAME state:" "$running_status"
  printf "%s %s\n" "Start automatically:" "$autostart_status"

  printf "\n%s\n" "$(cyan "Select option:")"
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
    read option < /dev/tty

    if echo "$option" | grep -Eq '^[1-5]$'; then
      echomsg "------------------------------------------------" 1
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
    status)  is_running && echook "running" || echoerr "stopped" ;;
    kill)    kill_proc ;;
    version) echomsg "$SKEEN_NAME v$(get_current_version "skeen")" ;;
    "") show_menu ;;
    *) echomsg "Usage: skeen (start|stop|restart|status|kill|version)" ;;
  esac
else
  install
fi
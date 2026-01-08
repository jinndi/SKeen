#!/bin/sh
#
# https://github.com/jinndi/sing-box-keenetic
#
# Copyright (c) 2026 Jinndi <alncores@gmail.ru>
#
# Released under the MIT License, see the accompanying file LICENSE
# or https://opensource.org/licenses/MIT

trap '' INT QUIT HUP

PKG_OS=""
PKG_ARCH=""
PKG_SUFFIX=""
PKG_NAME=""

ENTWARE_DIR="/opt"
REPO_BASE_URL="https://raw.githubusercontent.com/jinndi/sing-box-keenetic/main"

TMP_DIR="${ENTWARE_DIR}/tmp"
SB_BIN="${ENTWARE_DIR}/bin/sing-box"
PATH_SCRIPT="${ENTWARE_DIR}/bin/sb"
PATH_SCRIPT_URL="${REPO_BASE_URL}/install.sh"

CONFIG_DIR="${ENTWARE_DIR}/etc/sing-box/config"
CONFIG_FILE="${CONFIG_DIR}/config.json"
CONFIG_FILE_URL="${REPO_BASE_URL}/config.json"

INIT_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99sing-box"
INIT_SCRIPT_URL="${REPO_BASE_URL}/S99sing-box"
INIT_SCRIPT_DISABLE="${ENTWARE_DIR}/etc/sing-box/S99sing-box"

cyan()  { printf '\033[36m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

echomsg() {
  [ -n "$2" ] && printf '\n' >&2
  cyan "$1" >&2
}

echook() {
  green "$1" >&2
}

echoerr() {
  red "$1" >&2
}

exiterr() {
  red "$1" >&2
  exit 1
}

get_current_version() {
  if [ -f "$SB_BIN" ]; then
    echo "$("$SB_BIN" version | awk 'NR==1 {print $3}' | xargs)"
  fi
}

get_latest_version() {
  latest_release=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest)
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    exiterr "Failed to fetch the latest version information."
  fi
  if [ "$(echo "$latest_release" | grep tag_name | wc -l)" -eq 0 ]; then
    exiterr "Failed to parse the latest version information:\n$(echo "$latest_release" | grep message)"
  fi
  echo $(echo "$latest_release" | grep tag_name | head -n 1 | awk -F: '{print $2}' | sed 's/[", v]//g')
}

show_header() {
  printf '\n\033[1;35m'
  cat <<EOF
#############################################
 SING-BOX KEENETIC $(get_current_version)
 https://github.com/jinndi/sing-box-keenetic
#############################################
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
  uname_m=$(uname -m | tr '[:upper:]' '[:lower:]')
  cpupart="$(grep -i 'cpu part' /proc/cpuinfo | sed -e 's/.*: //' | tr '[:upper:]' '[:lower:]' | head -n1)"
  cpumodel="$(grep -i 'cpu model' /proc/cpuinfo | sed -e 's/.*: //i' | tr '[:upper:]' '[:lower:]')"

  case "$uname_m" in
    # ARM64
    *aarch64* | *arm64* | *armv8*)
      ARCH="aarch64"
      case "$cpupart" in
        *0xd03*) echo "${ARCH}_cortex-a53"; return ;;
        *0xd08*) echo "${ARCH}_cortex-a72"; return ;;
        *0xd0b*) echo "${ARCH}_cortex-a76"; return ;;
        *)       echo "${ARCH}_generic";    return ;;
      esac
    ;;

    # MIPS endian
    *mipsel*|*mipsle*) ARCH="mipsel" ;;
    *mips*)            ARCH="mips" ;;

    *) exiterr "Unsupported CPU architecture (uname -m=$uname_m)" ;;
  esac

  # MIPS core
  case "$cpuinfo" in
    *74k*|*34k*)    echo "${ARCH}_74kc" ;;
    *24k*f*|*24kf*) echo "${ARCH}_24kc_24kf" ;;
    *24k*|*1004*)   echo "${ARCH}_24kc" ;;
    *4kec*)         echo "${ARCH}_4kec" ;;
    *)              echo "${ARCH}_mips32" ;;
  esac
}

check_ndmc(){
  if ! command -v ndmc >/dev/null 2>&1; then
    exiterr "ndmc not found! Please install ndmc before proceeding."
  fi
}

download_latest_version(){
  download_version="$1"

  if [ -z "$download_version" ]; then
    echomsg "Fetching the latest version number..." 1
    download_version="$(get_latest_version)"
    echook "Latest version is $download_version"
  fi

  PKG_NAME="sing-box_${download_version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
  pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${download_version}/${PKG_NAME}"

  echomsg "Downloading $PKG_NAME ..." 1
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  curl --fail -Lo "$PKG_NAME" "$pkg_url"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    exiterr "Failed to download $PKG_NAME"
  fi
  echook "Downloaded $PKG_NAME successfully."
}

install_sb_bin(){
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

  echomsg "Installing sing-box binary to $SB_BIN" 1
  [ -f "$SB_BIN" ] && rm -f "$SB_BIN"
  mv ./usr/bin/sing-box "$SB_BIN"
  chmod 755 "$SB_BIN"
  chmod +x "$SB_BIN"
  echook "sing-box binary installed successfully."

  echomsg "Cleaning up temporary files..." 1
  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${PKG_NAME}"
  echook "Cleanup completed."
}

create_sb_config(){
  if [ -d "$CONFIG_DIR" ] && ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
    return
  else
    rm -rf "$CONFIG_DIR"
  fi
  
  echomsg "Creating configuration directory at $CONFIG_DIR" 1
  mkdir -p "$CONFIG_DIR"

  echo "Downloading default configuration file..."
  curl --fail -Lo "$CONFIG_FILE" "$CONFIG_FILE_URL"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    exit $curl_exit_status
  fi
  echook "Configuration file created successfully."
}

create_init_script(){
  [ -f "$INIT_SCRIPT" ] && rm -f "$INIT_SCRIPT"

  echomsg "Downloading startup script at $INIT_SCRIPT" 1
  curl --fail -Lo "$INIT_SCRIPT" "$INIT_SCRIPT_URL"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    exiterr "Failed to download the startup script"
  fi
  chmod 755 "$INIT_SCRIPT"
  chmod +x "$INIT_SCRIPT"
  echook "Startup script created successfully."
}

create_proxy_interface(){
  echomsg "Creating proxy interface Proxy0 in ndmc" 1
  ndmc -c interface Proxy0 && 
  ndmc -c interface Proxy0 proxy protocol socks5 && 
  ndmc -c interface Proxy0 proxy socks5-udp && 
  ndmc -c interface Proxy0 proxy upstream 127.0.0.1 2080  && 
  ndmc -c interface Proxy0 description Sing-box && 
  ndmc -c interface Proxy0 ip global auto && 
  ndmc -c interface Proxy0 up && 
  ndmc -c system configuration save
  echook "Proxy interface Proxy0 created successfully."
}

create_current_script(){
  [ -f "$PATH_SCRIPT" ] && rm -f "$PATH_SCRIPT"

  echomsg "Downloading current script at $PATH_SCRIPT" 1
  curl --fail -Lo "$PATH_SCRIPT" "$PATH_SCRIPT_URL"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    exiterr "Failed to download the current script"
  fi
  chmod 755 "$PATH_SCRIPT"
  chmod +x "$PATH_SCRIPT"
  echook "Current script created successfully."
}

press_any_side_to_open_menu(){
  echomsg "------------------------------------------------"
  printf "Press any key to open menu..." > /dev/tty
  dd bs=1 count=1 < /dev/tty >/dev/null 2>&1
  show_menu
}

is_singbox_running(){
  pidof sing-box >/dev/null 2>&1
}

install(){
  if is_singbox_running; then
    exiterr "Sing-box is already running. Please stop and delete it before installing."
  fi
  printf "\n"
  echomsg "------------------------------------------------"
  printf "Press any key to start installation..." > /dev/tty
  dd bs=1 count=1 < /dev/tty >/dev/null 2>&1
  echo > /dev/tty
  get_os_release
  get_architecture
  check_ndmc
  download_latest_version
  install_sb_bin
  create_sb_config
  create_init_script
  create_proxy_interface
  create_current_script
  printf "\n"
  echook "Installation completed, sing-box version:"
  "$SB_BIN" version
  echomsg "You can now configure sing-box by editing $CONFIG_DIR" 1
  press_any_side_to_open_menu
}

uninstall(){
  if is_singbox_running; then
    stop_singbox
  fi
  echomsg "Removing sing-box binary..."
  rm -f "$SB_BIN"
  echomsg "Removing init script..."
  rm -f "$INIT_SCRIPT"
  echomsg "Removing current script..."
  rm -f "$PATH_SCRIPT"
  echomsg "Removing proxy interface Proxy0 from ndmc..."
  ndmc -c interface Proxy0 down  &&
  ndmc -c no interface Proxy0 &&
  ndmc -c system configuration save
  echomsg "Removing sing-box cache and temporary files..."
  for item in "$SINGBOX_DIR"/*; do
    if [ "$item" != "$CONFIG_DIR" ]; then
      rm -rf "$item"
    fi
  done
  echomsg "Configuration directory $CONFIG_DIR is retained."
  echomsg "If you want to remove it manually, run: rm -rf '$CONFIG_DIR'"
}

accept_uninstall(){
  printf "\n"
  while :; do
    printf "Uninstall Sing-box? [y/n]: " > /dev/tty
    read option < /dev/tty
    [ -z "$option" ] && option="n"
    case "$option" in
      y|Y|n|N)
        echomsg "Uninstalling Sing-box..." 1
        uninstall
        echook "Sing-box has been uninstalled successfully."
        exit 0
      ;;
      n|N)
        break
      ;;
      *)
        echoerr "Incorrect option"
      ;;
    esac
  done
  show_menu
}

enable_init_script(){
  if [ -f "$INIT_SCRIPT_DISABLE" ]; then
    mv "$INIT_SCRIPT_DISABLE" "$INIT_SCRIPT" >/dev/null 2>&1
  fi
}

disable_init_script(){
  if [ -f "$INIT_SCRIPT" ]; then
    mv "$INIT_SCRIPT" "$INIT_SCRIPT_DISABLE" >/dev/null 2>&1
  fi
}

start_singbox() {
  echomsg "Starting Sing-box..."
  enable_init_script
  "$INIT_SCRIPT" start >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echook "Sing-box started."
  else
    disable_init_script
    echoerr "Failed to start Sing-box."
  fi
}

stop_singbox() {
  echomsg "Stopping Sing-box..."
  enable_init_script
  "$INIT_SCRIPT" stop >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    disable_init_script
    echook "Sing-box stopped."
  else
    echoerr "Failed to stop Sing-box."
  fi
}

restart_singbox() {
  echomsg "Restarting Sing-box..."
  enable_init_script
  "$INIT_SCRIPT" restart >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echook "Sing-box restarted successfully."
  else
    disable_init_script
    echoerr "Failed to restart Sing-box."
  fi
}

show_menu(){
  show_header

  if [ -f "$INIT_SCRIPT" ]; then
    autostart_status="$(green "enable")"
  else
    autostart_status="$(red "disable")"
  fi

  if is_singbox_running; then
    running_status="$(green "active")"
    action="❌ Stop"
    if [ -f "$INIT_SCRIPT_DISABLE" ]; then
      mv "$INIT_SCRIPT_DISABLE" "$INIT_SCRIPT" >/dev/null 2>&1
      autostart_status="$(green "enable")"
    fi
  else
    running_status="$(red "not active")"
    action="🚀 Start"
    if [ -f "$INIT_SCRIPT" ]; then
      mv "$INIT_SCRIPT" "$INIT_SCRIPT_DISABLE" >/dev/null 2>&1
      autostart_status="$(green "disable")"
    fi
  fi

  printf "\n%s %s\n" "$(cyan "Status:")" "$running_status"
  printf "%s %s\n" "$(cyan "Autostart:")" "$autostart_status"

  printf "\n%s\n" "$(cyan "Select option:")"
  printf " %s ${action}\n"    "$(green "1.")"
  printf " %s 🌀 Restart\n"   "$(green "2.")"
  printf " %s 🪣 Uninstall\n" "$(green "3.")"
  printf " %s 🚪 Exit\n"      "$(green "4.")"

  while :; do
    printf "Choice: " > /dev/tty
    read option < /dev/tty

    case "$option" in
      1)
        printf "\n"
        echomsg "------------------------------------------------"
        if is_singbox_running; then
          stop_singbox
        else
          start_singbox
        fi
        press_any_side_to_open_menu
      ;;
      2)
        printf "\n"
        echomsg "------------------------------------------------"
        restart_singbox
        press_any_side_to_open_menu
      ;;
      3) accept_uninstall ;;
      4) 
        trap - INT QUIT HUP
        exit 0 
      ;;
      *)
        echoerr "Incorrect option"
      ;;
    esac
  done
}

run(){
  CURRENT_VERSION="$(get_current_version)"

  if [ -n "$CURRENT_VERSION" ]; then
    LATEST_VERSION="$(get_latest_version)"

    if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
      printf "%s %s\n" "$(cyan "New version of the sing-box core is available:")" "$(green "$LATEST_VERSION")"
      printf "%s %s\n" "$(cyan "Current installed version:")" "$(red "$CURRENT_VERSION")"
      printf "%s %s\n" "$(cyan "More details:")" "$(green "https://github.com/SagerNet/sing-box/releases")"

      while :; do
        printf "Perform the update? [y/n] (default: n): " > /dev/tty
        read option < /dev/tty
        [ -z "$option" ] && option="n"
        case "$option" in
          y|Y)
            if is_singbox_running; then
              stop_singbox
            fi
            get_os_release
            get_architecture
            download_latest_version "$LATEST_VERSION"
            install_sb_bin
            start_singbox
            echook "The sing-box core has been successfully updated"
            press_any_side_to_open_menu
          ;;
          n|N)
            break
          ;;
          *)
            echoerr "Incorrect option"
          ;;
        esac
      done
    fi
  fi

  if [ -f "$PATH_SCRIPT" ]; then
    show_menu
  else
    install
  fi
}

run
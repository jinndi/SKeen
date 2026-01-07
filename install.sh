#!/bin/sh
#
# https://github.com/jinndi/sing-box-keenetic
#
# Copyright (c) 2026 Jinndi <alncores@gmail.ru>
#
# Released under the MIT License, see the accompanying file LICENSE
# or https://opensource.org/licenses/MIT

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

get_architecture(){
  case "$(uname -m)" in
    armv8* | armv8 | arm64 | aarch64) 
      ARCH="aarch64"
      CPU_PART="$(awk -F': ' '/CPU part/ {print $2; exit}' /proc/cpuinfo)"
      case "$CPU_PART" in
        0xd03) PKG_ARCH="${ARCH}_cortex-a53" ;;
        0xd08) PKG_ARCH="${ARCH}_cortex-a72" ;;
        0xd0b) PKG_ARCH="${ARCH}_cortex-a76" ;;
        *) PKG_ARCH="${ARCH}_generic" ;;
      esac
    ;;
    armv7* | armv7 | armv6* | armv6) 
      ARCH="arm"
      MODEL="$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)"
      case "$MODEL" in
        *A15*) PKG_ARCH="${ARCH}_cortex-a15_neon-vfpv4" ;;
        *A9*)  PKG_ARCH="${ARCH}_cortex-a9" ;;
        *A8*)  PKG_ARCH="${ARCH}_cortex-a8_vfpv3" ;;
        *A7*)  PKG_ARCH="${ARCH}_cortex-a7" ;;
        *A5*)  PKG_ARCH="${ARCH}_cortex-a5_vfpv4" ;;
        *)     PKG_ARCH="${ARCH}_cortex-a7" ;;
      esac
    ;;
    mipsel*) 
      ARCH="mipsel"
      PKG_ARCH="${ARCH}_24kc"
    ;;
    mips*) 
      ARCH="mips" 
      PKG_ARCH="${ARCH}_24kc"
    ;;
    *) exiterr "Unsupported CPU architecture!" ;;
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
  echomsg "You can now configure sing-box by editing $CONFIG_FILE" 1
  press_any_side_to_open_menu
}

uninstall(){
  if is_singbox_running; then
    "$INIT_SCRIPT" stop
  fi
  echomsg "Removing sing-box binary..."
  rm -f "$SB_BIN"
  echomsg "Removing init script..."
  rm -f "$INIT_SCRIPT"
  echomsg "Removing current script..."
  rm -f "$PATH_SCRIPT"
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

show_menu(){
  show_header

  if is_singbox_running; then
    printf "\n%s %s\n" "$(cyan "Service status:")" "$(green "active")"
    printf "\n%s\n" "$(cyan "Select option:")"
    printf " %s ❌ Stop\n" "$(green "1.")"
  else
    printf "\n%s %s\n" "$(cyan "Service status:")" "$(red "not active")"
    printf "\n%s\n" "$(cyan "Select option:")"
    printf " %s 🚀 Start\n" "$(green "1.")"
  fi
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
          "$INIT_SCRIPT" stop
        else
          "$INIT_SCRIPT" start >/dev/null 2>&1 </dev/null &
        fi
        press_any_side_to_open_menu
      ;;
      2)
        printf "\n"
        echomsg "------------------------------------------------"
        "$INIT_SCRIPT" restart >/dev/null 2>&1 </dev/null &
        press_any_side_to_open_menu
      ;;
      3) accept_uninstall;;
      4) exit 0 ;;
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
              "$INIT_SCRIPT" stop
            fi
            get_os_release
            get_architecture
            download_latest_version "$LATEST_VERSION"
            install_sb_bin
            "$INIT_SCRIPT" start >/dev/null 2>&1 </dev/null & 
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
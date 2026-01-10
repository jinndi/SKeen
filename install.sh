#!/bin/sh
#
# https://github.com/jinndi/SKeen
#
# Copyright (c) 2026 Jinndi <alncores@gmail.ru>
#
# Released under the MIT License, see the accompanying file LICENSE
# or https://opensource.org/licenses/MIT
PATH="/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ACTION=$1

APP_NAME="SKeen"
APP_VERSION="2.1.4"

ENTWARE_DIR="/opt"
WORK_DIR="${ENTWARE_DIR}/etc/skeen"

REPO_BASE_URL="https://raw.githubusercontent.com/jinndi/SKeen/main"

CONFIG_NAME_DIR="config"
CONFIG_NAME_FILE="example_config.json"
CONFIG_DIR="${WORK_DIR}/${CONFIG_NAME_DIR}"
CONFIG_FILE="${CONFIG_DIR}/${CONFIG_NAME_FILE}"
CONFIG_FILE_URL="${REPO_BASE_URL}/${CONFIG_NAME_FILE}"

PROC="skeen-box"
PROC_ARGS="run -D $WORK_DIR -C $CONFIG_NAME_DIR"

SETTINGS_FILE="${WORK_DIR}/settings.conf"

TMP_DIR="${ENTWARE_DIR}/tmp"

SB_BIN="${ENTWARE_DIR}/bin/${PROC}"

PATH_SCRIPT="${ENTWARE_DIR}/bin/skeen"
PATH_SCRIPT_URL="${REPO_BASE_URL}/install.sh"

INIT_SCRIPT="${ENTWARE_DIR}/etc/init.d/S99SKeen"

DEPENDENCIES="curl tar ndmc start-stop-daemon"

create_settings(){
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  {
    echo "# Sing-box autostart on router reboot"
    echo "# 0 - disabled, 1 - enabled"
    echo "AUTO_START=1"
  } > "$SETTINGS_FILE"
  create_init_script > /dev/null 2>&1
}

[ -f "$SETTINGS_FILE" ] || create_settings
. "$SETTINGS_FILE"

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

get_sb_current_version() {
  if [ -f "$SB_BIN" ]; then
    echo "$("$SB_BIN" version | awk 'NR==1 {print $3}' | xargs)"
  fi
}

get_sb_latest_version() {
  latest_release=$(curl --connect-timeout 10 --max-time 90 -s https://api.github.com/repos/SagerNet/sing-box/releases/latest)
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    echoerr "Failed to fetch the latest version information."
    return 1
  fi
  if [ "$(echo "$latest_release" | grep tag_name | wc -l)" -eq 0 ]; then
    echoerr "Failed to parse the latest version information:\n$(echo "$latest_release" | grep message)"
    return 1
  fi
  echo $(echo "$latest_release" | grep tag_name | head -n 1 | awk -F: '{print $2}' | sed 's/[", v]//g')
}

get_sk_latest_version() {
  latest_release=$(curl --connect-timeout 10 --max-time 90 -s https://api.github.com/repos/jinndi/SKeen/releases/latest)
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    echoerr "Failed to fetch the latest version information."
    return 1
  fi
  if [ "$(echo "$latest_release" | grep tag_name | wc -l)" -eq 0 ]; then
    echoerr "Failed to parse the latest version information:\n$(echo "$latest_release" | grep message)"
    return 1
  fi
  echo $(echo "$latest_release" | grep tag_name | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
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

download_sb_latest_version(){
  download_version="$1"

  if [ -z "$download_version" ]; then
    echomsg "Fetching the latest version number..." 1
    download_version="$(get_sb_latest_version)" || exit 1
    echook "Latest version is $download_version"
  fi

  PKG_NAME="sing-box_${download_version}_${PKG_OS}_${PKG_ARCH}${PKG_SUFFIX}"
  pkg_url="https://github.com/SagerNet/sing-box/releases/download/v${download_version}/${PKG_NAME}"

  echomsg "Downloading $PKG_NAME ..." 1
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  curl --fail --connect-timeout 10 --max-time 90 -Lo "$PKG_NAME" "$pkg_url"
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
  curl --fail --connect-timeout 10 --max-time 90 -Lo "$CONFIG_FILE" "$CONFIG_FILE_URL"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    echoerr "Failed to download configuration file"
    return 1
  fi
  echook "Configuration file created successfully."
}

create_init_script(){
  echomsg "Create startup script at $INIT_SCRIPT" 1
  [ -f "$INIT_SCRIPT" ] && rm -f "$INIT_SCRIPT"
  {
    echo "#!/bin/sh"
    echo "PATH=$PATH"
    echo "skeen start"
  } > "$INIT_SCRIPT"
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
  curl --fail --connect-timeout 10 --max-time 90 -Lo "$PATH_SCRIPT" "$PATH_SCRIPT_URL"
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
  dd bs=1 count=1 if=/dev/tty of=/dev/null 2>&1
  if [ "$1" = "reload" ];then
    exec sh "$0"
  else
    show_menu
  fi
}

is_running(){
  if [ -n "$(pidof "$PROC")" ]; then
    return 0
  else
    return 1
  fi
}

install(){
  echomsg "------------------------------------------------"
  printf "Press any key to start installation..." > /dev/tty
  dd bs=1 count=1 if=/dev/tty of=/dev/null 2>&1
  echo > /dev/tty
  get_os_release
  get_architecture
  check_dependencies
  download_sb_latest_version
  install_sb_bin
  create_sb_config
  create_init_script
  create_proxy_interface
  create_current_script
  printf "\n"
  echook "Installation completed, sing-box version:"
  "$SB_BIN" version
  echomsg "Configure sing-box by editing $CONFIG_DIR" 1
  press_any_side_to_open_menu
}

uninstall(){
  is_running && stop
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
  echomsg "Configuration directory $WORK_DIR is retained."
  echomsg "If you want to remove it manually, run: rm -rf '$WORK_DIR'"
}

accept_uninstall(){
  max_attempts=3
  attempt=0
  while [ $attempt -lt $max_attempts ]; do
    printf "Uninstall SKeen? [y/n]: " > /dev/tty
    read option < /dev/tty
    [ -z "$option" ] && option="n"
    case "$option" in
      y|Y)
        echomsg "Uninstalling SKeen..." 1
        uninstall
        echook "SKeen has been uninstalled successfully."
        exit 0
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

update_settings_var(){
  KEY=$1
  VALUE=$2
  [ -f "$SETTINGS_FILE" ] || create_settings
  if grep -q "^[[:space:]]*$KEY[[:space:]]*=" "$SETTINGS_FILE"; then
    sed -i "s|^[[:space:]]*$KEY[[:space:]]*=.*|$KEY=$VALUE|" "$SETTINGS_FILE"
  else
    echo "$KEY=$VALUE" >> "$SETTINGS_FILE"
  fi
  . "$SETTINGS_FILE"
}

start() {
  [ -n "$ACTION" ] && [ "$AUTO_START" = "0" ] && return 0
  echomsg "Starting Sing-box..."
  is_running && echook "Sing-box started." && return 0
  $PROC check -C $CONFIG_DIR
  status_check=$?
  if [ $status_check -ne 0 ]; then
    [ -z "$ACTION" ] && press_any_side_to_open_menu
  fi
  start-stop-daemon -S -b -x $PROC -- $PROC_ARGS
  status_start=$?
  if [ $status_start -eq 0 ]; then
    echook "Sing-box started."
    logger -p notice -t "$APP_NAME" "Started"
    return 0
  fi

  echoerr "Failed to start Sing-box."
  logger -p error -t "$APP_NAME" "Failed to start"
  return 1
}

stop(){
  echomsg "Stopping Sing-box..."
  is_running || ( echook "Sing-box stopped." && return 0 )
  start-stop-daemon -K -x $PROC >/dev/null
  status_stop=$?
  if [ $status_stop -eq 0 ]; then
    echook "Sing-box stopped."
    logger -p notice -t "$APP_NAME" "Stopped"
    return 0
  else
    echoerr "Failed to stop Sing-box."
    logger -p error -t "$APP_NAME" "Failed to stop"
    return 1
  fi
}

kill_proc(){
  is_running || ( echook "Sing-box not running." && return 0 )
  echo "Killing ${PROC}..."
  killall -9 "$PROC" 2>/dev/null
}

switch_state(){
  if is_running; then
    stop
  else
    start
  fi
  press_any_side_to_open_menu
}

restart() {
  stop
  start
  press_any_side_to_open_menu
}

switch_autostart(){
  if [ "$AUTO_START" = "1" ]; then
    update_settings_var "AUTO_START" "0"
    echook "Autostart disabled"
  else
    update_settings_var "AUTO_START" "1"
    echook "Autostart enabled"
  fi
  press_any_side_to_open_menu
}

update_core(){
  is_running && stop
  get_os_release
  get_architecture
  download_sb_latest_version "$latest_sb_ver" || return 1
  install_sb_bin
  echook "The sing-box core has been successfully updated"
}

update_skeen(){
  pkg_name="SKeen-v${latest_sk_ver}.tar.gz"
  pkg_url="https://github.com/jinndi/SKeen/archive/${pkg_name}"
  
  echomsg "Downloading SKeen-v${latest_sk_ver}.tar.gz ..." 1
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  curl --fail --connect-timeout 10 --max-time 60 -Lo "$pkg_name" "$pkg_url"
  curl_exit_status=$?
  if [ $curl_exit_status -ne 0 ]; then
    echoerr "Failed to download $pkg_name"
    return 1
  fi
  echook "Downloaded $pkg_name successfully."

  tmp_unpack_dir="${TMP_DIR}/SKeen-unpack"

  if [ -d "$tmp_unpack_dir" ]; then
    rm -rf "$tmp_unpack_dir"
  fi

  echomsg "Extracting $pkg_name" 1
  mkdir "$tmp_unpack_dir"
  cd "$tmp_unpack_dir"
  tar -xf "../${pkg_name}" --strip-components=1
  echook "Extraction completed."

  echomsg "Installing SKeen to $PATH_SCRIPT" 1
  mkdir -p "$(dirname "$PATH_SCRIPT")"
  [ -f "$PATH_SCRIPT" ] && rm -f "$PATH_SCRIPT"
  if [ -f "install.sh" ];then
    mv ./install.sh "$PATH_SCRIPT"
    chmod 755 "$PATH_SCRIPT"
    chmod +x "$PATH_SCRIPT"
    echook "SKeen installed successfully."
  else
    echoerr "install.sh not found in archive!"
  fi
  echomsg "Cleaning up temporary files..." 1
  rm -rf "$tmp_unpack_dir"
  rm -f "${TMP_DIR}/${pkg_name}"
  echook "Cleanup completed."
  echook "The SKeen has been successfully updated"
}

check_update(){
  echomsg "Checking sing-box for updates..."
  current_sb_ver="$(get_sb_current_version)"
  latest_sb_ver="$(get_sb_latest_version)" || press_any_side_to_open_menu

  if [ -z "$current_sb_ver" ]; then
    if [ -f "$SB_BIN" ]; then
      echoerr "Failed to get sing-box version"
    else
      update_core
      current_sb_ver="$(get_sb_current_version)"
      latest_sb_ver="$current_sb_ver"
    fi
  fi

  if [ -n "$latest_sb_ver" ] && [ -n "$current_sb_ver" ]; then
    if [ "$latest_sb_ver" != "$current_sb_ver" ]; then
      printf "%s %s\n" "$(cyan "New version of the sing-box core is available:")" "$(green "$latest_sb_ver")"
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
      echook "The latest sing-box version $latest_sb_ver is already installed"
    fi
  fi

  echomsg "Checking SKeen for updates..." 1
  current_sk_ver="$APP_VERSION"
  latest_sk_ver="$(get_sk_latest_version)" || press_any_side_to_open_menu

  if [ -z "$current_sk_ver" ]; then
    echoerr "Failed to get SKeen version"
  fi

  if [ -n "$latest_sk_ver" ] && [ -n "$current_sk_ver" ]; then
    if [ "$latest_sk_ver" != "$current_sk_ver" ]; then
      printf "%s %s\n" "$(cyan "New version SKeen script is available:")" "$(green "$latest_sk_ver")"
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
      echook "The latest Skeen version $latest_sk_ver is already installed"
    fi
  fi

  is_running || start
  press_any_side_to_open_menu "reload"
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

  printf "\n%s %s" "SKeen version:" "$(cyan "v${APP_VERSION}")"
  printf "\n%s %s" "sing-box version:" "$(cyan "v$(get_sb_current_version)")"
  printf "\n%s %s\n" "sing-box state:" "$running_status"
  printf "%s %s\n" "Start automatically:" "$autostart_status"

  printf "\n%s\n" "$(cyan "Select option:")"
  printf "  %s $running_text sing-box\n" "$(green "1.")"
  printf "  %s Restart sing-box\n" "$(green "2.")"
  printf "  %s $autostart_text Autostart\n" "$(green "3.")"
  printf "  %s Check Updates\n" "$(green "4.")"
  printf "  %s Uninstall SKeen\n" "$(green "5.")"
  printf "  %s Exit\n" "$(green "6.")"

  max_attempts=5
   attempt=0
   while [ $attempt -lt $max_attempts ]; do
    printf "\nEnter your selection [1-6]: " > /dev/tty
    read option < /dev/tty
    if [ "$option" -ge 1 ] && [ "$option" -le 5 ]; then
      echomsg "------------------------------------------------" 1
    fi
    case "$option" in
      1) switch_state ;;
      2) restart ;;
      3) switch_autostart ;;
      4) check_update ;;
      5) accept_uninstall ;;
      6) exit 0 ;;
      *) echoerr "Incorrect option" ;;
    esac
     attempt=$((attempt+1))
   done
   exiterr "Maximum attempts reached, exiting menu."
 }

case "$ACTION" in
  start)   start ;;
  stop)    stop ;;
  restart) restart ;;
  status)  is_running && echook "running" || echoerr "stopped" ;;
  kill)    kill_proc ;;
  version) echo "$APP_NAME v${APP_VERSION}" ;;
  *)
    if [ -n "$ACTION" ]; then
      echomsg "Usage: skeen (start|stop|restart|status|kill|version)"
    elif [ -f "$PATH_SCRIPT" ]; then
      show_menu
    else
      install
    fi
  ;;
esac
#!/bin/sh
# Interactive bootstrap that selects the SKeen language before installation.
set -eu
PATH="/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"
INSTALLER_DIR="${TMPDIR:-/tmp}"
INSTALLER_FILE="${INSTALLER_DIR%/}/skeen-installer-$$.sh"
RELEASE_BASE_URL="https://github.com/jinndi/SKeen/releases/latest/download"
TTY=/dev/tty

cleanup() { rm -f "$INSTALLER_FILE"; }
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

exiterr() {
  if [ -t 2 ]; then
    printf '\033[31m%s\033[0m\n' "$*" >&2
  else
    printf '%s\n' "$*" >&2
  fi
  exit 1
}

if [ "${SKIP_COMPATIBILITY_CHECKS:-0}" != "1" ]; then
  if [ "$(id -u)" -ne 0 ]; then
    exiterr 'Run this installer as root.'
  fi

  fail_compatibility() {
    printf '%s\n' 'SKeen installation is not supported on this system.' >&2
    exiterr "$1"
  }

  if [ "$(command -v opkg 2>/dev/null || true)" != "/opt/bin/opkg" ]; then
    fail_compatibility 'Entware opkg was not found at /opt/bin/opkg.'
  fi
  if [ -e /opt/bin/skeen ]; then
    printf '%s\n' 'SKeen is already installed. Remove it first or run the update from SKeen.' >&2
    exit 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    fail_compatibility 'curl is required to download SKeen.'
  fi

  opkg_arch=$(opkg print-architecture 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)
  case "$opkg_arch" in
    *aarch64* | *arm64* | *armv8* | *mipsel* | *mipsle* | *mips_*) : ;;
    *) fail_compatibility 'Supported architectures: aarch64, mipsel, mips.' ;;
  esac

  free_mb=$(df -Pm /opt 2>/dev/null | awk 'NR == 2 {print $4}')
  case "$free_mb" in
    '' | *[!0-9]*) fail_compatibility 'Unable to determine free space on /opt.' ;;
  esac
  if [ "$free_mb" -le 30 ]; then
    fail_compatibility "More than 30 MB of free space is required on /opt (available: ${free_mb} MB)."
  fi
fi

if [ -n "${INSTALL_LANG:-}" ]; then
  case "$INSTALL_LANG" in
    en | ru) language="$INSTALL_LANG" ;;
    *) exiterr 'INSTALL_LANG must be en or ru' ;;
  esac
elif [ -r "$TTY" ] && [ -w "$TTY" ]; then
  printf '%s\n' 'Select language:' >"$TTY"
  printf '%s\n' '  1) English' '  2) Русский' '  0) Cancel' >"$TTY"

  while :; do
    printf '%s' 'Choice [1-2, 0]: ' >"$TTY"
    IFS= read -r language_choice <"$TTY" || exit 1
    case "$language_choice" in
      1) language=en; break ;;
      2) language=ru; break ;;
      0) printf '%s\n' 'Installation cancelled' >"$TTY"; exit 0 ;;
      *) printf '%s\n' 'Enter 1, 2 or 0' >"$TTY" ;;
    esac
  done
else
  case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
    ru | ru_* | ru.*) language=ru ;;
    *) language=en ;;
  esac
fi

case "$language" in
  ru) script_name=skeen_ru ;;
  *) script_name=skeen ;;
esac

case "$language" in
  ru) printf '%s\n' 'Загрузка скрипта SKeen...' ;;
  *) printf '%s\n' 'Downloading the SKeen script...' ;;
esac

if ! mkdir -p "$INSTALLER_DIR" || ! : >"$INSTALLER_FILE"; then
  case "$language" in
    ru) exiterr "Не удалось создать временный файл установщика: $INSTALLER_FILE" ;;
    *) exiterr "Cannot create installer temporary file:  $INSTALLER_FILE" ;;
  esac
fi

if ! curl -fsSL --connect-timeout 10 -o "$INSTALLER_FILE" \
  --resolve release-assets.githubusercontent.com:443:185.199.108.133 \
  "$RELEASE_BASE_URL/$script_name"; then
  case "$language" in
    ru) exiterr 'Не удалось загрузить SKeen скрипт.' ;;
    *) exiterr 'Failed to download the SKeen script.' ;;
  esac
fi

chmod 700 "$INSTALLER_FILE"
clear; sh "$INSTALLER_FILE"

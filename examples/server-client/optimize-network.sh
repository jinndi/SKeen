#!/bin/bash

# ==============================================================================
# Оптимизация сетевого стека Linux (High-Load Network Tuning)
# Конфигурация для серверов/VPS с объемом RAM от 1 ГБ
# ==============================================================================
# Основные изменения:
#  1. Буферы и лимиты:
#     - Увеличены максимальные размеры сетевых буферов (16MB) для TCP-сокетов.
#     - Увеличены очереди очереди соединений (somaxconn, max_backlog = 4096).
#     - Расширен диапазон локальных портов для исходящих соединений (10000-60001).
#     - Лимит открытых файлов системы (file-max) установлен в 1048576.
#
#  2. Защита и тайм-ауты TCP:
#     - Включена защита от SYN-flood атак (tcp_syncookies).
#     - Оптимизирована утилизация TIME_WAIT сокетов (tcp_tw_reuse, tcp_fin_timeout = 30s).
#     - Ускорено обнаружение мертвых соединений (tcp_keepalive_*).
#     - Включен TCP Fast Open (ускоряет повторные handshake) и MTU Probing.
#
#  3. Безопасность и маршрутизация:
#     - Отключены ICMP-ping ответы (icmp_echo_ignore_all).
#     - Отключены timestamps (снижает накладные расходы на пакеты).
#     - Отключен IPv6 на всех интерфейсах (all, default, lo).
#     - Включена переадресация IP-пакетов (ip_forward) для VPN/маршрутизации.
#
# Документации:
# https://www.kernel.org/doc/Documentation/sysctl/net.txt
# https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
# ==============================================================================

# ==============================================================================
# Чтобы применить на сервере, выполните:
# bash <(curl -sSL https://raw.githubusercontent.com/jinndi/SKeen/main/examples/server-client/optimize-network.sh)
# ==============================================================================

readonly PATH_SYSCTL_CONF="/etc/sysctl.d/99-optimize-network.conf"

if [[ $EUID -ne 0 ]]; then
  echo "[!] Скрипт должен быть запущен от имени root!" >&2
  exit 1
fi

if ! command -v sysctl >/dev/null 2>&1; then
  echo "[!] Ошибка: утилита 'sysctl' не найдена в системе!" >&2
  exit 1
fi

if [[ ! -w /proc/sys/net/ipv4/tcp_congestion_control ]]; then
  echo "[!] Сетевой стек ядра недоступен для изменения (OpenVZ/LXC контейнер без прав)!" >&2
  exit 1
fi

mkdir -p "$(dirname "$PATH_SYSCTL_CONF")"

if [[ -f "$PATH_SYSCTL_CONF" ]]; then
  echo "[~] Перезаписываем сетевой sysctl-конфиг: $PATH_SYSCTL_CONF"
else
  echo "[+] Создаем сетевой sysctl-конфиг: $PATH_SYSCTL_CONF"
fi

{
  echo "# Network configuration for server 1+ GB RAM"
  echo "# https://www.kernel.org/doc/Documentation/sysctl/net.txt"
  echo "# https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt"
  echo
  echo "fs.file-max = 1048576"
  echo "net.core.rmem_max = 16777216"
  echo "net.core.wmem_max = 16777216"
  echo "net.core.rmem_default = 262144"
  echo "net.core.wmem_default = 262144"
  echo "net.core.netdev_max_backlog = 4096"
  echo "net.core.somaxconn = 4096"
  echo "net.ipv4.ip_forward = 1"
  echo "net.ipv4.conf.all.src_valid_mark = 1"
  echo "net.ipv4.icmp_echo_ignore_all = 1"
  echo "net.ipv4.tcp_rmem = 4096 87380 16777216"
  echo "net.ipv4.tcp_wmem = 4096 65536 16777216"
  echo "net.ipv4.tcp_mem = 8192 16384 65536"
  echo "net.ipv4.udp_mem = 8192 16384 32768"
  echo "net.ipv4.udp_rmem_min = 16384"
  echo "net.ipv4.udp_wmem_min = 16384"
  echo "net.ipv4.tcp_syncookies = 1"
  echo "net.ipv4.tcp_tw_reuse = 1"
  echo "net.ipv4.tcp_fin_timeout = 30"
  echo "net.ipv4.tcp_keepalive_time = 600"
  echo "net.ipv4.tcp_keepalive_probes = 5"
  echo "net.ipv4.tcp_keepalive_intvl = 10"
  echo "net.ipv4.tcp_timestamps = 0"
  echo "net.ipv4.tcp_sack = 1"
  echo "net.ipv4.tcp_limit_output_bytes = 262144"
  echo "net.ipv4.ip_unprivileged_port_start = 1024"
  echo "net.ipv4.ip_local_port_range = 10000 60001"
  echo "net.ipv4.tcp_max_syn_backlog = 4096"
  echo "net.ipv4.tcp_max_tw_buckets = 4000"
  echo "net.ipv4.tcp_fastopen = 3"
  echo "net.ipv4.tcp_mtu_probing = 1"
  echo
  echo "## Disable IPv6"
  echo "net.ipv6.conf.all.disable_ipv6 = 1"
  echo "net.ipv6.conf.default.disable_ipv6 = 1"
  echo "net.ipv6.conf.lo.disable_ipv6 = 1"
  echo
  echo "## tcp_congestion_control"
  echo "# Algorithm for control of network overload"
  echo "# Full list of algorithms that can be available:"
  echo "# https://en.wikipedia.org/wiki/TCP_congestion-avoidance_algorithm#Algorithms"
  echo "# BBR - from Google (set in priority)"
  echo "# HYBLA - for networks with high delay"
  echo "# Cubic - for low delay networks"
} > "$PATH_SYSCTL_CONF"

modprobe -q tcp_bbr 2>/dev/null
modprobe -q tcp_hybla 2>/dev/null

available_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)
all_cc=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null)

if [[ " $all_cc " == *" bbr "* ]]; then
  {
    echo "net.core.default_qdisc = fq"
    echo "net.ipv4.tcp_congestion_control = bbr"
  } >> "$PATH_SYSCTL_CONF"
elif [[ " $all_cc " == *" hybla "* ]]; then
  echo "net.ipv4.tcp_congestion_control = hybla" >> "$PATH_SYSCTL_CONF"
fi

if sysctl -e -p "$PATH_SYSCTL_CONF" > /dev/null; then
  echo "[+] Изменения успешно применены!"
else
  echo "[!] Ошибка применения $PATH_SYSCTL_CONF" >&2
fi

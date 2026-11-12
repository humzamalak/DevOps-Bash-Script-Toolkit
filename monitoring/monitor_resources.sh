#!/usr/bin/env bash
# monitor_resources.sh - Monitor system resources and alert on thresholds
#
# This script provides lightweight monitoring for system resources:
# - Measures CPU, memory and root disk usage as percentages
# - Prints an alert line for each resource at or above its threshold
# - Works on Linux (/proc) and macOS (top, vm_stat, sysctl)
# - Exit code: 0 if no threshold is reached, 1 if any alert, 2 on an unsupported OS
# - Designed for use in cron jobs, server bootstrapping, or as a health check
#
# Usage: monitor_resources.sh [--cpu <percent>] [--mem <percent>] [--disk <percent>] [--help]
#
# Options:
#   --cpu         CPU usage threshold (default: 80)
#   --mem         Memory usage threshold (default: 80)
#   --disk        Disk usage threshold (default: 80)
#   -h, --help    Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

CPU_THR=80   # Default CPU usage threshold (%)
MEM_THR=80   # Default memory usage threshold (%)
DISK_THR=80  # Default disk usage threshold (%)

# Overridable for tests
OS="${MONITOR_OS:-$(uname -s)}"
PROC_DIR="${PROC_DIR:-/proc}"
CPU_SAMPLE_SECONDS="${CPU_SAMPLE_SECONDS:-1}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cpu)
      CPU_THR="$2"; shift 2;;   # Set CPU threshold
    --mem)
      MEM_THR="$2"; shift 2;;   # Set memory threshold
    --disk)
      DISK_THR="$2"; shift 2;;  # Set disk threshold
    -h|--help)
      show_help; exit 0;;       # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
done

for thr in "$CPU_THR" "$MEM_THR" "$DISK_THR"; do
  if ! [[ "$thr" =~ ^[0-9]+$ ]]; then
    echo "[ERROR] Thresholds must be whole numbers (got: $thr)." >&2; exit 1
  fi
done

# Linux CPU: busy share of all CPU time between two /proc/stat samples
cpu_linux() {
  local a b
  a=$(head -1 "$PROC_DIR/stat")
  sleep "$CPU_SAMPLE_SECONDS"
  b=$(head -1 "$PROC_DIR/stat")
  awk -v a="$a" -v b="$b" 'BEGIN {
    n = split(a, x, " "); split(b, y, " ")
    for (i = 2; i <= n; i++) { total += y[i] - x[i] }
    idle = (y[5] - x[5]) + (y[6] - x[6])   # idle + iowait
    if (total <= 0) { print 0 } else { printf "%d\n", (total - idle) * 100 / total }
  }'
}

# Linux memory: (MemTotal - MemAvailable) / MemTotal
mem_linux() {
  awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2}
       END { if (t > 0) printf "%d\n", (t - a) * 100 / t; else print 0 }' "$PROC_DIR/meminfo"
}

# macOS CPU: 100 - idle from the second top sample (the first is since boot)
cpu_darwin() {
  top -l 2 -n 0 | awk '/CPU usage/ {idle = $7} END {sub("%", "", idle); printf "%d\n", 100 - idle}'
}

# macOS memory: (active + wired + compressed pages) * page size / total memory
mem_darwin() {
  local page_size total
  page_size=$(sysctl -n hw.pagesize)
  total=$(sysctl -n hw.memsize)
  vm_stat | awk -v ps="$page_size" -v t="$total" '
    /^Pages active:/ || /^Pages wired down:/ || /^Pages occupied by compressor:/ {
      gsub("\\.", "", $NF); used += $NF
    }
    END { printf "%d\n", used * ps * 100 / t }'
}

case "$OS" in
  Linux)  CPU_USAGE=$(cpu_linux);  MEM_USAGE=$(mem_linux);;
  Darwin) CPU_USAGE=$(cpu_darwin); MEM_USAGE=$(mem_darwin);;
  *) echo "[ERROR] Unsupported OS: $OS (Linux and macOS only)." >&2; exit 2;;
esac
# Root filesystem usage (POSIX df output)
DISK_USAGE=$(df -P / | awk 'NR == 2 {sub("%", "", $5); print $5}')

echo "[INFO] CPU ${CPU_USAGE}%, memory ${MEM_USAGE}%, disk ${DISK_USAGE}%"

ALERT=0
if (( CPU_USAGE >= CPU_THR )); then
  echo "[ALERT] CPU usage is at $CPU_USAGE% (threshold: $CPU_THR%)"; ALERT=1
fi
if (( MEM_USAGE >= MEM_THR )); then
  echo "[ALERT] Memory usage is at $MEM_USAGE% (threshold: $MEM_THR%)"; ALERT=1
fi
if (( DISK_USAGE >= DISK_THR )); then
  echo "[ALERT] Disk usage is at $DISK_USAGE% (threshold: $DISK_THR%)"; ALERT=1
fi

echo "[INFO] Resource monitoring complete."
exit "$ALERT"

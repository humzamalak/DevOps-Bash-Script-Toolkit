#!/usr/bin/env bash
# monitor_resources.sh - Monitor system resources and alert on thresholds
#
# This script provides lightweight monitoring for system resources:
# - Checks CPU, memory, and disk usage
# - Alerts if any resource exceeds the specified threshold
# - Allows custom thresholds for each resource
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

# Get current CPU usage (macOS syntax; adjust for Linux as needed)
CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
# Get current memory usage (macOS syntax; adjust for Linux as needed)
MEM_USAGE=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
# Get current disk usage for root filesystem
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Alert if CPU usage exceeds threshold
if [[ "$CPU_USAGE" -ge "$CPU_THR" ]]; then
  echo "[ALERT] CPU usage is at $CPU_USAGE% (threshold: $CPU_THR%)"
fi
# Alert if memory usage exceeds threshold
if [[ "$MEM_USAGE" -ge "$MEM_THR" ]]; then
  echo "[ALERT] Memory usage is at $MEM_USAGE% (threshold: $MEM_THR%)"
fi
# Alert if disk usage exceeds threshold
if [[ "$DISK_USAGE" -ge "$DISK_THR" ]]; then
  echo "[ALERT] Disk usage is at $DISK_USAGE% (threshold: $DISK_THR%)"
fi

echo "[INFO] Resource monitoring complete."

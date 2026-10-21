#!/usr/bin/env bash
# log_rotate.sh - Rotate and compress logs by size or age
#
# This script automates log rotation and compression:
# - Rotates logs if they exceed a specified size (in MB) or age (in days)
# - Compresses rotated logs with gzip and timestamps them
# - Prevents disk exhaustion and helps with log management/compliance
# - Designed for use in cron jobs or as part of server maintenance
#
# Usage: log_rotate.sh -f <log_file> [-s <size_mb>] [-a <age_days>] [--help]
#
# Options:
#   -f, --file         Log file to rotate (required)
#   -s, --size         Rotate if larger than size in MB (optional)
#   -a, --age          Rotate if older than age in days (optional)
#   -h, --help         Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

LOG_FILE=""   # Path to the log file to rotate
SIZE_MB=""    # Size threshold in MB (optional)
AGE_DAYS=""   # Age threshold in days (optional)

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      LOG_FILE="$2"; shift 2;;   # Set log file path
    -s|--size)
      SIZE_MB="$2"; shift 2;;    # Set size threshold
    -a|--age)
      AGE_DAYS="$2"; shift 2;;   # Set age threshold
    -h|--help)
      show_help; exit 0;;        # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Ensure log file is provided
if [[ -z "$LOG_FILE" ]]; then
  echo "[ERROR] Log file is required."; show_help; exit 1
fi

should_rotate=false  # Flag to determine if rotation is needed

# Check if log file exceeds size threshold
if [[ -n "$SIZE_MB" ]]; then
  actual_size=$(du -m "$LOG_FILE" | cut -f1)
  if (( actual_size >= SIZE_MB )); then
    should_rotate=true
  fi
fi
# Check if log file exceeds age threshold
if [[ -n "$AGE_DAYS" ]]; then
  file_age=$(( ( $(date +%s) - $(stat -f %m "$LOG_FILE") ) / 86400 ))
  if (( file_age >= AGE_DAYS )); then
    should_rotate=true
  fi
fi

# If rotation is needed, compress and clear the log file
if [[ "$should_rotate" == true ]]; then
  gzip -c "$LOG_FILE" > "$LOG_FILE.$(date +%Y%m%d%H%M%S).gz"
  : > "$LOG_FILE"  # Truncate the log file
  echo "[INFO] Rotated and compressed $LOG_FILE"
else
  echo "[INFO] No rotation needed for $LOG_FILE"
fi

#!/usr/bin/env bash
# check_service_health.sh - Check service/process health and port availability
#
# This script checks if a given service/process is running and optionally if a port is open:
# - Uses pgrep to check for the process by name
# - Uses nc (netcat) to check if a port is open on localhost
# - Designed for use in monitoring, health checks, or incident response
# - Exit code: 0 if all checks pass, 1 if any check fails, 2 if a tool is missing
#
# Usage: check_service_health.sh -s <service> [-p <port>] [--help]
#
# Options:
#   -s, --service      Service/process name (required)
#   -p, --port         Port to check (optional)
#   -h, --help         Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

SERVICE=""  # Name of the service/process to check
PORT=""     # Port to check (optional)

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--service)
      SERVICE="$2"; shift 2;;  # Set service/process name
    -p|--port)
      PORT="$2"; shift 2;;     # Set port to check
    -h|--help)
      show_help; exit 0;;      # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Ensure service name is provided
if [[ -z "$SERVICE" ]]; then
  echo "[ERROR] Service name is required."; show_help; exit 1
fi

# Make sure the tools for the requested checks exist
for tool in pgrep ${PORT:+nc}; do
  if ! command -v "$tool" > /dev/null 2>&1; then
    echo "[ERROR] Required tool not found: $tool" >&2; exit 2
  fi
done

FAILED=0  # Set to 1 when any check fails

# Check if the service/process is running using pgrep
if pgrep -x "$SERVICE" > /dev/null; then
  echo "[OK] Service $SERVICE is running."
else
  echo "[FAIL] Service $SERVICE is not running."
  FAILED=1
fi

# If a port is specified, check if it is open on localhost
if [[ -n "$PORT" ]]; then
  if nc -z 127.0.0.1 "$PORT"; then
    echo "[OK] Port $PORT is open."
  else
    echo "[FAIL] Port $PORT is not open."
    FAILED=1
  fi
fi

exit "$FAILED"  # Non-zero when any check failed

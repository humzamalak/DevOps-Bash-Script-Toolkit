#!/usr/bin/env bash
# docker_cleanup.sh - Clean up Docker resources safely
#
# This script helps maintain a healthy Docker environment by:
# - Removing unused Docker data (images, containers, networks, build cache)
# - Removing dangling (unused) Docker volumes
# - Allowing users to select which cleanup actions to perform
# - Providing clear logging and error messages
#
# Usage: docker_cleanup.sh [--prune] [--volumes] [--help]
#
# Options:
#   --prune         Run docker system prune (remove unused data)
#   --volumes       Remove dangling volumes
#   -h, --help      Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

PRUNE="false"   # Whether to run docker system prune
VOLUMES="false" # Whether to remove dangling volumes

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prune)
      PRUNE="true"; shift;;      # Enable system prune
    --volumes)
      VOLUMES="true"; shift;;    # Enable volume prune
    -h|--help)
      show_help; exit 0;;        # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# If --prune is set, remove all unused Docker data
if [[ "$PRUNE" == "true" ]]; then
  echo "[INFO] Running: docker system prune -f"
  docker system prune -f
fi

# If --volumes is set, remove all dangling Docker volumes
if [[ "$VOLUMES" == "true" ]]; then
  echo "[INFO] Removing dangling volumes"
  docker volume prune -f
fi

echo "[SUCCESS] Docker cleanup complete."

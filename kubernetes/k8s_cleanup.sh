#!/usr/bin/env bash
# k8s_cleanup.sh - Clean up completed/failed jobs and unused pods in a namespace
#
# This script helps maintain Kubernetes cluster hygiene by:
# - Deleting completed jobs
# - Removing pods older than a specified age
# - Allowing namespace and age threshold customization
#
# Usage: k8s_cleanup.sh [-n|--namespace <namespace>] [--age <hours>] [--help]
#
# Options:
#   -n, --namespace     Kubernetes namespace (default: default)
#   --age               Age threshold in hours (default: 24)
#   -h, --help          Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

NAMESPACE="default"  # Default namespace
AGE=24                # Default age threshold in hours

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      NAMESPACE="$2"; shift 2;;  # Set namespace
    --age)
      AGE="$2"; shift 2;;        # Set age threshold
    -h|--help)
      show_help; exit 0;;        # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Delete jobs that have completed successfully in the specified namespace
kubectl -n "$NAMESPACE" get jobs --field-selector status.successful=1 --no-headers 2>/dev/null | awk '{print $1}' | xargs -r kubectl -n "$NAMESPACE" delete job 2>/dev/null || true

# Delete pods older than the specified age threshold in the namespace
kubectl -n "$NAMESPACE" get pods --no-headers | awk -v age="$AGE" '{if ($5 ~ /[0-9]+h/ && int($5) >= age) print $1}' | xargs -r kubectl -n "$NAMESPACE" delete pod

echo "[SUCCESS] Cleanup complete in namespace $NAMESPACE."

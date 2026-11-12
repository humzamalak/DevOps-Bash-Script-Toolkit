#!/usr/bin/env bash
# k8s_cleanup.sh - Clean up completed jobs and finished pods in a namespace
#
# This script helps maintain Kubernetes cluster hygiene by:
# - Deleting jobs that completed successfully
# - Deleting finished pods (phase Succeeded or Failed) older than a given age
# - Never deleting Running, Pending or Unknown pods
#
# Usage: k8s_cleanup.sh [-n|--namespace <namespace>] [--age <hours>] [--dry-run] [--help]
#
# Options:
#   -n, --namespace     Kubernetes namespace (default: default)
#   --age               Delete finished pods at least this many hours old (default: 24)
#   --dry-run           Print what would be deleted, but delete nothing
#   -h, --help          Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

NAMESPACE="default"  # Default namespace
AGE=24               # Default age threshold in hours
DRY_RUN="false"      # Whether to only print what would be deleted

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      NAMESPACE="$2"; shift 2;;  # Set namespace
    --age)
      AGE="$2"; shift 2;;        # Set age threshold
    --dry-run)
      DRY_RUN="true"; shift;;    # Print only
    -h|--help)
      show_help; exit 0;;        # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
done

if ! [[ "$AGE" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --age must be a whole number of hours." >&2; exit 1
fi

# Convert an RFC 3339 UTC timestamp (2026-01-02T03:04:05Z) to epoch seconds.
# GNU and BusyBox date use -d; BSD/macOS date uses -j -f.
to_epoch() {
  local ts="$1" plain
  plain="${ts%Z}"; plain="${plain/T/ }"
  date -u -d "$plain" +%s 2>/dev/null || date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s
}

# Delete or, in dry-run mode, print a resource
remove() {
  local kind="$1" name="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would delete $kind/$name"
  else
    kubectl -n "$NAMESPACE" delete "$kind" "$name"
  fi
}

# Delete jobs that have completed successfully
while read -r job; do
  [[ -n "$job" ]] && remove job "$job"
done < <(kubectl -n "$NAMESPACE" get jobs --field-selector status.successful=1 -o name 2>/dev/null | sed 's|^job[^/]*/||')

# Delete finished pods older than the age threshold
NOW=$(date -u +%s)
MAX_AGE_SECONDS=$(( AGE * 3600 ))
while read -r name phase created; do
  [[ -z "$name" ]] && continue
  case "$phase" in
    Succeeded|Failed) ;;
    *) continue;;  # Never touch Running, Pending or Unknown pods
  esac
  created_epoch=$(to_epoch "$created")
  if (( NOW - created_epoch >= MAX_AGE_SECONDS )); then
    remove pod "$name"
  fi
done < <(kubectl -n "$NAMESPACE" get pods -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{" "}{.metadata.creationTimestamp}{"\n"}{end}')

echo "[SUCCESS] Cleanup complete in namespace $NAMESPACE."

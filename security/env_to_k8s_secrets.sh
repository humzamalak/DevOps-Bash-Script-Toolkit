#!/usr/bin/env bash
# env_to_k8s_secrets.sh - Convert .env file to Kubernetes secrets
#
# This script automates the creation or update of Kubernetes secrets from a .env file:
# - Reads key-value pairs from a .env file
# - Creates or updates a Kubernetes secret in the specified namespace
# - Uses kubectl with --from-env-file and applies the secret manifest
# - Designed for use in CI/CD, secure deployments, or secret rotation
#
# Usage: env_to_k8s_secrets.sh -f <env_file> -n <namespace> -s <secret_name> [--help]
#
# Options:
#   -f, --file         Path to .env file (required)
#   -n, --namespace    Kubernetes namespace (required)
#   -s, --secret       Secret name (required)
#   -h, --help         Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

ENV_FILE=""   # Path to .env file
NAMESPACE=""  # Kubernetes namespace
SECRET=""     # Secret name

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      ENV_FILE="$2"; shift 2;;      # Set .env file path
    -n|--namespace)
      NAMESPACE="$2"; shift 2;;     # Set namespace
    -s|--secret)
      SECRET="$2"; shift 2;;        # Set secret name
    -h|--help)
      show_help; exit 0;;           # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Ensure all required arguments are provided
if [[ -z "$ENV_FILE" || -z "$NAMESPACE" || -z "$SECRET" ]]; then
  echo "[ERROR] File, namespace, and secret name are required."; show_help; exit 1
fi

# Create or update the Kubernetes secret from the .env file
kubectl -n "$NAMESPACE" create secret generic "$SECRET" --from-env-file="$ENV_FILE" --dry-run=client -o yaml | kubectl apply -f -

echo "[SUCCESS] Secret $SECRET created/updated in namespace $NAMESPACE."

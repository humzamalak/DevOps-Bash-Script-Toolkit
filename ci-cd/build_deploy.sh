#!/usr/bin/env bash
# build_deploy.sh - Build Docker image and deploy to Kubernetes
#
# This script automates the build and deployment process:
# - Builds a Docker image from the current directory
# - Pushes the image to a Docker registry
# - Updates a specified Kubernetes deployment with the new image
# - Allows customization of image name, deployment, and namespace
# - Designed for use in CI/CD pipelines or manual deployments
#
# Usage: build_deploy.sh -i <image> -d <deployment> [-n <namespace>] [--help]
#
# Options:
#   -i, --image        Docker image name (required)
#   -d, --deployment   Kubernetes deployment name (required)
#   -n, --namespace    Kubernetes namespace (default: default)
#   -h, --help         Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

IMAGE=""       # Docker image name
DEPLOYMENT=""  # Kubernetes deployment name
NAMESPACE="default"  # Kubernetes namespace (default)

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--image)
      IMAGE="$2"; shift 2;;         # Set Docker image name
    -d|--deployment)
      DEPLOYMENT="$2"; shift 2;;    # Set deployment name
    -n|--namespace)
      NAMESPACE="$2"; shift 2;;     # Set namespace
    -h|--help)
      show_help; exit 0;;           # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Ensure required arguments are provided
if [[ -z "$IMAGE" || -z "$DEPLOYMENT" ]]; then
  echo "[ERROR] Image and deployment are required."; show_help; exit 1
fi

echo "[INFO] Building Docker image: $IMAGE"
docker build -t "$IMAGE" .  # Build Docker image from current directory

echo "[INFO] Pushing Docker image: $IMAGE"
docker push "$IMAGE"        # Push image to registry

echo "[INFO] Updating Kubernetes deployment: $DEPLOYMENT"
# Update the deployment with the new image in the specified namespace
kubectl set image deployment/"$DEPLOYMENT" "$DEPLOYMENT"="$IMAGE" -n "$NAMESPACE"

echo "[SUCCESS] Build and deploy complete."

#!/usr/bin/env bash
# terraform_apply_wrapper.sh - Automate Terraform apply with safety and rollback
#
# This script wraps Terraform's apply command to provide additional safety features:
# - Allows specifying the working directory for Terraform configs
# - Supports auto-approve to skip interactive prompts
# - Optionally attempts a rollback (terraform destroy) if apply fails
# - Provides clear logging and error messages
#
# Usage: terraform_apply_wrapper.sh [-d|--dir <directory>] [--auto-approve] [--rollback] [--help]
#
# Options:
#   -d, --dir           Directory containing Terraform config (default: current)
#   --auto-approve      Skip interactive approval
#   --rollback          Attempt rollback on failure
#   -h, --help          Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

TF_DIR="."         # Default directory for Terraform configs
AUTO_APPROVE=""    # Flag for auto-approve
ROLLBACK="false"   # Whether to attempt rollback on failure

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      TF_DIR="$2"; shift 2;;  # Set working directory
    --auto-approve)
      AUTO_APPROVE="-auto-approve"; shift;;  # Enable auto-approve
    --rollback)
      ROLLBACK="true"; shift;;  # Enable rollback on failure
    -h|--help)
      show_help; exit 0;;  # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Change to the specified Terraform directory
cd "$TF_DIR"
echo "[INFO] Running: terraform init"
terraform init  # Initialize Terraform working directory

echo "[INFO] Running: terraform plan"
terraform plan  # Show planned changes

echo "[INFO] Running: terraform apply $AUTO_APPROVE"
# Attempt to apply changes; if it fails, optionally rollback
if ! terraform apply $AUTO_APPROVE; then
  echo "[ERROR] Terraform apply failed."
  if [[ "$ROLLBACK" == "true" ]]; then
    echo "[INFO] Attempting rollback (terraform destroy)"
    terraform destroy $AUTO_APPROVE || echo "[WARN] Rollback failed. Manual intervention required."
  fi
  exit 1
fi

echo "[SUCCESS] Terraform apply completed."

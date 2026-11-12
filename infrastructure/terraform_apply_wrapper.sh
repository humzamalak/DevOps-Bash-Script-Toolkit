#!/usr/bin/env bash
# terraform_apply_wrapper.sh - Run Terraform init, plan and apply with clear logging
#
# This script wraps Terraform's apply command:
# - Allows specifying the working directory for Terraform configs
# - Supports auto-approve to skip interactive prompts
# - Never destroys infrastructure: if apply fails, it stops and reports
# - Provides clear logging and error messages
#
# Usage: terraform_apply_wrapper.sh [-d|--dir <directory>] [--auto-approve] [--help]
#
# Options:
#   -d, --dir           Directory containing Terraform config (default: current)
#   --auto-approve      Skip interactive approval
#   -h, --help          Show this help message
#
# On a failed apply, Terraform keeps the resources it created or changed
# before the error. Run 'terraform plan' to see the current state, fix the
# cause, then run this script again.

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

TF_DIR="."         # Default directory for Terraform configs
AUTO_APPROVE=""    # Flag for auto-approve

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      TF_DIR="$2"; shift 2;;  # Set working directory
    --auto-approve)
      AUTO_APPROVE="-auto-approve"; shift;;  # Enable auto-approve
    --rollback)
      # Removed: it ran 'terraform destroy', which deletes the whole stack,
      # including resources that existed before this apply.
      echo "[ERROR] --rollback was removed because it ran 'terraform destroy' on the whole stack." >&2
      echo "[ERROR] On a failed apply, run 'terraform plan', fix the cause and apply again." >&2
      exit 2;;
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
# Apply changes. On failure, stop: do not destroy anything.
if ! terraform apply $AUTO_APPROVE; then
  echo "[ERROR] Terraform apply failed. Some changes may already be applied."
  echo "[ERROR] Run 'terraform plan' in $TF_DIR to review the state, fix the cause, then run this script again."
  exit 1
fi

echo "[SUCCESS] Terraform apply completed."

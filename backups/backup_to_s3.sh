#!/usr/bin/env bash
# backup_to_s3.sh - Backup files/directories to AWS S3
#
# This script automates the backup of files or directories to an AWS S3 bucket:
# - Uses awscli to sync local data to S3
# - Supports custom S3 key prefixes for organization
# - Provides clear logging and error messages
# - Designed for use in scheduled backups, pre-deployment, or disaster recovery
#
# Usage: backup_to_s3.sh -s <source> -b <bucket> [-k <key_prefix>] [--help]
#
# Options:
#   -s, --source        Source file or directory to back up
#   -b, --bucket        S3 bucket name
#   -k, --key-prefix    S3 key prefix (optional)
#   -h, --help          Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

SOURCE=""     # Path to source file or directory
BUCKET=""     # S3 bucket name
KEY_PREFIX="" # Optional S3 key prefix

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source)
      SOURCE="$2"; shift 2;;      # Set source path
    -b|--bucket)
      BUCKET="$2"; shift 2;;      # Set S3 bucket name
    -k|--key-prefix)
      KEY_PREFIX="$2"; shift 2;;  # Set S3 key prefix
    -h|--help)
      show_help; exit 0;;         # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Ensure required arguments are provided
if [[ -z "$SOURCE" || -z "$BUCKET" ]]; then
  echo "[ERROR] Source and bucket are required."; show_help; exit 1
fi

# Build S3 destination path
if [[ -n "$KEY_PREFIX" ]]; then
  DEST="s3://$BUCKET/$KEY_PREFIX/"
else
  DEST="s3://$BUCKET/"
fi

echo "[INFO] Syncing $SOURCE to $DEST"
# Perform the sync using awscli
aws s3 sync "$SOURCE" "$DEST"

echo "[SUCCESS] Backup to S3 complete."

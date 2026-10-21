#!/usr/bin/env bash
# autotag.sh - Semantic version auto-tagging based on commit messages
#
# This script automates semantic versioning for your repository:
# - Determines the latest tag and inspects commit messages since that tag
# - Increments major, minor, or patch version based on commit content
#   - 'BREAKING CHANGE' in commit: major
#   - 'feat:' in commit: minor
#   - 'fix:' in commit: patch
# - Supports a dry-run mode to preview the next tag
# - Designed for use in CI/CD pipelines or release automation
#
# Usage: autotag.sh [--dry-run] [--help]
#
# Options:
#   --dry-run     Show what would be tagged, but do not create tag
#   -h, --help    Show this help message

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Print help message by extracting comments from the script
show_help() {
  grep '^#' "$0" | cut -c 3-
}

DRY_RUN="false"  # Whether to only preview the tag

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN="true"; shift;;    # Enable dry-run mode
    -h|--help)
      show_help; exit 0;;         # Show help and exit
    *)
      echo "Unknown option: $1"; show_help; exit 1;;  # Handle unknown options
  esac
  done

# Get the latest tag, or default to 0.0.0 if none exists
if LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null); then
  RANGE="${LATEST_TAG}..HEAD"
else
  LATEST_TAG="0.0.0"; RANGE="HEAD"  # No tags yet: inspect the whole history
fi
# Get full commit messages since the latest tag, one record per commit (NUL-separated)
COMMITS=$(git log "$RANGE" --format='%B%x00' | tr '\0' '\036')

# Parse the latest tag into major, minor, patch (a leading 'v' is ignored)
MAJOR=0; MINOR=0; PATCH=0
IFS='.' read -r MAJOR MINOR PATCH <<< "${LATEST_TAG#v}"
PREFIX=""; [[ "$LATEST_TAG" == v* ]] && PREFIX="v"  # Keep the existing tag style

# Inspect every commit; the largest bump found wins (major > minor > patch)
BUMP="none"
while IFS= read -r -d $'\036' c; do
  c="${c#$'\n'}"  # git separates records with a newline
  if [[ "$c" == *"BREAKING CHANGE"* || "$c" =~ ^[a-z]+(\(.*\))?!: ]]; then
    BUMP="major"; break
  elif [[ "$c" =~ ^feat(\(.*\))?: ]]; then
    BUMP="minor"
  elif [[ "$c" =~ ^fix(\(.*\))?: && "$BUMP" == "none" ]]; then
    BUMP="patch"
  fi
done <<< "$COMMITS"

case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0;;  # Major bump resets minor/patch
  minor) MINOR=$((MINOR + 1)); PATCH=0;;           # Minor bump resets patch
  patch) PATCH=$((PATCH + 1));;
  none)  echo "[INFO] No feat/fix/breaking commits since $LATEST_TAG; nothing to tag."; exit 0;;
esac

target_tag="${PREFIX}$MAJOR.$MINOR.$PATCH"  # Construct the new tag
if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY RUN] Would tag: $target_tag"
else
  git tag "$target_tag"
  echo "[INFO] Created tag: $target_tag"
fi

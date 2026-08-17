#!/usr/bin/env bash
# Commit the updated Homebrew cask definition.
set -euo pipefail

tap_dir=""
version=""
dry_run=false

while [ "$#" -gt 0 ]; do
  case "$1" in
  --tap-dir) tap_dir="${2:?missing value for --tap-dir}"; shift 2 ;;
  --version) version="${2:?missing value for --version}"; shift 2 ;;
  --dry-run) dry_run=true; shift ;;
  *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$tap_dir" ] || [ -z "$version" ]; then
  echo "Usage: $0 --tap-dir DIR --version VERSION [--dry-run]" >&2
  exit 2
fi

cd "$tap_dir"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A -- Casks/easybar-native.rb

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

if [ "$dry_run" = true ]; then
  echo "Homebrew cask change is ready to commit for easybar-native ${version}."
  git diff --cached --stat
  exit 0
fi

git commit -m "easybar-native ${version}"
git push

#!/usr/bin/env bash
# Remove a local development installation.
set -Eeuo pipefail

# Print supported command-line arguments.
usage() {
  cat >&2 <<'EOF_USAGE'
Usage: scripts/dev/uninstall-local.sh [options]

Remove the local EasyBar Native app and CLI link created by make install-local.
Native config, logs, widgets, and managed packages are preserved.

Options:
  --app-dir <dir>  App installation directory. Default: ~/Applications
  --bin-dir <dir>  CLI link directory. Default: ~/.local/bin
EOF_USAGE
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_root="$(cd -- "$script_dir/../.." && pwd -P)"

app_dir="${LOCAL_APP_DIR:-$HOME/Applications}"
bin_dir="${LOCAL_BIN_DIR:-$HOME/.local/bin}"

while [ "$#" -gt 0 ]; do
  case "$1" in
  --app-dir)
    app_dir="${2:?missing value for --app-dir}"
    shift 2
    ;;
  --bin-dir)
    bin_dir="${2:?missing value for --bin-dir}"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    exit 2
    ;;
  esac
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Local uninstallation is supported only on macOS." >&2
  exit 1
fi

# Exit unless a required command is available.
require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
}

# Remove a file, symlink, or directory when present.
remove_path() {
  local path="$1"
  local parent

  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    return
  fi

  parent="$(dirname -- "$path")"
  if [ -w "$parent" ]; then
    rm -rf "$path"
    return
  fi

  require_command sudo
  sudo rm -rf "$path"
}

app_destination="${app_dir%/}/EasyBarNative.app"
cli_destination="${bin_dir%/}/easybar-native"

bash "$project_root/scripts/dev/stop-local.sh"
remove_path "$cli_destination"
remove_path "$app_destination"

cat <<EOF_SUMMARY
Local EasyBar Native installation removed.

Removed app: $app_destination
Removed CLI: $cli_destination

Preserved:
  ~/.config/easybar-native
  ~/.local/state/easybar-native
  ~/.local/share/easybar-native
EOF_SUMMARY

#!/usr/bin/env bash
# Install a local development build.
set -Eeuo pipefail

# Print supported command-line arguments.
usage() {
  cat >&2 <<'EOF_USAGE'
Usage: scripts/dev/install-local.sh [options]

Build artifacts must already exist in dist/.

Options:
  --dist-dir <dir>  Distribution directory. Default: dist
  --app-dir <dir>   App installation directory. Default: ~/Applications
  --bin-dir <dir>   CLI link directory. Default: ~/.local/bin
  --no-launch       Install without launching EasyBar Native.
EOF_USAGE
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_root="$(cd -- "$script_dir/../.." && pwd -P)"

dist_dir="${DIST_DIR:-dist}"
app_dir="${LOCAL_APP_DIR:-$HOME/Applications}"
bin_dir="${LOCAL_BIN_DIR:-$HOME/.local/bin}"
launch_app=true

while [ "$#" -gt 0 ]; do
  case "$1" in
  --dist-dir)
    dist_dir="${2:?missing value for --dist-dir}"
    shift 2
    ;;
  --app-dir)
    app_dir="${2:?missing value for --app-dir}"
    shift 2
    ;;
  --bin-dir)
    bin_dir="${2:?missing value for --bin-dir}"
    shift 2
    ;;
  --no-launch)
    launch_app=false
    shift
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
  echo "Local installation is supported only on macOS." >&2
  exit 1
fi

case "$dist_dir" in
/*) ;;
*) dist_dir="$project_root/$dist_dir" ;;
esac

# Exit unless a required command is available.
require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
}

# Exit unless a required path exists.
require_path() {
  local path="$1"
  local label="$2"

  if [ ! -e "$path" ]; then
    echo "Missing ${label}: ${path}" >&2
    exit 1
  fi
}

# Create a directory with the expected permissions.
ensure_directory() {
  local directory="$1"

  if [ -d "$directory" ]; then
    return
  fi

  if mkdir -p "$directory" 2>/dev/null; then
    return
  fi

  require_command sudo
  sudo mkdir -p "$directory"
}

# Replace the installed application bundle.
replace_bundle() {
  local source="$1"
  local destination="$2"
  local parent
  local stage

  parent="$(dirname -- "$destination")"
  ensure_directory "$parent"
  stage="${parent}/.${destination##*/}.local-install.$$"

  if [ -w "$parent" ]; then
    rm -rf "$stage"
    ditto "$source" "$stage"
    rm -rf "$destination"
    mv "$stage" "$destination"
    return
  fi

  require_command sudo
  sudo rm -rf "$stage"
  sudo ditto "$source" "$stage"
  sudo rm -rf "$destination"
  sudo mv "$stage" "$destination"
}

# Replace an installed symbolic link.
replace_symlink() {
  local source="$1"
  local destination="$2"
  local parent
  local stage

  parent="$(dirname -- "$destination")"
  ensure_directory "$parent"
  stage="${destination}.local-install.$$"

  if [ -w "$parent" ]; then
    rm -rf "$stage" "$destination"
    ln -s "$source" "$stage"
    mv "$stage" "$destination"
    return
  fi

  require_command sudo
  sudo rm -rf "$stage" "$destination"
  sudo ln -s "$source" "$stage"
  sudo mv "$stage" "$destination"
}

# Clear quarantine attributes from a directory tree.
clear_quarantine_recursive() {
  local path="$1"

  xattr -dr com.apple.quarantine "$path" >/dev/null 2>&1 || true

  if xattr -lr "$path" 2>/dev/null | grep -Fq "com.apple.quarantine"; then
    echo "Failed to remove quarantine from: $path" >&2
    exit 1
  fi
}

require_command ditto
require_command grep
require_command open
require_command xattr

app_source="$dist_dir/EasyBarNative.app"
cli_source="$app_source/Contents/MacOS/easybar-native"
require_path "$app_source" "EasyBar Native app bundle"
require_path "$cli_source" "easybar-native CLI"

app_destination="${app_dir%/}/EasyBarNative.app"
cli_destination="${bin_dir%/}/easybar-native"

bash "$project_root/scripts/dev/stop-local.sh"

echo "Installing EasyBarNative.app into $app_destination"
replace_bundle "$app_source" "$app_destination"

echo "Linking easybar-native into $cli_destination"
replace_symlink "$app_destination/Contents/MacOS/easybar-native" "$cli_destination"

echo "Removing quarantine from local EasyBar Native app"
clear_quarantine_recursive "$app_destination"

if [ "$launch_app" = true ]; then
  echo "Launching EasyBar Native"
  open "$app_destination"
fi

cat <<EOF_SUMMARY
Local EasyBar Native installation complete.

App: $app_destination
CLI: $cli_destination
EOF_SUMMARY

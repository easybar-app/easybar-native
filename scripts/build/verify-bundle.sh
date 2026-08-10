#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: scripts/build/verify-bundle.sh [--arch <arm64|x86_64|universal>] [--version <version>] [--dist-dir <dir>]" >&2
}

arch=""
version="${VERSION:-dev}"
dist_dir="${DIST_DIR:-dist}"

if [ "$#" -eq 1 ]; then
  arch="$1"
  shift
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
  --arch)
    arch="${2:?missing value for --arch}"
    shift 2
    ;;
  --version)
    version="${2:?missing value for --version}"
    shift 2
    ;;
  --dist-dir)
    dist_dir="${2:?missing value for --dist-dir}"
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

if [ -z "$arch" ]; then
  arch="${ARCH:-universal}"
fi

case "$arch" in
arm64 | x86_64 | universal) ;;
*)
  echo "Unsupported architecture '$arch'. Use arm64, x86_64, or universal." >&2
  exit 2
  ;;
esac

app_name="EasyBarNative"
app_bundle="$dist_dir/${app_name}.app"
app_contents="$app_bundle/Contents"
app_macos="$app_contents/MacOS"
app_resources="$app_contents/Resources"
app_resource_dir="$app_resources/EasyBar"
app_themes_dir="$app_resources/Themes"
app_bin="$app_macos/$app_name"
lua_runtime_bin="$app_macos/EasyBarLuaRuntime"
cli_core_bin="$app_resources/EasyBarNative/CLI/EasyBarCtl"
cli_bin="$app_macos/easybar-native"
plist="$app_contents/Info.plist"
app_icon_file="$app_name"
app_icon_icns="$app_resources/${app_icon_file}.icns"

require_file() {
  local path="$1"
  local label="$2"

  if [ ! -f "$path" ]; then
    echo "Missing ${label}: ${path}" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  local label="$2"

  if [ ! -d "$path" ]; then
    echo "Missing ${label}: ${path}" >&2
    exit 1
  fi
}

verify_architecture() {
  local path="$1"
  local label="$2"
  local arches

  arches="$(lipo -archs "$path")"

  case "$arch" in
  arm64 | x86_64)
    if [ "$arches" != "$arch" ]; then
      echo "Unexpected architecture for ${label}: expected ${arch}, got ${arches}" >&2
      exit 1
    fi
    ;;
  universal)
    case " $arches " in
    *" arm64 "*) ;;
    *)
      echo "Universal ${label} is missing arm64: ${arches}" >&2
      exit 1
      ;;
    esac
    case " $arches " in
    *" x86_64 "*) ;;
    *)
      echo "Universal ${label} is missing x86_64: ${arches}" >&2
      exit 1
      ;;
    esac
    ;;
  esac
}

require_file "$app_bin" "EasyBarNative executable"
require_file "$lua_runtime_bin" "EasyBarLuaRuntime executable"
require_file "$cli_core_bin" "EasyBarCtl executable"
require_file "$cli_bin" "easybar-native executable"

echo "Built $arch artifacts:"
file "$app_bin"
file "$lua_runtime_bin"
file "$cli_core_bin"
file "$cli_bin"

verify_architecture "$app_bin" "EasyBarNative"
verify_architecture "$lua_runtime_bin" "EasyBarLuaRuntime"
verify_architecture "$cli_core_bin" "EasyBarCtl"
verify_architecture "$cli_bin" "easybar-native"

require_file "$plist" "EasyBar Native Info.plist"
require_dir "$app_resource_dir" "app resource directory"
require_file "$app_resource_dir/Assets/easybar-menubar.svg" "menu bar icon resource"
require_file "$app_resource_dir/Lua/runtime.lua" "Lua runtime resource"
require_file "$app_resource_dir/Lua/easybar_api.lua" "Lua API stub"
require_dir "$app_resource_dir/Lua/easybar" "Lua easybar module"
require_file "$app_resource_dir/Events/event_catalog.json" "event catalog"
require_file "$app_resource_dir/ThemeTokens/theme_tokens.json" "theme token catalog"
require_dir "$app_themes_dir" "themes directory"
require_file "$app_icon_icns" "EasyBar Native icon"

if [ -e "$app_contents/Library/LoginItems" ]; then
  echo "Unexpected nested helper app directory: $app_contents/Library/LoginItems" >&2
  exit 1
fi

test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$plist")" = "$app_icon_file"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" = "$version"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")" = "$version"

app_version_output="$("$app_bin" --version)"
cli_version_output="$("$cli_bin" --version)"
core_cli_version_output="$("$cli_core_bin" --version)"
test "$app_version_output" = "EasyBar Native $version"
test "$cli_version_output" = "easybar-native $version"
test "$core_cli_version_output" = "easybar $version"
echo "Verified binary versions: $app_version_output; $cli_version_output"

codesign --verify --deep --strict "$app_bundle"

echo "Info.plist:"
plutil -p "$plist"
echo "Packaged Contents:"
ls -1 "$app_contents"
echo "Packaged executables:"
ls -1 "$app_macos"
echo "Packaged Resources:"
ls -1 "$app_resources" 2>/dev/null || true

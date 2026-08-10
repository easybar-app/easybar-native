#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "bundle failed at line $LINENO: $BASH_COMMAND" >&2' ERR

usage() {
  cat >&2 <<'EOF_USAGE'
Usage: scripts/build/bundle.sh [options]

Options:
  --kit-root <dir>       Use this EasyBarKit checkout instead of the resolved package dependency.
  --arch <arch>          arm64, x86_64, or universal. Default: universal
  --version <version>    Version stamped into all artifacts. Default: dev
  --bundle-id <id>       EasyBar Native bundle identifier. Default: io.github.gi8lino.easybar-native
  --dist-dir <dir>       Distribution directory. Default: dist
EOF_USAGE
}

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
kit_root=""
arch="${ARCH:-universal}"
version="${VERSION:-dev}"
bundle_id="${BUNDLE_ID:-io.github.gi8lino.easybar-native}"
dist_dir="${DIST_DIR:-dist}"

while [ "$#" -gt 0 ]; do
  case "$1" in
  --kit-root)
    kit_root="${2:?missing value for --kit-root}"
    shift 2
    ;;
  --arch)
    arch="${2:?missing value for --arch}"
    shift 2
    ;;
  --version)
    version="${2:?missing value for --version}"
    shift 2
    ;;
  --bundle-id)
    bundle_id="${2:?missing value for --bundle-id}"
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

case "$arch" in
arm64 | x86_64 | universal) ;;
*)
  echo "Unsupported architecture '$arch'. Use arm64, x86_64, or universal." >&2
  exit 2
  ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  echo "EasyBar Native app bundling is supported only on macOS." >&2
  exit 1
fi

case "$dist_dir" in
/*) ;;
*) dist_dir="$project_root/$dist_dir" ;;
esac

require_command() {
  local command_name="$1"
  local hint="${2:-}"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    if [ -n "$hint" ]; then
      echo "$hint" >&2
    fi
    exit 1
  fi
}

require_file() {
  local path="$1"
  local label="$2"

  if [ ! -f "$path" ]; then
    echo "Missing $label: $path" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  local label="$2"

  if [ ! -d "$path" ]; then
    echo "Missing $label: $path" >&2
    exit 1
  fi
}

stage_writable_file() {
  local source="$1"
  local destination="$2"
  install -m 0644 "$source" "$destination"
}

require_command swift
require_command install
require_command codesign
require_command lipo
require_command python3
require_command rsvg-convert "Install librsvg with: brew install librsvg"
require_command magick "Install ImageMagick with: brew install imagemagick"
require_command sips
require_command iconutil

resolve_easybar_kit_dependency_path() {
  (
    cd "$project_root"
    swift package resolve >/dev/null
    swift package show-dependencies --format json
  ) | python3 -c 'import json, os, sys
root = json.load(sys.stdin)
stack = [root]
while stack:
    item = stack.pop()
    if item.get("identity") == "easybar-kit":
        print(os.path.realpath(item["path"]))
        raise SystemExit(0)
    stack.extend(item.get("dependencies", []))
raise SystemExit("easybar-kit dependency not found")'
}

dependency_override_added=false

restore_dependency_override() {
  local status=$?
  trap - EXIT

  if [ "$dependency_override_added" = true ]; then
    echo "Restoring EasyBar package dependency state"
    if ! (cd "$project_root" && swift package unedit easybar-kit --force >/dev/null); then
      echo "Failed to restore EasyBarKit dependency state" >&2
      status=1
    fi
  fi

  exit "$status"
}
trap restore_dependency_override EXIT

resolved_kit_root="$(resolve_easybar_kit_dependency_path)"
if [ -n "$kit_root" ]; then
  if [ ! -f "$kit_root/Package.swift" ]; then
    echo "EasyBarKit checkout not found: $kit_root" >&2
    exit 1
  fi
  kit_root="$(cd -- "$kit_root" && pwd -P)"

  if [ "$resolved_kit_root" != "$kit_root" ]; then
    echo "Using local EasyBarKit checkout: $kit_root"
    (cd "$project_root" && swift package edit easybar-kit --path "$kit_root")
    dependency_override_added=true
  fi
else
  kit_root="$resolved_kit_root"
fi

build_version_file="$kit_root/.build/easybar-build-version"
mkdir -p "$(dirname "$build_version_file")"
printf '%s\n' "$version" >"$build_version_file"

rm -rf "$dist_dir"
mkdir -p "$dist_dir"

app_name="EasyBarNative"
app_bundle="$dist_dir/${app_name}.app"
app_contents="$app_bundle/Contents"
app_macos="$app_contents/MacOS"
app_resources="$app_contents/Resources"
app_resource_dir="$app_resources/EasyBar"
app_themes_dir="$app_resources/Themes"
app_bin="$app_macos/EasyBarNative"
lua_runtime_bin="$app_macos/EasyBarLuaRuntime"
cli_core_dir="$app_resources/EasyBarNative/CLI"
cli_core_bin="$cli_core_dir/EasyBarCtl"
cli_bin="$app_macos/easybar-native"
app_plist="$app_contents/Info.plist"
app_icon_icns="$app_resources/EasyBarNative.icns"

mkdir -p \
  "$app_macos" \
  "$app_resource_dir/Lua" \
  "$app_resource_dir/Events" \
  "$app_resource_dir/ThemeTokens" \
  "$app_resource_dir/Assets" \
  "$app_themes_dir" \
  "$cli_core_dir"

root_product_path() {
  local build_arch="$1"
  local product="$2"
  local bin_dir

  (
    cd "$project_root"
    swift build -c release --arch "$build_arch" --product "$product" >&2
  )
  bin_dir="$(cd "$project_root" && swift build -c release --arch "$build_arch" --show-bin-path)"
  printf '%s/%s\n' "$bin_dir" "$product"
}

kit_product_path() {
  local build_arch="$1"
  local product="$2"
  local bin_dir

  swift build --package-path "$kit_root" -c release --arch "$build_arch" --product "$product" >&2
  bin_dir="$(swift build --package-path "$kit_root" -c release --arch "$build_arch" --show-bin-path)"
  printf '%s/%s\n' "$bin_dir" "$product"
}

stage_product() {
  local owner="$1"
  local product="$2"
  local destination="$3"
  local arm64_path
  local x86_64_path
  local source_path

  echo "Building $product ($arch)"

  if [ "$arch" = universal ]; then
    if [ "$owner" = root ]; then
      arm64_path="$(root_product_path arm64 "$product")"
      x86_64_path="$(root_product_path x86_64 "$product")"
    else
      arm64_path="$(kit_product_path arm64 "$product")"
      x86_64_path="$(kit_product_path x86_64 "$product")"
    fi

    require_file "$arm64_path" "$product arm64 executable"
    require_file "$x86_64_path" "$product x86_64 executable"
    lipo -create "$arm64_path" "$x86_64_path" -output "$destination"
  else
    if [ "$owner" = root ]; then
      source_path="$(root_product_path "$arch" "$product")"
    else
      source_path="$(kit_product_path "$arch" "$product")"
    fi

    require_file "$source_path" "$product executable"
    cp "$source_path" "$destination"
  fi

  require_file "$destination" "staged $product executable"
}

stage_product root EasyBarNative "$app_bin"
stage_product root EasyBarNativeCtl "$cli_bin"
stage_product kit EasyBarLuaRuntime "$lua_runtime_bin"
stage_product kit EasyBarCtl "$cli_core_bin"
chmod +x "$app_bin" "$lua_runtime_bin" "$cli_core_bin" "$cli_bin"

app_version_output="$("$app_bin" --version)"
cli_version_output="$("$cli_bin" --version)"
core_cli_version_output="$("$cli_core_bin" --version)"
if [ "$app_version_output" != "EasyBar Native $version" ]; then
  echo "EasyBar Native binary version mismatch: expected 'EasyBar Native $version', got '$app_version_output'" >&2
  exit 1
fi
if [ "$cli_version_output" != "easybar-native $version" ]; then
  echo "EasyBar Native CLI version mismatch: expected 'easybar-native $version', got '$cli_version_output'" >&2
  exit 1
fi
if [ "$core_cli_version_output" != "easybar $version" ]; then
  echo "Shared CLI core version mismatch: expected 'easybar $version', got '$core_cli_version_output'" >&2
  exit 1
fi
echo "Verified binary versions: $app_version_output; $cli_version_output"

echo "Staging EasyBarKit runtime resources"
require_file "$kit_root/Sources/EasyBarKit/Lua/runtime.lua" "runtime.lua"
require_file "$kit_root/Sources/EasyBarKit/Lua/easybar_api.lua" "Lua API stub"
require_dir "$kit_root/Sources/EasyBarKit/Lua/easybar" "Lua easybar module"
require_file "$kit_root/Sources/EasyBarKit/Events/event_catalog.json" "event catalog"
require_file "$kit_root/Sources/EasyBarKit/Theme/theme_tokens.json" "theme token catalog"
require_file "$kit_root/Sources/EasyBarKit/Assets/easybar-menubar.svg" "menu bar icon"
require_dir "$kit_root/themes" "themes directory"

stage_writable_file "$kit_root/Sources/EasyBarKit/Lua/runtime.lua" "$app_resource_dir/Lua/runtime.lua"
stage_writable_file "$kit_root/Sources/EasyBarKit/Lua/easybar_api.lua" "$app_resource_dir/Lua/easybar_api.lua"
cp -R "$kit_root/Sources/EasyBarKit/Lua/easybar" "$app_resource_dir/Lua/easybar"
stage_writable_file "$kit_root/Sources/EasyBarKit/Events/event_catalog.json" "$app_resource_dir/Events/event_catalog.json"
stage_writable_file "$kit_root/Sources/EasyBarKit/Theme/theme_tokens.json" "$app_resource_dir/ThemeTokens/theme_tokens.json"
stage_writable_file "$kit_root/Sources/EasyBarKit/Assets/easybar-menubar.svg" "$app_resource_dir/Assets/easybar-menubar.svg"
cp -R "$kit_root/themes/." "$app_themes_dir/"

python3 "$project_root/scripts/build/stamp.py" lua-api \
  --file "$app_resource_dir/Lua/easybar_api.lua" \
  --version "$version"

echo "Staging bundle metadata"
require_file "$project_root/Sources/EasyBarNativeApp/Info.plist" "EasyBar Native Info.plist"
stage_writable_file "$project_root/Sources/EasyBarNativeApp/Info.plist" "$app_plist"

python3 "$project_root/scripts/build/stamp.py" plist \
  --plist "$app_plist" \
  --bundle-id "$bundle_id" \
  --version "$version" \
  --executable EasyBarNative \
  --name "EasyBar Native" \
  --icon-file EasyBarNative

echo "Generating bundle icon"
"$project_root/scripts/assets/app_icons.sh" \
  rsvg-convert \
  magick \
  "$dist_dir" \
  "$kit_root/packaging/easybar-icon.svg:$app_icon_icns"

echo "Ad-hoc signing app executables"
for executable in "$lua_runtime_bin" "$cli_core_bin" "$cli_bin"; do
  codesign --force --sign - "$executable"
done
codesign --force --deep --sign - "$app_bundle"
touch "$app_bundle"

require_file "$app_resource_dir/Lua/runtime.lua" "staged runtime.lua"
require_file "$app_resource_dir/Lua/easybar_api.lua" "staged Lua API stub"
require_file "$app_resource_dir/Events/event_catalog.json" "staged event catalog"
require_file "$app_resource_dir/ThemeTokens/theme_tokens.json" "staged theme tokens"
require_file "$app_themes_dir/default.toml" "default theme"
require_file "$app_icon_icns" "EasyBar Native icon"

printf '\nBundle ready:\n'
printf '  App:  %s\n' "$app_bundle"
printf '  CLI:  %s\n' "$cli_bin"

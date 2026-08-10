#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "release verification failed at line $LINENO: $BASH_COMMAND" >&2' ERR

version="${VERSION:-dev}"
arch="${ARCH:-universal}"
dist_dir="${DIST_DIR:-dist}"

while [ "$#" -gt 0 ]; do
  case "$1" in
  --version)
    version="${2:?missing value for --version}"
    shift 2
    ;;
  --arch)
    arch="${2:?missing value for --arch}"
    shift 2
    ;;
  --dist-dir)
    dist_dir="${2:?missing value for --dist-dir}"
    shift 2
    ;;
  -h | --help)
    echo "Usage: $0 [--version VERSION] [--arch ARCH] [--dist-dir DIR]" >&2
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 2
    ;;
  esac
done

scripts/build/verify-bundle.sh --arch "$arch" --version "$version" --dist-dir "$dist_dir"

package_zip="$dist_dir/EasyBarNative-$version.zip"
if [ ! -f "$package_zip" ]; then
  echo "Missing release package: $package_zip" >&2
  exit 1
fi

for expected_entry in \
  "EasyBarNative.app/Contents/MacOS/EasyBarNative" \
  "EasyBarNative.app/Contents/MacOS/EasyBarLuaRuntime" \
  "EasyBarNative.app/Contents/Resources/EasyBarNative/CLI/EasyBarCtl" \
  "EasyBarNative.app/Contents/MacOS/easybar-native"
do
  if ! unzip -Z1 "$package_zip" | grep -Fxq "$expected_entry"; then
    echo "Release archive does not contain expected executable: $expected_entry" >&2
    unzip -Z1 "$package_zip" >&2
    exit 1
  fi
done

echo "Release package:"
ls -lh "$package_zip"
shasum -a 256 "$package_zip"
codesign -dv --verbose=4 "$dist_dir/EasyBarNative.app" 2>&1 || true

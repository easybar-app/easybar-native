#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "package failed at line $LINENO: $BASH_COMMAND" >&2' ERR

version="${VERSION:-dev}"
dist_dir="${DIST_DIR:-dist}"

while [ "$#" -gt 0 ]; do
  case "$1" in
  --version)
    version="${2:?missing value for --version}"
    shift 2
    ;;
  --dist-dir)
    dist_dir="${2:?missing value for --dist-dir}"
    shift 2
    ;;
  -h | --help)
    echo "Usage: $0 [--version VERSION] [--dist-dir DIR]" >&2
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 2
    ;;
  esac
done

app_bundle="$dist_dir/EasyBarNative.app"
package_stage="$dist_dir/package-native"
package_zip="$dist_dir/EasyBarNative-$version.zip"

if [ ! -d "$app_bundle" ]; then
  echo "Missing EasyBar Native app bundle: $app_bundle" >&2
  exit 1
fi

mkdir -p "$dist_dir"
rm -rf "$package_stage" "$package_zip"
mkdir -p "$package_stage"
cp -R "$app_bundle" "$package_stage/EasyBarNative.app"

package_dir="$(cd "$dist_dir" && pwd -P)"
package_zip="$package_dir/EasyBarNative-$version.zip"
(
  cd "$package_stage"
  zip -qry "$package_zip" EasyBarNative.app
)
rm -rf "$package_stage"

echo "Created $package_zip"

#!/usr/bin/env bash
set -euo pipefail

tap_dir=""
repository="${GITHUB_REPOSITORY:-easybar-app/easybar-native}"
tag=""
version=""
sha=""

while [ "$#" -gt 0 ]; do
  case "$1" in
  --tap-dir) tap_dir="${2:?missing value for --tap-dir}"; shift 2 ;;
  --repository) repository="${2:?missing value for --repository}"; shift 2 ;;
  --tag) tag="${2:?missing value for --tag}"; shift 2 ;;
  --version) version="${2:?missing value for --version}"; shift 2 ;;
  --sha) sha="${2:?missing value for --sha}"; shift 2 ;;
  *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$tap_dir" ] || [ -z "$version" ] || [ -z "$sha" ]; then
  echo "Usage: $0 --tap-dir DIR --version VERSION --sha SHA [--repository OWNER/REPO] [--tag TAG]" >&2
  exit 2
fi

if [ -z "$tag" ]; then
  tag="v${version}"
fi

cask_dir="$tap_dir/Casks"
cask_file="$cask_dir/easybar-native.rb"
asset_url="https://github.com/${repository}/releases/download/${tag}/EasyBarNative-${version}.zip"
mkdir -p "$cask_dir"

cat > "$cask_file" <<EOF_CASK
cask "easybar-native" do
  version "${version}"
  sha256 "${sha}"

  url "${asset_url}"
  name "EasyBar Native"
  desc "Native macOS menu-bar frontend for EasyBarKit Lua widgets"
  homepage "https://github.com/${repository}"

  depends_on formula: "lua"
  depends_on macos: :sonoma

  postflight do
    system "xattr", "-dr", "com.apple.quarantine", "#{appdir}/EasyBarNative.app"
  end

  app "EasyBarNative.app"
  binary "#{appdir}/EasyBarNative.app/Contents/MacOS/easybar-native", target: "easybar-native"

  zap trash: [
    "~/.config/easybar-native",
    "~/.local/share/easybar-native",
    "~/.local/state/easybar-native",
  ]
end
EOF_CASK

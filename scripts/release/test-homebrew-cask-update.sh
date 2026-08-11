#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

tap_dir="${tmp_dir}/homebrew-tap"
version="9.8.7"
tag="v${version}"
sha="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

mkdir -p "${tap_dir}/Casks"
git -C "${tap_dir}" init -q
touch "${tap_dir}/Casks/easybar.rb"
git -C "${tap_dir}" add Casks
git -C "${tap_dir}" -c user.name=test -c user.email=test@example.com \
  -c commit.gpgsign=false commit -qm fixture

"${repo_root}/scripts/release/update-homebrew-cask.sh" \
  --tap-dir "${tap_dir}" \
  --repository easybar-app/easybar-native \
  --tag "${tag}" \
  --version "${version}" \
  --sha "${sha}"

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    echo "Expected ${file} to contain: ${expected}" >&2
    cat "$file" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq "$unexpected" "$file"; then
    echo "Expected ${file} not to contain: ${unexpected}" >&2
    cat "$file" >&2
    exit 1
  fi
}

cask="${tap_dir}/Casks/easybar-native.rb"
test -s "$cask"
assert_contains "$cask" 'cask "easybar-native" do'
assert_contains "$cask" "url \"https://github.com/easybar-app/easybar-native/releases/download/${tag}/EasyBarNative-${version}.zip\""
assert_contains "$cask" "sha256 \"${sha}\""
assert_contains "$cask" "version \"${version}\""
assert_contains "$cask" 'depends_on formula: "lua"'
assert_contains "$cask" 'depends_on macos: :sonoma'
assert_contains "$cask" 'system "xattr", "-dr", "com.apple.quarantine", "#{appdir}/EasyBarNative.app"'
assert_contains "$cask" 'app "EasyBarNative.app"'
assert_contains "$cask" 'binary "#{appdir}/EasyBarNative.app/Contents/MacOS/easybar-native", target: "easybar-native"'
assert_contains "$cask" '"~/.config/easybar-native",'
assert_contains "$cask" '"~/.local/share/easybar-native",'
assert_contains "$cask" '"~/.local/state/easybar-native",'
assert_not_contains "$cask" 'easybar-calendar-agent'
assert_not_contains "$cask" 'easybar-network-agent'

test -e "${tap_dir}/Casks/easybar.rb"
ruby -c "$cask" >/dev/null

"${repo_root}/scripts/release/commit-homebrew-cask.sh" \
  --tap-dir "${tap_dir}" \
  --version "${version}" \
  --dry-run >/dev/null

if git -C "$tap_dir" diff --cached --quiet; then
  echo "Expected dry-run commit script to stage the native cask change." >&2
  exit 1
fi

# EasyBar Native

EasyBar Native is the native macOS menu-bar frontend for
[`easybar-kit`](../easybar-kit). It runs the same Lua widgets as EasyBar, but each top-level widget
is hosted as an independent `NSStatusItem` in the system menu bar instead of inside a custom bar
window.

## What is shared

The frontend reuses EasyBarKit's complete widget implementation:

- Lua widget loading and package activation
- timers, commands, JSON, storage, events, and lifecycle events
- hover, click, scroll, and context-menu interaction
- SwiftUI widget rendering
- custom popup panels
- native inbox and built-in widgets
- themes and widget state

A Lua widget does not need a second native-specific implementation. A top-level Lua root becomes one
status item; a row or group below that root remains inside the same item.

Calendar and network helper agents, the Lua runtime helper, and the `easybar` CLI are shared support
products supplied by EasyBarKit. They are not reimplemented in this repository.

## Native differences

macOS owns the status area, so EasyBar's `left`, `center`, and `right` positions are treated as
relative ordering hints only. EasyBar Native cannot place arbitrary status items on the left side of
the macOS menu bar or span a background across multiple status items.

The native frontend uses its own bootstrap paths by default:

```text
~/.config/easybar-native/config.toml
~/.local/state/easybar-native/runtime
```

The Lua widget directory remains the shared EasyBar default (`~/.config/easybar/widgets`) unless the
native config overrides `app.widgets_dir`. Calendar and network agent sockets remain shared with the
EasyBar support runtime.

## Build and test

Keep this repository next to `easybar-kit` for source-tree development:

```text
projects/
├── easybar-kit/
└── easybar-native/
```

Then:

```bash
make build
make test
make check
make run
```

`make check` also validates the Homebrew cask generator used by tagged releases.

## Install the current checkout

Install a complete local development build with:

```bash
make install-local
```

The local installation contains:

```text
~/Applications/EasyBarNative.app
~/.local/bin/easybar
~/Library/Application Support/EasyBar/Agents/EasyBarCalendarAgent.app
~/Library/Application Support/EasyBar/Agents/EasyBarNetworkAgent.app
~/Library/LaunchAgents/io.github.gi8lino.easybar.local.*.plist
```

The support paths and LaunchAgent labels are intentionally shared with EasyBar because those helper
agents expose the same sockets to both frontends.

The local build receives a Git-derived version containing both the EasyBar Native and EasyBarKit
commits, for example:

```text
0.53.2-dev.a1b2c3d4.kit.e5f6a7b8
```

If either checkout has staged, unstaged, or untracked changes, the version ends in `-dirty`.
Inspect it before installing with:

```bash
make print-local-version
```

Local bundles are ad-hoc signed and are not notarized. The installer recursively removes
`com.apple.quarantine` from `EasyBarNative.app` and both shared agent bundles, removes it from the
shared CLI, and verifies that the attribute is gone before starting the agents or launching the app.

Override the defaults when needed:

```bash
make install-local LOCAL_INSTALL_ARCH=universal
make install-local LOCAL_APP_DIR=/Applications
make install-local EASYBAR_KIT_ROOT=/path/to/easybar-kit
```

Remove the local Native app and the shared local support installation with:

```bash
make uninstall-local
```

## Release packaging

Build the same native release archive produced by GitHub Actions with:

```bash
make release ARCH=universal VERSION=0.54.0
```

The release artifact is:

```text
dist/EasyBarNative-0.54.0.zip
```

A pushed `v*` tag runs the release workflow on macOS, verifies the repository, builds and uploads the
archive to the GitHub release, and only then dispatches `update-homebrew-cask.yml`. The cask workflow
downloads the immutable release archive, calculates its SHA-256, updates
`Casks/easybar-native.rb` in `easybar-app/homebrew-tap`, and commits the change with
`HOMEBREW_TAP_TOKEN`.

The Native cask depends on the existing shared `easybar-calendar-agent`, `easybar-network-agent`, and
`lua` formulae. It does not rewrite those formulae on Native releases.

Because the published app is currently ad-hoc signed rather than notarized, the generated cask
removes `com.apple.quarantine` from the installed `EasyBarNative.app` before launching it. The shared
agent formulae handle quarantine removal for their own app bundles.

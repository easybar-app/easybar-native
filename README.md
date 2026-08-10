# EasyBar Native

EasyBar Native is the native macOS menu-bar frontend for
[`easybar-kit`](../easybar-kit). It runs EasyBar Lua widgets as independent `NSStatusItem`s in the
system menu bar instead of rendering them inside EasyBar's custom full-width bar.

Lua packages are the only public/custom widget extension model. EasyBar Native keeps the host-owned
Inbox surface because Lua packages such as `inbox-github`, `inbox-gitlab`, and `inbox-brew` publish
into it. Regular EasyBar built-ins are not registered as Native status items.

## Isolation from EasyBar

EasyBar Native intentionally owns its runtime and user data instead of sharing EasyBar's installation
state:

```text
config:       ~/.config/easybar-native/config.toml
widgets:      ~/.config/easybar-native/widgets
runtime:      ~/.local/state/easybar-native/runtime
logs:         ~/.local/state/easybar-native/easybar-native.out
packages:     ~/.local/share/easybar-native/packages
editor stub:  ~/.local/share/easybar-native/easybar_api.lua
CLI:          easybar-native
```

The Native app does not install, start, stop, or depend on EasyBar's calendar or network helper
agents. It also does not install or modify the `easybar` CLI or EasyBar's managed package store.

The bundled `easybar-native` command uses the same tested package-management and IPC implementation
from EasyBarKit, but runs it with Native's isolated config, runtime, log, widget, and package paths.
Helper-agent commands are not exposed through the Native CLI.

Examples:

```bash
easybar-native widgets search
easybar-native widgets install tailscale
easybar-native widgets installed
easybar-native config reload
easybar-native logs
```

## What is shared

The frontend still reuses EasyBarKit's implementation for:

- Lua widget loading and package activation
- timers, commands, JSON, storage, events, and lifecycle events
- hover, click, scroll, and context-menu interaction
- SwiftUI widget rendering
- custom popup panels
- the host-owned Inbox aggregation surface
- themes and widget state
- the shared CLI implementation embedded behind `easybar-native`

Sharing implementation does not imply sharing user data or background services.

## Native differences

macOS owns the status area, so EasyBar's `left`, `center`, and `right` positions are treated as
relative ordering hints only. EasyBar Native cannot place arbitrary status items on the left side of
the macOS menu bar or span a background across multiple status items.

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

Install a local development build with:

```bash
make install-local
```

The installation contains:

```text
~/Applications/EasyBarNative.app
~/.local/bin/easybar-native -> ~/Applications/EasyBarNative.app/Contents/MacOS/easybar-native
```

No EasyBar helper agents or shared CLI binaries are installed.

The local build receives a Git-derived version containing both the EasyBar Native and EasyBarKit
commits, for example:

```text
0.2.0-dev.a1b2c3d4.kit.e5f6a7b8
```

If either checkout has staged, unstaged, or untracked changes, the version ends in `-dirty`.
Inspect it before installing with:

```bash
make print-local-version
```

Local bundles are ad-hoc signed and are not notarized. The installer recursively removes
`com.apple.quarantine` from `EasyBarNative.app` before launching it.

Override the defaults when needed:

```bash
make install-local LOCAL_INSTALL_ARCH=universal
make install-local LOCAL_APP_DIR=/Applications
make install-local EASYBAR_KIT_ROOT=/path/to/easybar-kit
```

Remove the local app and CLI link with:

```bash
make uninstall-local
```

Native config, logs, and package data are preserved by `uninstall-local`.

## Release packaging

Build the same native release archive produced by GitHub Actions with:

```bash
make release ARCH=universal VERSION=0.2.1
```

The release artifact is:

```text
dist/EasyBarNative-0.2.1.zip
```

The ZIP contains `EasyBarNative.app`, including the Lua runtime helper, the private EasyBarKit CLI
core, and the public `easybar-native` launcher.

A pushed `v*` tag runs the release workflow on macOS, verifies the repository, builds and uploads the
archive to the GitHub release, and then dispatches `update-homebrew-cask.yml`. The generated cask
depends only on Lua, installs the app, and exposes the embedded `easybar-native` launcher as a binary.

Because the published app is currently ad-hoc signed rather than notarized, the generated cask
removes `com.apple.quarantine` from the installed app before it is used.

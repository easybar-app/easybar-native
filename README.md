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
native config overrides `app.widgets_dir`. This lets the same local widgets run in both frontends.

Calendar and network helper agents are shared infrastructure provided by EasyBarKit. EasyBar Native
connects to those shared agent sockets while keeping its own app socket, Lua socket, lock, and inbox
runtime state under `~/.local/state/easybar-native/runtime`.

## Build and run

Keep this repository next to `easybar-kit`:

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

`make run` also builds EasyBarKit's `EasyBarLuaRuntime` helper and exposes it to the source-tree
runtime discovery path.

Install a release build and the shared CLI, runtime, and helper agents into `~/.local/bin` with:

```bash
make install-local
```

Override the destination with `LOCAL_BIN_DIR=/path/to/bin`.

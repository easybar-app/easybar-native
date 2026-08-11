# EasyBar Native

EasyBar Native is a lightweight, scriptable macOS menu-bar app for Lua widgets. It keeps the normal
macOS menu bar while giving every widget its own menu-bar item.

## Features

- Scriptable Lua widgets with events, popups, groups, and context menus
- Installable Lua widgets and libraries from the official package registry
- A built-in Inbox for notifications published by Lua widgets
- Independent configuration, packages, logs, and runtime state
- Shared EasyBar themes and Lua widget APIs
- A dedicated `easybar-native` CLI for control and diagnostics
- No dependency on EasyBar's calendar or network helper agents

EasyBar Native intentionally provides Lua widgets and the built-in Inbox only. Use
[EasyBar](https://easybar.dev/products/easybar/) when you want the full-width bar and its native
Spaces, battery, Wi-Fi, calendar, volume, CPU, and other built-ins.

## Requirements

- macOS 14 Sonoma or newer
- [Homebrew](https://brew.sh/) for installation

## Installation

```bash
brew tap easybar-app/tap
brew install --cask easybar-app/tap/easybar-native
open -a "EasyBar Native"
```

See the [installation guide](https://easybar.dev/products/easybar-native/installation/) for upgrades,
verification, and removal.

## Documentation

- [Quick start](https://easybar.dev/products/easybar-native/quick-start/)
- [Configuration](https://easybar.dev/products/easybar-native/configuration/)
- [Lua widgets and packages](https://easybar.dev/products/easybar-native/widgets/)
- [`easybar-native` CLI](https://easybar.dev/cli/easybar-native/)
- [Troubleshooting](https://easybar.dev/products/easybar-native/troubleshooting/)
- [Compare EasyBar products](https://easybar.dev/products/)

## License

Licensed under the [Apache License 2.0](./LICENSE).

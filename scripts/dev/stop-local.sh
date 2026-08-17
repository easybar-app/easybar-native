#!/usr/bin/env bash
# Stop the locally installed application.
set -euo pipefail

pkill -x EasyBarNative >/dev/null 2>&1 || true

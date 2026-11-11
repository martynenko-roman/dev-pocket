#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
app=${APP_BINARY:-$repo/dist/DevPocket.app/Contents/MacOS/DevPocket}
"$app" --selftest

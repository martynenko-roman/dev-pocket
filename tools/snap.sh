#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
app=${APP_BINARY:-$repo/dist/DevPocket.app/Contents/MacOS/DevPocket}
shots=${APP_SHOTS:-/private/tmp/DevPocket-shots}
mkdir -p "$shots"
APP_SNAPSHOT="$shots" "$app"

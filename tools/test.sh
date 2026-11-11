#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-/private/tmp/DevPocket-clang-cache}
export SWIFTPM_MODULECACHE_OVERRIDE=${SWIFTPM_MODULECACHE_OVERRIDE:-/private/tmp/DevPocket-module-cache}
swift test --package-path "$repo" --scratch-path /private/tmp/DevPocket-build \
  --disable-sandbox --manifest-cache none --cache-path /private/tmp/DevPocket-cache \
  --config-path /private/tmp/DevPocket-config --security-path /private/tmp/DevPocket-security

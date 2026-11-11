#!/bin/zsh
# Local build; set APP_INSTALL_ROOT=$HOME/Applications to install there.
set -euo pipefail
here=${0:A:h}
name=DevPocket
scratch=${APP_BUILD_ROOT:-/private/tmp/DevPocket-build}
config=release
[[ " $* " == *" --debug "* ]] && config=debug
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-/private/tmp/DevPocket-clang-cache}
export SWIFTPM_MODULECACHE_OVERRIDE=${SWIFTPM_MODULECACHE_OVERRIDE:-/private/tmp/DevPocket-module-cache}
swift build --jobs 2 -c "$config" --package-path "$here" --scratch-path "$scratch" \
  --disable-sandbox --manifest-cache none --cache-path /private/tmp/DevPocket-cache \
  --config-path /private/tmp/DevPocket-config --security-path /private/tmp/DevPocket-security
car="$here/Resources/Assets.car"
icns="$here/Resources/AppIcon.icns"
if [[ ! -f "$car" || ! -f "$icns" || -n "$(find "$here/Icon/AppIcon.icon" -newer "$car" | head -1)" ]]; then
  "$here/tools/make_icon.sh"
fi
app="${APP_INSTALL_ROOT:-$here/dist}/$name.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$scratch/$config/$name" "$app/Contents/MacOS/$name"
sed "s/__BUILD__/$(date +%Y%m%d%H%M)/" "$here/Info.plist.in" > "$app/Contents/Info.plist"
cp -X "$here/Resources/Assets.car" "$here/Resources/AppIcon.icns" "$app/Contents/Resources/"
identity=${SIGN_IDENTITY:--}
codesign --force --sign "$identity" --entitlements "$here/DevPocket.entitlements" "$app"
codesign --verify --strict "$app"
echo "Built $app"
if [[ " $* " == *" --open "* ]]; then
  open "$app"
fi

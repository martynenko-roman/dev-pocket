#!/bin/zsh
# Isolated, disposable app identities for testing through Launch Services.
set -euo pipefail
repo=${0:A:h:h}
python3 - "$repo" <<'PY'
from pathlib import Path
import plistlib, shutil, sys
root=Path(sys.argv[1])
binary=Path('/private/tmp/DevPocket-build/debug/DevPocket')
base=plistlib.loads((root/'Info.plist.in').read_bytes().replace(b'__BUILD__',b'1'))
for mode in ['selftest','snapshots','review','helper']:
    bundle=root/'dist'/f'DevPocket-{mode}.app'
    (bundle/'Contents/MacOS').mkdir(parents=True,exist_ok=True)
    shutil.copy2(binary,bundle/'Contents/MacOS/DevPocket')
    info=dict(base)
    info['CFBundleIdentifier']=f'com.romanmartynenko.devpocket.qa.{mode}'
    info['CFBundleName']=f'DevPocket-{mode}'
    info['CFBundleDisplayName']=f'DevPocket-{mode}'
    info.pop('CFBundleIconName',None)
    info.pop('CFBundleIconFile',None)
    environments={
        'selftest': {'APP_SELFTEST':'1','APP_TEST_LOG':'/private/tmp/DevPocket-native-selftest.log'},
        'snapshots': {'APP_SNAPSHOT':'/private/tmp/DevPocket-shots'},
        'review': {'APP_SNAPSHOT':'/private/tmp/DevPocket-shots','APP_REVIEW':'1'},
        'helper': {'APP_HELPER':'1'},
    }
    info['LSEnvironment']=environments[mode]
    (bundle/'Contents/Info.plist').write_bytes(plistlib.dumps(info))
PY
for mode in selftest snapshots review helper; do
  codesign --force --sign - --entitlements "$repo/DevPocket.entitlements" "$repo/dist/DevPocket-$mode.app"
done

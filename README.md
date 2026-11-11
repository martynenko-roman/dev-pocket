# DevPocket

A native macOS 26+ menu bar utility based on the BAMA Toolbox specification.
Keep the Mac awake, flip everyday system settings, select sound devices, and
reverse physical mouse wheels without changing trackpad gestures.

## Status

The implementation compiles. Three unit tests and 31 native API self-test
checks pass; native light/dark views have been reviewed. Final icon packaging
and manual permission/hardware acceptance checks remain pending. See
[build status](docs/BUILD-STATUS.md) for exact evidence and current limitations.

## Build

With full Xcode selected and its setup complete:

```sh
./build.sh
```

Output: `dist/DevPocket.app`. The default scratch directory is under
`/private/tmp`. Set `APP_INSTALL_ROOT` to change the app destination.
Quit any older running copy before opening a new build.

The icon compiler currently fails in the restricted runner despite the
source document opening in Icon Composer. The status document records an
ordinary-Terminal comparison to finish that diagnosis.

## Verify

```sh
tools/test.sh
tools/make-qa.sh
```

Launch `dist/DevPocket-selftest.app` from Finder for real API checks. It writes
`/private/tmp/DevPocket-native-selftest.log` and uses a disposable helper app.
`DevPocket-review.app` shows the real views with isolated preferences and
system-setting/audio fixtures. Keep Awake there still uses a real assertion.
`tools/snap.sh` exports window-only screenshots when capture access permits it.

Bundle identifier: `com.romanmartynenko.devpocket`.
[Brief](docs/BRIEF.md) · [Stories](docs/STORIES.md) · [Specification](docs/SPEC.md)

Source: https://github.com/daveebbelaar/bama/blob/main/specs/toolbox.md

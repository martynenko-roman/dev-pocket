# DevPocket

Native macOS 26+ menu bar utility. `docs/SPEC.md` is the unchanged upstream
Toolbox spec; the user renamed the app DevPocket. `docs/STORIES.md` tracks
acceptance evidence. Preserve that scope, including the dropped URL scheme,
App Intents, debug bridge, and icon picker.

## Code

- `DevPocketKit`: pure clock, duration, preference, and gesture rules.
- App services own power assertions, system preferences, CoreAudio, Carbon
  shortcuts, and the scroll event tap. `AppModel` assembles them.
- Settings persist in UserDefaults. Power sessions live in memory. No database.
- `MenuBarPanel` and `SettingsView` use the same services. `Toast` owns the
  nonactivating, mouse-ignoring overlay.
- Build uses Swift 6 with main-actor default isolation. C callbacks are
  nonisolated and cross onto main only where the delivery queue is known.

## Verification

`./build.sh --debug` builds, compiles the icon, signs, and packages into
`dist/DevPocket.app`. The default scratch directory is `/private/tmp`;
`APP_BUILD_ROOT` and `APP_INSTALL_ROOT` override destinations.

`tools/test.sh` runs Swift Testing. `tools/selftest.sh` runs the real API
checks; launch through the desktop if the shell aborts in `_RegisterApplication`.
`tools/make-qa.sh` creates isolated selftest, helper, snapshots, and review
app identities under dist. Launch those with Finder. The native self-test
writes `/private/tmp/DevPocket-native-selftest.log`; the helper is disposable
and is the only app a self-test may terminate.

`tools/snap.sh` requests window-only PNGs. Screen Recording may be required.
`DevPocket-review.app` exposes the actual views for native visual inspection;
its preferences are isolated, system toggles/audio use fixtures, and its
Keep Awake button still holds a real assertion. Review captures prove layout,
not successful changes to Finder, Dock, sound hardware, or permission grants.

After UI changes, check both appearances, run `tools/grid-lint.sh`, and run
`swift tools/check-layout.swift /private/tmp/DevPocket-shots/*-layout.json`.
Only mark stories done when every acceptance line has evidence. Keep manual
permission and hardware checks pending when they have not run.

## Design

Design rules: `design/DESIGN-SYSTEM.md`. Use its tokens and the system accent.
Forms own their layout; custom panel groups use grid probes. Icon source is
`Icon/AppIcon.icon`, with original SVG layers and no SF Symbols.

## System integration

Keep Awake prevents idle display sleep, not lid-close sleep. Every start
releases the previous assertion. Finder/Dock restarts and AppleScript run
away from the main thread. Refresh preferences before reads; busy controls
ignore duplicate clicks. CoreAudio listeners deliver on main. Read every
scroll representation before negating any field; continuous gestures pass
through. Request permissions only at use; preserve exact recovery wording.

Commit working changes with their verification evidence. Keep build outputs
and QA copies out of Git.

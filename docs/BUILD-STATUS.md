# DevPocket build verification

Updated 2026-11-11. The application is implemented and its debug source build
passes. A release executable also compiled successfully. Final icon packaging and some manual acceptance checks remain open.

## Resolved setup issues

- Xcode is selected at `/Applications/Xcode.app/Contents/Developer`.
- Xcode 27.2, build 27B52; Apple Swift 6.4.2.
- `actool` and Icon Composer are installed. The user accepted Icon Composer's
  license; its normal Open dialog and the project document were observed.
- The earlier mixed Command Line Tools interfaces no longer block SwiftPM.
- A transient disk-full failure cleared; subsequent source builds passed.

## Implemented

Menu bar panel, Keep Awake durations and app watch, optimistic system toggles,
CoreAudio input/output selection and listeners, General and Shortcuts settings,
Carbon shortcut recording/conflicts, physical-wheel reversal and Accessibility
retry, login item integration, and the nonactivating toast. Local settings use
UserDefaults; Keep Awake sessions stay in memory.

## Passed checks

- Debug source build: clean Swift 6 compile with no compiler warnings.
- Release source build: compiled and linked with SwiftPM native backend and
  debug information disabled. The backend prints a deprecation warning. The
  default backend failed in dSYM generation with Operation not permitted.
- Swift Testing: three tests pass, including seven parameterized clock cases.
- Native API self-test: **31/31** checks pass when the isolated QA app is
  launched through Finder. Log: `/private/tmp/DevPocket-native-selftest.log`.
- Power checks: exactly one named assertion after start/restart, none after
  stop/expiry, duration changes restart the countdown, stale timeline dates
  cannot display more than the configured duration.
- App watch: a disposable helper app is selected, terminated normally, and
  its termination releases the assertion with feedback naming the app.
- Audio observers run without a Swift concurrency trap; default output is
  consistent with the live device list when available.
- All six physical-wheel delta fields reverse; gesture fields pass through.
- Carbon registration, duplicate rejection, and clearing pass.
- Info.plist contains LSUIElement and the Automation usage description.
- The login toggle matches the actual SMAppService status.
- `tools/grid-lint.sh` and `git diff --check` pass.

## Native visual review

The actual SwiftUI views were opened in an isolated review app and inspected
through computer use in light and dark appearances: panel, sound menu,
General settings including its lower sections, Shortcuts, and toast. Active
window captures confirmed the settings switch accent and shortcut warning.
The recorder captured a test chord, rejected a duplicate with an orange
warning, and recovered after the original binding was cleared. Test bindings
were removed afterwards.

The countdown's first-frame mismatch was fixed and rechecked: the button and
status both start at 15:00. The regression is also in the self-test.

Review fixtures do not change Finder/Dock preferences or sound routing.
Their Keep Awake controls still exercise real power assertions. Review-window
layout inspection does not prove the final menu bar anchoring or Settings
window presentation. Global activation from another application remains a
manual check; targeted test keystrokes are not proof of a hardware hotkey.

Automatic window PNG export produced layout JSON but no PNG files in this
session. The native screen images were reviewed through computer use; no
flattened view-hierarchy image is being represented as full visual QA.

## Remaining icon packaging blocker

The original `Icon/AppIcon.icon` document opens and renders both SVG layers
in Icon Composer. Command-line `ictool` still reports:

```text
The file “AppIcon.icon” couldn’t be opened.
```

`actool` reports `Icon export exited with status 255` and cannot produce
`Resources/Assets.car` or `Resources/AppIcon.icns`. This persisted after license
acceptance and when using a temporary copy of the document. The runner also
reports unavailable CoreSimulator/XPC services. These observations suggest a
runner-specific problem, but an ordinary-Terminal comparison is still needed.

Requested comparison:

```sh
cd /Users/romanmartynenko/Desktop/Roman/repos/lido/DevPocket
tools/make_icon.sh
```

If that produces both files, `build.sh` reuses them while the icon sources are
unchanged, finishes packaging/signing, and writes `dist/DevPocket.app`. Use
`./build.sh --debug` to avoid the runner's release dSYM-generation failure.
The existing primary app bundle predates the final changes and should not be
used as the acceptance build until packaging succeeds. QA copies contain the
new code, but intentionally have separate identities and are not the final app.

## Remaining acceptance checks

- Finder hidden files and desktop icons: actual changes, restart, rollback,
  and refresh after changes made elsewhere.
- Dock auto-hide: actual change and refresh.
- Dark mode: Allow and Don't Allow paths, rollback/recovery text, and sync
  after a change in System Settings.
- Audio: switching actual routes, system output following the primary output,
  and hot-plugging headphones.
- Shortcut: activation while another application is frontmost, with toast.
- Scroll: Accessibility grant/retry and physical wheel versus trackpad/Magic
  Mouse on real hardware.
- Toast: actual screen placement and 1.5-second lifetime outside preview mode.
- Final menu bar and Settings window presentation after packaging.

Keep incomplete stories open until the named checks pass. No system developer
tool files or unrelated user data were modified by these diagnostics.

## Saved evidence

The passing native test output and release compile output are copied into
`docs/verification/`. Read those alongside the manual-check limits above.

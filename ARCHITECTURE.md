# Architecture

`DevPocketKit` contains pure, Sendable rules. The executable depends on it;
the library does not depend on AppKit or SwiftUI.

`KeepAwake`, `QuickToggles`, `AudioDevices`, `ScrollReverser`, and
`ShortcutCenter` each own one system integration. `AppModel` composes them
and exposes login-item state. `SystemToggles` performs the preference and
AppleScript operations. Views call the services directly; no duplicate
command or state layer exists.

UI and observable state run on main. Finder/Dock processes run in detached
tasks; AppleScript runs on one serial background queue. CoreAudio requests
main-queue delivery; event taps use the main run loop. Carbon handlers and
local-key monitors cross into main without transferring NSEvent objects.

Power sessions are memory only; preferences use UserDefaults. Snapshot
fixtures avoid modifying system preferences or audio routes. Native API
self-tests use isolated preferences and a disposable helper app.

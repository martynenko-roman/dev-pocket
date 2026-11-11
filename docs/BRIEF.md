# DevPocket

A menu bar panel of one-click toggles for the Mac settings you change every day.

## Replaces
Amphetamine, Caffeine, TinkerTool, Mos

## Main jobs
1. Keep the Mac awake until I turn it off, for a set time, or while one app runs.
2. Flip hidden files, desktop icons, dark mode, and Dock auto-hide with one click.
3. Switch the sound output and input device.

## Data
- Settings: Keep Awake duration (default "Until turned off"), reverse mouse scroll
  (default off), shortcuts. UserDefaults.
- Keep Awake session: on, end date, app pid and name. Memory only.

## Shape
Menu bar extra in window style, plus a Settings window. macOS 26 or later.
No Dock icon (LSUIElement). Local data. Works offline. No accounts.

## System hooks
Menu bar item, global shortcuts for four toggles (no defaults), Automation of System
Events for dark mode, Accessibility for the scroll reverser, launch at login.

## Reference
Amphetamine for Keep Awake, Control Center for the look.

## Look
Native, system accent color. A row of round toggle buttons, each a symbol with a
one-word label under it, like Control Center. A short glass toast confirms each change.

## Not in version one
- Keep Awake schedules and battery rules
- More hidden settings (screenshot format, key repeat)
- Per-app sound output

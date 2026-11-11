## M1 Core loop

### S-001 Turn Keep Awake on and off
As the user, I click the cup button in the menu bar panel and the Mac stops going to sleep.
Screens: menu.png
Acceptance:
- [snap] The cup button shows its on state and the label "Awake".
- [self] `pmset -g assertions` lists a PreventUserIdleDisplaySleep assertion named "DevPocket Keep Awake"; it is gone after the second click.
- [manual] A toast "Keep Awake on" shows for 1.5 s at the top of the screen.
Status: todo

### S-002 Keep the Mac awake for a set time
As the user, I right-click the cup button and pick 15 minutes, 1 hour, or 2 hours.
Depends: S-001
Acceptance:
- [unit] `clock(3599)` is "59:59" and `clock(7199.2)` is "2:00:00".
- [snap] The button label counts down, for example "14:59".
- [self] Starting a new session releases the old assertion first: only one assertion exists.
Status: todo

### S-003 Show or hide hidden files
As the user, I click the eye button and Finder shows dot files.
Screens: menu.png
Acceptance:
- [unit] A stored string "YES" reads as on; a missing value reads as off.
- [manual] Finder restarts and shows hidden files; the button shows a spinner until it is done.
Status: todo

### S-004 Hide desktop icons and the Dock
As the user, I click the desktop button for a clean desktop before I share my screen, and the Dock button to hide the Dock.
Acceptance:
- [unit] A missing `CreateDesktop` value reads as on.
- [manual] Desktop icons disappear after Finder restarts, and come back with a second click.
- [manual] The Dock button turns on auto-hide the same way, through a Dock restart.
Status: todo

### S-005 Switch dark mode and grant Automation
As the user, I click the moon button; the first time, macOS asks if DevPocket may control System Events.
Acceptance:
- [manual] After Allow, the Mac switches to dark mode and the button stays in sync when I change it in System Settings.
- [manual] After Don't Allow, the button flips back and a toast says "Allow DevPocket to control System Events in Privacy & Security > Automation".
- [self] Info.plist has `NSAppleEventsUsageDescription`.
Status: todo

### S-006 Switch the sound output and input
As the user, I open the sound menu in the panel header and pick a device.
Screens: menu-sound.png
Acceptance:
- [snap] The header shows the current output name; the menu lists outputs and inputs with a check on the current ones.
- [manual] Plugging in headphones adds them to the list without reopening the panel.
Status: todo

## M2 Settings and extras

### S-007 Keep the Mac awake while an app runs
As the user, I pick an app in Settings and Keep Awake stays on until that app quits.
Screens: settings.png
Acceptance:
- [manual] Quitting the app turns Keep Awake off with a toast naming the app.
- [snap] The status line reads "On while Xcode runs".
Status: todo

### S-008 Settings page
As the user, I open Settings and see Keep Awake, the four toggles with a detail line each, Sound, and Shortcuts.
Screens: settings.png
Acceptance:
- [snap] Each toggle row has a symbol, a title, one line of detail, and a switch.
- [snap] The Keep Awake footer says "Closing the lid still sleeps the Mac."
Status: todo

### S-009 Give a toggle a shortcut
As the user, I record a shortcut for Keep Awake, hidden files, desktop icons, or dark mode.
Depends: S-008
Acceptance:
- [manual] The shortcut flips the setting and shows the toast.
- [snap] A shortcut another app owns shows an orange warning next to the field.
Status: todo

### S-010 Reverse the mouse wheel and grant Accessibility
As the user, I turn on "Reverse mouse scroll direction" and the wheel flips while the trackpad stays the same.
Acceptance:
- [manual] Without Accessibility, the row shows "Needs Accessibility" with a button to the right System Settings pane, and the tap installs within 2 s of the grant.
- [manual] The wheel scrolls the other way; trackpad and Magic Mouse do not change.
- [snap] The footer says "Quit Mos or other scroll apps first, or the direction flips twice."
Status: todo

### S-011 Launch at login
As the user, I turn on "Open at login" in Settings.
Acceptance:
- [self] The toggle reflects `SMAppService.mainApp.status`.
Status: todo

## Dropped
- Debug bridge commands, URL scheme, and App Intents for each toggle
- App icon picker and Dock icon option

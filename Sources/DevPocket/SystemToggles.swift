import AppKit
import DevPocketKit
import Observation

enum SystemToggle: String, CaseIterable, Identifiable {
    case hiddenFiles, desktopIcons, darkMode, dockAutoHide
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hiddenFiles: "Show hidden files"
        case .desktopIcons: "Show desktop icons"
        case .darkMode: "Dark mode"
        case .dockAutoHide: "Hide the Dock automatically"
        }
    }
    var label: String {
        switch self {
        case .hiddenFiles: "Hidden"
        case .desktopIcons: "Desktop"
        case .darkMode: "Dark"
        case .dockAutoHide: "Dock"
        }
    }
    var detail: String {
        switch self {
        case .hiddenFiles: "Show dot files and other hidden items in Finder."
        case .desktopIcons: "Show files and folders on your desktop."
        case .darkMode: "Use a dark appearance across your Mac."
        case .dockAutoHide: "Show the Dock when the pointer reaches its edge."
        }
    }
    var symbol: String {
        switch self {
        case .hiddenFiles: "eye"
        case .desktopIcons: "desktopcomputer"
        case .darkMode: "moon.fill"
        case .dockAutoHide: "dock.rectangle"
        }
    }
    var preference: (key: String, domain: String, fallback: Bool) {
        switch self {
        case .hiddenFiles: ("AppleShowAllFiles", "com.apple.finder", false)
        case .desktopIcons: ("CreateDesktop", "com.apple.finder", true)
        case .dockAutoHide: ("autohide", "com.apple.dock", false)
        case .darkMode: ("AppleInterfaceStyle", "", false)
        }
    }
    func toast(on: Bool) -> String {
        switch self {
        case .hiddenFiles: on ? "Hidden files shown" : "Hidden files hidden"
        case .desktopIcons: on ? "Desktop icons shown" : "Desktop icons hidden"
        case .darkMode: on ? "Dark mode on" : "Dark mode off"
        case .dockAutoHide: on ? "Dock auto-hide on" : "Dock auto-hide off"
        }
    }
}

struct SystemChangeError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum SystemToggles {
    static func read(_ toggle: SystemToggle) -> Bool {
        if toggle == .darkMode {
            CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
            return (CFPreferencesCopyAppValue("AppleInterfaceStyle" as CFString,
                                             kCFPreferencesAnyApplication) as? String) == "Dark"
        }
        let pref = toggle.preference
        CFPreferencesAppSynchronize(pref.domain as CFString)
        return Rules.preferenceBool(CFPreferencesCopyAppValue(pref.key as CFString, pref.domain as CFString),
                                    fallback: pref.fallback)
    }

    static func set(_ toggle: SystemToggle, on: Bool) async throws {
        if toggle == .darkMode {
            try await setDarkMode(on)
            return
        }
        let pref = toggle.preference
        let old = CFPreferencesCopyAppValue(pref.key as CFString, pref.domain as CFString)
        CFPreferencesSetAppValue(pref.key as CFString, on as CFBoolean, pref.domain as CFString)
        guard CFPreferencesAppSynchronize(pref.domain as CFString) else {
            CFPreferencesSetAppValue(pref.key as CFString, old, pref.domain as CFString)
            throw SystemChangeError(message: "Unable to save \(toggle.title.lowercased()).")
        }
        let processName = toggle == .dockAutoHide ? "Dock" : "Finder"
        do {
            try await Task.detached {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
                process.arguments = [processName]
                process.standardError = FileHandle.nullDevice
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    throw SystemChangeError(message: "Unable to restart \(processName). Try again.")
                }
            }.value
        } catch {
            CFPreferencesSetAppValue(pref.key as CFString, old, pref.domain as CFString)
            CFPreferencesAppSynchronize(pref.domain as CFString)
            throw error
        }
    }

    private static let scriptQueue = DispatchQueue(label: "com.romanmartynenko.devpocket.appearance")

    private static func setDarkMode(_ on: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            scriptQueue.async { @Sendable in
                let source = "tell application \"System Events\" to tell appearance preferences to set dark mode to \(on ? "true" : "false")"
                var error: NSDictionary?
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: SystemChangeError(message: "Unable to create appearance script."))
                    return
                }
                script.executeAndReturnError(&error)
                if let error {
                    let denied = (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue == -1743
                    continuation.resume(throwing: SystemChangeError(message: denied
                        ? "Allow DevPocket to control System Events in Privacy & Security > Automation"
                        : "Unable to change dark mode. \(error[NSAppleScript.errorMessage] as? String ?? "Try again.")"))
                } else { continuation.resume() }
            }
        }
    }
}

@Observable
final class QuickToggles {
    private(set) var values: [SystemToggle: Bool] = [:]
    private(set) var busy: Set<SystemToggle> = []
    private(set) var errors: [SystemToggle: String] = [:]
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    private let preview: Bool

    init(preview: Bool = false) {
        self.preview = preview
        refresh()
        if preview { return }
        observers.append(DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.refresh() } })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.refresh() } })
    }

    func refresh() {
        for toggle in SystemToggle.allCases where !busy.contains(toggle) {
            values[toggle] = preview ? toggle == .desktopIcons : SystemToggles.read(toggle)
        }
    }

    func toggle(_ item: SystemToggle) { set(item, on: !(values[item] ?? false)) }

    func set(_ item: SystemToggle, on: Bool) {
        guard !busy.contains(item), !preview else { return }
        let old = values[item] ?? false
        guard on != old else { return }
        values[item] = on
        busy.insert(item)
        errors[item] = nil
        Task {
            do {
                try await SystemToggles.set(item, on: on)
                Toast.shared.show(item.toast(on: on))
            } catch {
                values[item] = old
                errors[item] = error.localizedDescription
                Toast.shared.show(error.localizedDescription)
            }
            busy.remove(item)
        }
    }
}

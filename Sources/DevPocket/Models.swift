import AppKit
import Observation
import ServiceManagement

@Observable
final class AppModel {
    static let shared = AppModel()
    let awake: KeepAwake
    let toggles: QuickToggles
    let audio: AudioDevices
    let scroll: ScrollReverser
    let shortcuts: ShortcutCenter
    private(set) var loginEnabled = false
    private(set) var loginNeedsApproval = false
    var loginError: String?
    private let preview: Bool

    init(preview: Bool = AppMode.isSnapshot) {
        self.preview = preview
        let defaults = AppMode.isTesting ? UserDefaults(suiteName: "com.romanmartynenko.devpocket.preview")! : .standard
        awake = KeepAwake(defaults: defaults)
        toggles = QuickToggles(preview: preview)
        audio = AudioDevices(preview: preview)
        scroll = ScrollReverser(defaults: defaults, preview: AppMode.isTesting)
        shortcuts = ShortcutCenter(defaults: defaults, enabled: !AppMode.isTesting || AppMode.isReview)
        shortcuts.perform = { [weak self] action in
            guard let self else { return }
            switch action {
            case .awake: self.awake.toggle()
            case .hidden: self.toggles.toggle(.hiddenFiles)
            case .desktop: self.toggles.toggle(.desktopIcons)
            case .dark: self.toggles.toggle(.darkMode)
            }
        }
        refresh()
    }

    var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    func refresh() {
        toggles.refresh()
        audio.refresh()
        guard !preview else { return }
        loginEnabled = SMAppService.mainApp.status == .enabled
        loginNeedsApproval = SMAppService.mainApp.status == .requiresApproval
        scroll.refresh()
    }

    func setLogin(_ enabled: Bool) {
        guard !preview else { return }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch { loginError = "Unable to change Open at login: \(error.localizedDescription)" }
        refresh()
    }

    func shutdown() {
        awake.stop(announce: false)
        audio.shutdown()
        scroll.shutdown()
        shortcuts.shutdown()
    }
}

import AppKit
import Carbon.HIToolbox
import Observation

enum ShortcutAction: UInt32, CaseIterable, Identifiable, Codable {
    case awake = 1, hidden, desktop, dark
    var id: UInt32 { rawValue }
    var title: String {
        switch self {
        case .awake: "Keep Awake"
        case .hidden: "Show hidden files"
        case .desktop: "Show desktop icons"
        case .dark: "Dark mode"
        }
    }
}

struct KeyCombination: Codable, Equatable {
    var key: UInt32
    var modifiers: UInt32
    var display: String
}

@Observable
final class ShortcutCenter {
    private(set) var bindings: [ShortcutAction: KeyCombination] = [:]
    private(set) var errors: [ShortcutAction: String] = [:]
    var recording: ShortcutAction?
    var perform: (ShortcutAction) -> Void = { _ in }
    @ObservationIgnored private var refs: [ShortcutAction: EventHotKeyRef] = [:]
    @ObservationIgnored private var handler: EventHandlerRef?
    @ObservationIgnored private var monitor: Any?
    private let defaults: UserDefaults
    private let enabled: Bool

    init(defaults: UserDefaults = .standard, enabled: Bool = true) {
        self.defaults = defaults
        self.enabled = enabled
        guard enabled else { return }
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { handler, event, context in
            ShortcutCenter.handle(handler, event, context)
        }, 1, &type,
                            Unmanaged.passUnretained(self).toOpaque(), &handler)
        for action in ShortcutAction.allCases {
            if let data = defaults.data(forKey: "shortcut.\(action.rawValue)"),
               let combo = try? JSONDecoder().decode(KeyCombination.self, from: data) {
                save(combo, for: action)
            }
        }
    }

    nonisolated private static func handle(_ handler: EventHandlerCallRef?, _ event: EventRef?,
                                           _ context: UnsafeMutableRawPointer?) -> OSStatus {
        var id = EventHotKeyID()
        guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                nil, MemoryLayout<EventHotKeyID>.size, nil, &id) == noErr,
              id.signature == 0x4456504B, let action = ShortcutAction(rawValue: id.id), let context else { return noErr }
        // Carbon's application event handler runs on the application's main event loop.
        let center = Unmanaged<ShortcutCenter>.fromOpaque(context).takeUnretainedValue()
        MainActor.assumeIsolated { center.perform(action) }
        return noErr
    }

    func save(_ combo: KeyCombination, for action: ShortcutAction) {
        guard enabled else { return }
        if bindings[action] == combo { stopRecording(); return }
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(combo.key, combo.modifiers,
                                         EventHotKeyID(signature: 0x4456504B, id: action.rawValue),
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else {
            errors[action] = "Shortcut unavailable. Another app may already use it."
            stopRecording()
            return
        }
        if let old = refs[action] { UnregisterEventHotKey(old) }
        refs[action] = ref
        bindings[action] = combo
        errors[action] = nil
        defaults.set(try? JSONEncoder().encode(combo), forKey: "shortcut.\(action.rawValue)")
        stopRecording()
    }

    func clear(_ action: ShortcutAction) {
        if let ref = refs.removeValue(forKey: action) { UnregisterEventHotKey(ref) }
        bindings[action] = nil
        errors[action] = nil
        defaults.removeObject(forKey: "shortcut.\(action.rawValue)")
        stopRecording()
    }

    func startRecording(_ action: ShortcutAction) {
        stopRecording()
        recording = action
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = event.keyCode
            let rawFlags = event.modifierFlags.rawValue
            let characters = event.charactersIgnoringModifiers ?? ""
            let consumed = MainActor.assumeIsolated {
                self?.recordKey(keyCode, rawFlags: rawFlags, characters: characters) ?? false
            }
            return consumed ? nil : event
        }
    }

    private func recordKey(_ keyCode: UInt16, rawFlags: UInt, characters: String) -> Bool {
        guard let action = recording else { return false }
        if keyCode == UInt16(kVK_Escape) { stopRecording(); return true }
        let flags = NSEvent.ModifierFlags(rawValue: rawFlags).intersection(.deviceIndependentFlagsMask)
        guard !flags.intersection([.command, .control, .option]).isEmpty else {
            errors[action] = "Include Command, Control, or Option."
            return true
        }
        var modifiers: UInt32 = 0
        var display = ""
        if flags.contains(.control) { modifiers |= UInt32(controlKey); display += "⌃" }
        if flags.contains(.option) { modifiers |= UInt32(optionKey); display += "⌥" }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey); display += "⇧" }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey); display += "⌘" }
        display += characters == " " ? "Space" : characters.uppercased()
        save(.init(key: UInt32(keyCode), modifiers: modifiers, display: display), for: action)
        return true
    }

    func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recording = nil
    }

    func shutdown() {
        stopRecording()
        for ref in refs.values { UnregisterEventHotKey(ref) }
        refs.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }
}

import AppKit
import DevPocketKit
import Observation

@Observable
final class ScrollReverser {
    var enabled: Bool {
        didSet {
            defaults.set(enabled, forKey: "mouse.reverse")
            refresh()
        }
    }
    private(set) var trusted = false
    private(set) var installed = false
    private let preview: Bool
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var tap: CFMachPort?
    @ObservationIgnored private var source: CFRunLoopSource?
    @ObservationIgnored private var retry: Timer?

    init(defaults: UserDefaults = .standard, preview: Bool = false) {
        self.defaults = defaults
        self.preview = preview
        enabled = preview ? false : defaults.bool(forKey: "mouse.reverse")
        refresh()
    }

    var status: String {
        if !enabled { return "Reverse physical mouse wheels; keep trackpad gestures unchanged." }
        if !trusted { return "Needs Accessibility" }
        return installed ? "Mouse wheel reversal is on." : "Unable to install scroll control. Retrying…"
    }

    func refresh() {
        guard !preview else { return }
        trusted = AXIsProcessTrusted()
        if !enabled || !trusted { removeTap() }
        if enabled, trusted, tap == nil { installTap() }
        if enabled, !installed, retry == nil {
            retry = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
            retry?.tolerance = 0.1
        } else if !enabled || installed {
            retry?.invalidate()
            retry = nil
        }
    }

    func openAccessibility() {
        guard !preview else { return }
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    private func installTap() {
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                         options: .defaultTap,
                                         eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
                                         callback: { proxy, type, event, context in
                                             ScrollReverser.callback(proxy, type, event, context)
                                         },
                                         userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        installed = true
    }

    nonisolated private static func callback(_ proxy: CGEventTapProxy, _ type: CGEventType,
                                             _ event: CGEvent, _ context: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // The event source is installed on the main run loop only.
            if let context {
                let reverser = Unmanaged<ScrollReverser>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated {
                    if let tap = reverser.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                }
            }
        } else if type == .scrollWheel {
            reverseWheel(event)
        }
        return Unmanaged.passUnretained(event)
    }

    nonisolated static func reverseWheel(_ event: CGEvent) {
        guard Rules.shouldReverseScroll(phase: event.getIntegerValueField(.scrollWheelEventScrollPhase),
                                        momentum: event.getIntegerValueField(.scrollWheelEventMomentumPhase),
                                        continuous: event.getIntegerValueField(.scrollWheelEventIsContinuous)) else { return }
        let fields: [CGEventField] = [.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2,
                                     .scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2,
                                     .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2]
        // Setting a field may change another representation: collect all values first.
        let values = fields.map { event.getIntegerValueField($0) }
        for (field, value) in zip(fields, values) {
            event.setIntegerValueField(field, value: value == Int64.min ? Int64.max : -value)
        }
    }

    private func removeTap() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
        installed = false
    }

    func shutdown() {
        retry?.invalidate()
        retry = nil
        removeTap()
    }
}

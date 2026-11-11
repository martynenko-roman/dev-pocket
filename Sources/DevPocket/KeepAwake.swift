import AppKit
import DevPocketKit
import IOKit.pwr_mgt
import Observation

@Observable
final class KeepAwake {
    private(set) var isOn = false
    private(set) var endDate: Date?
    private(set) var appName: String?
    private(set) var appPID: pid_t?
    private(set) var sessionLength: TimeInterval?
    var duration: AwakeDuration {
        didSet {
            defaults.set(duration.rawValue, forKey: "awake.duration")
            if isOn, appPID == nil { start() }
        }
    }
    @ObservationIgnored private var assertion: IOPMAssertionID = 0
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observer: NSObjectProtocol?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored var notify: (String) -> Void = { Toast.shared.show($0) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        duration = AwakeDuration(rawValue: defaults.string(forKey: "awake.duration") ?? "") ?? .indefinitely
    }

    var assertionID: IOPMAssertionID { assertion }

    func toggle() { isOn ? stop() : start() }

    func start(app: NSRunningApplication? = nil, secondsOverride: TimeInterval? = nil) {
        stop(announce: false)
        var newID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn), "DevPocket Keep Awake" as CFString, &newID)
        guard result == kIOReturnSuccess else {
            notify("Unable to keep the Mac awake (\(result)).")
            return
        }
        assertion = newID
        isOn = true
        if let app {
            appPID = app.processIdentifier
            appName = app.localizedName ?? "App"
            observer = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
            ) { [weak self] note in
                let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
                MainActor.assumeIsolated {
                    guard let self, pid == self.appPID else { return }
                    let name = self.appName ?? "App"
                    self.stop(announce: false)
                    self.notify("\(name) quit. Keep Awake is off")
                }
            }
            // Catch termination between selecting the app and installing its observer.
            if app.isTerminated {
                let name = appName ?? "App"
                stop(announce: false)
                notify("\(name) quit. Keep Awake is off")
                return
            }
        } else if let seconds = secondsOverride ?? duration.seconds {
            sessionLength = seconds
            endDate = Date().addingTimeInterval(seconds)
            timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.stop() }
            }
            timer?.tolerance = min(seconds / 20, 0.5)
        }
        notify("Keep Awake on")
    }

    func stop(announce: Bool = true) {
        let wasOn = isOn
        timer?.invalidate()
        timer = nil
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observer = nil
        if assertion != 0 { IOPMAssertionRelease(assertion) }
        assertion = 0
        isOn = false
        endDate = nil
        appPID = nil
        appName = nil
        sessionLength = nil
        if wasOn, announce { notify("Keep Awake off") }
    }

    func label(at now: Date) -> String {
        if let endDate, isOn {
            return Rules.clock(min(endDate.timeIntervalSince(now), sessionLength ?? .greatestFiniteMagnitude))
        }
        return "Awake"
    }

    func status(at now: Date) -> String {
        guard isOn else { return "Off. Your Mac sleeps as usual." }
        if let appName { return "On while \(appName) runs" }
        if endDate != nil { return "On, \(label(at: now)) left" }
        return "On until you turn it off"
    }
}

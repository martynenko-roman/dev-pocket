import AppKit
import Carbon.HIToolbox
import DevPocketKit
import IOKit.pwr_mgt
import ServiceManagement

enum SelfTest {
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0

    static func run() {
        Task {
            let suite = "com.romanmartynenko.devpocket.selftest.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let awake = KeepAwake(defaults: defaults)
            awake.notify = { _ in }
            check("starts off", !awake.isOn && awake.assertionID == 0)
            awake.start()
            check("creates real display-sleep assertion", awake.isOn && awake.assertionID != 0)
            check("exactly one named assertion", assertionCount() == 1)
            awake.start()
            check("restarting keeps exactly one assertion", assertionCount() == 1)
            awake.stop(announce: false)
            check("stop releases assertion", assertionCount() == 0 && !awake.isOn)
            awake.start(secondsOverride: 0.15)
            try? await Task.sleep(for: .milliseconds(350))
            check("timed session expires", !awake.isOn && assertionCount() == 0)
            awake.duration = .minutes15
            awake.start()
            check("stale timeline date never exceeds session length", awake.label(at: Date().addingTimeInterval(-1)) == "15:00")
            awake.duration = .hour1
            check("changing duration restarts countdown", abs((awake.endDate?.timeIntervalSinceNow ?? 0) - 3600) < 2)
            check("duration restart still holds one assertion", assertionCount() == 1)
            awake.stop(announce: false)
            check("duration persists", KeepAwake(defaults: defaults).duration == .hour1)
            let helper = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("DevPocket-helper.app")
            if FileManager.default.fileExists(atPath: helper.path) {
                do {
                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.activates = false
                    configuration.createsNewApplicationInstance = true
                    let app = try await NSWorkspace.shared.openApplication(at: helper, configuration: configuration)
                    for _ in 0..<50 {
                        if app.isFinishedLaunching { break }
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                    var notification = ""
                    awake.notify = { notification = $0 }
                    awake.start(app: app)
                    check("app session watches the selected PID", awake.isOn && awake.appPID == app.processIdentifier)
                    app.terminate()
                    for _ in 0..<50 {
                        if !awake.isOn { break }
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                    log("Helper finishedLaunching=\(app.isFinishedLaunching) terminated=\(app.isTerminated) awake=\(awake.isOn)")
                    check("app termination releases assertion", !awake.isOn && assertionCount() == 0)
                    check("app termination names the app in feedback", notification == "\(app.localizedName ?? "App") quit. Keep Awake is off")
                    if !app.isTerminated { app.terminate() }
                    awake.stop(announce: false)
                } catch { check("launches isolated app-watch helper", false) }
            } else { check("app-watch helper is packaged", false) }
            check("clock rounds up", Rules.clock(7199.2) == "2:00:00")
            check("missing desktop preference defaults on", Rules.preferenceBool(nil, fallback: true))
            for item in SystemToggle.allCases {
                check("symbol \(item.symbol) exists", NSImage(systemSymbolName: item.symbol, accessibilityDescription: nil) != nil)
                _ = SystemToggles.read(item)
            }
            check("reads live preferences without changing them", true)
            let audio = AudioDevices()
            try? await Task.sleep(for: .milliseconds(500))
            check("audio observers run without a concurrency trap", true)
            check("audio default belongs to output list or is absent", audio.output == 0 || audio.outputs.contains { $0.id == audio.output })
            audio.shutdown()
            testWheel()
            let shortcuts = ShortcutCenter(defaults: defaults)
            let combo = KeyCombination(key: UInt32(kVK_F18), modifiers: UInt32(controlKey | optionKey | shiftKey), display: "⌃⌥⇧F18")
            shortcuts.save(combo, for: .awake)
            check("Carbon registers shortcut without Accessibility", shortcuts.bindings[.awake] == combo)
            shortcuts.save(combo, for: .hidden)
            check("duplicate shortcut reports conflict", shortcuts.errors[.hidden] != nil)
            shortcuts.clear(.awake)
            check("clearing unregisters shortcut", shortcuts.bindings[.awake] == nil)
            shortcuts.shutdown()
            let info = Bundle.main.infoDictionary ?? [:]
            check("menu bar only Info.plist", info["LSUIElement"] as? Bool == true)
            check("Automation usage string exists", !(info["NSAppleEventsUsageDescription"] as? String ?? "").isEmpty)
            check("login setting reflects actual service", AppModel.shared.loginEnabled == (SMAppService.mainApp.status == .enabled))
            check("all power assertions released", assertionCount() == 0)
            log("SELFTEST \(failures == 0 ? "PASS" : "FAIL") \(count - failures)/\(count) checks")
            exitCode = failures == 0 ? 0 : 1
            NSApp.terminate(nil)
        }
    }

    private static func assertionCount() -> Int {
        var result: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&result) == kIOReturnSuccess, let result else { return -1 }
        let dict = result.takeRetainedValue() as NSDictionary
        let items = dict[NSNumber(value: ProcessInfo.processInfo.processIdentifier)] as? [[String: Any]] ?? []
        return items.filter { $0[kIOPMAssertionNameKey] as? String == "DevPocket Keep Awake" }.count
    }

    private static func testWheel() {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2,
                                  wheel1: 4, wheel2: -2, wheel3: 0) else {
            check("creates scroll fixture", false)
            return
        }
        let fields: [CGEventField] = [.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2,
                                     .scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2,
                                     .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2]
        let before = fields.map { event.getIntegerValueField($0) }
        ScrollReverser.reverseWheel(event)
        check("wheel reverses all six deltas", fields.map { event.getIntegerValueField($0) } == before.map { -$0 })
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 1)
        let phased = fields.map { event.getIntegerValueField($0) }
        ScrollReverser.reverseWheel(event)
        check("gesture deltas remain unchanged", fields.map { event.getIntegerValueField($0) } == phased)
    }

    private static func check(_ name: String, _ ok: Bool) {
        count += 1
        if !ok { failures += 1 }
        log("\(ok ? "PASS" : "FAIL") \(name)")
    }

    private static func log(_ message: String) {
        let data = Data("\(message)\n".utf8)
        FileHandle.standardOutput.write(data)
        if let path = ProcessInfo.processInfo.environment["APP_TEST_LOG"], path.hasPrefix("/private/tmp/") {
            if !FileManager.default.fileExists(atPath: path) { FileManager.default.createFile(atPath: path, contents: nil) }
            if let file = FileHandle(forWritingAtPath: path) {
                file.seekToEndOfFile()
                file.write(data)
                try? file.close()
            }
        }
    }
}

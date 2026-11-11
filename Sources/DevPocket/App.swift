import AppKit
import SwiftUI

enum AppMode {
    static var isSelfTest: Bool {
        CommandLine.arguments.contains("--selftest") || ProcessInfo.processInfo.environment["APP_SELFTEST"] == "1"
    }
    static var isReview: Bool { ProcessInfo.processInfo.environment["APP_REVIEW"] == "1" }
    static var isHelper: Bool { ProcessInfo.processInfo.environment["APP_HELPER"] == "1" }
    static var isSnapshot: Bool { ProcessInfo.processInfo.environment["APP_SNAPSHOT"] != nil }
    static var isTesting: Bool { isSnapshot || isSelfTest || isHelper }
}

@main
struct DevPocketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra("DevPocket", systemImage: model.awake.isOn ? "cup.and.saucer.fill" : "cup.and.saucer",
                     isInserted: .constant(!AppMode.isTesting)) {
            MenuBarPanel(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(AppMode.isSnapshot || AppMode.isHelper ? .regular : .accessory)
        if AppMode.isHelper {
            Task {
                try? await Task.sleep(for: .seconds(30))
                NSApp.terminate(nil)
            }
        } else if AppMode.isSnapshot { Snapshot.run(model: .shared) }
        else if AppMode.isSelfTest { SelfTest.run() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppModel.shared.shutdown()
        if AppMode.isSelfTest { exit(SelfTest.exitCode) }
    }
}

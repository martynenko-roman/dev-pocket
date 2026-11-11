import AppKit
import SwiftUI

enum Snapshot {
    private static var window: NSWindow?
    static func run(model: AppModel) {
        if ProcessInfo.processInfo.environment["APP_REVIEW"] == "1" {
            NSApp.appearance = NSAppearance(named: .aqua)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 760),
                                  styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.title = "DevPocket Visual Review"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: VisualReview(model: model))
            self.window = window
            window.center()
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
            return
        }
        guard let path = ProcessInfo.processInfo.environment["APP_SNAPSHOT"],
              URL(fileURLWithPath: path).standardizedFileURL.path.hasPrefix("/private/tmp/") || path.hasPrefix("/tmp/") else {
            NSApp.terminate(nil)
            return
        }
        Task {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            for mode in ["light", "dark"] {
                NSApp.appearance = NSAppearance(named: mode == "light" ? .aqua : .darkAqua)
                await show(MenuBarPanel(model: model), name: "menu-\(mode)", path: path,
                           size: NSSize(width: Layout.panelWidth, height: 200))
                // Run a real timed assertion for the countdown state, then release it.
                model.awake.start(secondsOverride: 899)
                await show(MenuBarPanel(model: model), name: "menu-awake-\(mode)", path: path,
                           size: NSSize(width: Layout.panelWidth, height: 200))
                model.awake.stop(announce: false)
                await show(GeneralSettings(model: model).frame(width: Layout.settingsWidth),
                           name: "settings-general-\(mode)", path: path,
                           size: NSSize(width: Layout.settingsWidth, height: 640))
                await show(ShortcutSettings(center: model.shortcuts).frame(width: Layout.settingsWidth),
                           name: "settings-shortcuts-\(mode)", path: path,
                           size: NSSize(width: Layout.settingsWidth, height: 320))
                await show(ToastView(text: "Keep Awake on"), name: "toast-\(mode)", path: path,
                           size: NSSize(width: Layout.toastWidth, height: Layout.toastHeight))
            }
            print("SNAPSHOT done \(path)")
            window?.close()
            NSApp.terminate(nil)
        }
    }

    private static func show<V: View>(_ view: V, name: String, path: String, size: NSSize) async {
        window?.contentView = nil
        window?.close()
        GridProbes.shared.reset()
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "DevPocket — \(name)"
        window.contentView = NSHostingView(rootView: view.noInitialFocus())
        window.center()
        self.window = window
        NSApp.unhideWithoutActivation()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        try? await Task.sleep(for: .milliseconds(900))
        GridProbes.shared.write(to: "\(path)/\(name)-layout.json", window: window.contentLayoutRect.size)
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-o", "-l", String(window.windowNumber), "\(path)/\(name).png"]
        try? capture.run()
        capture.waitUntilExit()
        if capture.terminationStatus == 0 { print("SNAPSHOT \(path)/\(name).png") }
        else { print("SNAPSHOT FAILED \(name): requires an active display and Screen Recording access") }
    }
}

private struct VisualReview: View {
    let model: AppModel
    @State private var surface = "Menu"
    @State private var dark = false

    var body: some View {
        VStack(spacing: Space.xl) {
            HStack {
                Picker("Surface", selection: $surface) {
                    ForEach(["Menu", "General", "Shortcuts", "Toast"], id: \.self) { Text($0) }
                }
                .onChange(of: surface) { _, _ in model.awake.stop(announce: false) }
                Toggle("Dark preview", isOn: $dark)
                    .onChange(of: dark) { _, value in
                        NSApp.appearance = NSAppearance(named: value ? .darkAqua : .aqua)
                    }
            }
            .padding(.horizontal, Space.margin)
            Divider()
            switch surface {
            case "General": GeneralSettings(model: model).frame(width: Layout.settingsWidth)
            case "Shortcuts": ShortcutSettings(center: model.shortcuts).frame(width: Layout.settingsWidth)
            case "Toast": ToastView(text: "Keep Awake on")
            default: MenuBarPanel(model: model)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, Space.margin)
        .frame(minWidth: 640, minHeight: 760)
        .noInitialFocus()
    }
}

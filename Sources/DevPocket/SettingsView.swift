import AppKit
import DevPocketKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    let model: AppModel
    var body: some View {
        TabView {
            GeneralSettings(model: model)
                .tabItem { Label("General", systemImage: "switch.2") }
            ShortcutSettings(center: model.shortcuts)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: Layout.settingsWidth)
        .noInitialFocus()
        .onAppear { model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in model.refresh() }
    }
}

struct GeneralSettings: View {
    let model: AppModel
    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(get: { model.awake.isOn }, set: { $0 ? model.awake.start() : model.awake.stop() })) {
                    Label("Keep Awake", systemImage: "cup.and.saucer.fill")
                }
                Picker("Duration", selection: Binding(get: { model.awake.duration }, set: { model.awake.duration = $0 })) {
                    ForEach(AwakeDuration.allCases) { Text($0.title).tag($0) }
                }
                Menu("While an App Runs…") {
                    let apps = model.runningApps
                    if apps.isEmpty { Text("No running apps") }
                    ForEach(apps, id: \.processIdentifier) { app in
                        Button(app.localizedName ?? "App") { model.awake.start(app: app) }
                    }
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(model.awake.status(at: context.date)).foregroundStyle(.secondary).monospacedDigit()
                }
            } header: { Text("Keep Awake") }
            footer: { Text("Closing the lid still sleeps the Mac.") }

            Section("System") {
                ForEach(SystemToggle.allCases) { item in
                    Toggle(isOn: Binding(get: { model.toggles.values[item] ?? false },
                                         set: { model.toggles.set(item, on: $0) })) {
                        HStack(spacing: Space.md) {
                            Image(systemName: item.symbol).frame(width: Space.xxl)
                            VStack(alignment: .leading, spacing: Space.xs) {
                                Text(item.title)
                                Text(item.detail).font(.caption).foregroundStyle(.secondary)
                                if let error = model.toggles.errors[item] {
                                    Text(error).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if model.toggles.busy.contains(item) { ProgressView().controlSize(.small) }
                        }
                    }
                    .disabled(model.toggles.busy.contains(item))
                    .accessibilityLabel(item.title)
                }
            }

            Section("Sound") {
                soundPicker(input: false)
                soundPicker(input: true)
                if let error = model.audio.error { Text(error).font(.caption).foregroundStyle(.red) }
            }

            Section {
                Toggle("Reverse mouse scroll direction", isOn: Binding(get: { model.scroll.enabled },
                                                                       set: { model.scroll.enabled = $0 }))
                HStack {
                    Text(model.scroll.status).font(.caption).foregroundStyle(.secondary)
                    if model.scroll.enabled, !model.scroll.trusted {
                        Spacer()
                        Button("Open Accessibility…") { model.scroll.openAccessibility() }
                    }
                }
            } header: { Text("Mouse") }
            footer: { Text("Quit Mos or other scroll apps first, or the direction flips twice.") }

            Section("Startup") {
                Toggle("Open at login", isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
                if model.loginNeedsApproval {
                    Button("Approve in Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                }
                if let error = model.loginError { Text(error).font(.caption).foregroundStyle(.red) }
            }
        }
        .formStyle(.grouped)
        .fitsContent()
    }

    private func soundPicker(input: Bool) -> some View {
        let devices = input ? model.audio.inputs : model.audio.outputs
        let selected = input ? model.audio.input : model.audio.output
        return Picker(input ? "Input" : "Output", selection: Binding(get: { selected },
                                                                    set: { model.audio.select($0, isInput: input) })) {
            if !devices.contains(where: { $0.id == selected }) {
                Text(devices.isEmpty ? "No devices" : "No device selected").tag(selected)
            }
            ForEach(devices) { device in Text(device.name).tag(device.id).help(device.name) }
        }
        .disabled(devices.isEmpty)
    }
}

struct ShortcutSettings: View {
    let center: ShortcutCenter
    var body: some View {
        Form {
            Section {
                ForEach(ShortcutAction.allCases) { action in
                    VStack(alignment: .leading, spacing: Space.sm) {
                        HStack {
                            Text(action.title)
                            Spacer()
                            Button(center.recording == action ? "Press Shortcut…" : (center.bindings[action]?.display ?? "Record Shortcut…")) {
                                if center.recording == action { center.stopRecording() }
                                else { center.startRecording(action) }
                            }
                            .help("Record a global shortcut for \(action.title)")
                            Button("Clear") { center.clear(action) }
                                .disabled(center.bindings[action] == nil && center.recording != action)
                        }
                        if let error = center.errors[action] {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            } header: { Text("Global shortcuts") }
            footer: { Text("No shortcuts are assigned by default. Include Command, Control, or Option. Press Escape to cancel recording.") }
        }
        .formStyle(.grouped)
        .fitsContent()
        .onDisappear { center.stopRecording() }
    }
}

import DevPocketKit
import SwiftUI

struct MenuBarPanel: View {
    let model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            HStack(spacing: Space.sm) {
                Text("DevPocket").font(.headline)
                Spacer(minLength: Space.sm)
                Menu {
                    SoundMenu(model: model.audio)
                } label: {
                    Label(model.audio.outputName, systemImage: "speaker.wave.2")
                        .lineLimit(1)
                        .frame(maxWidth: 180)
                }
                .menuStyle(.borderlessButton)
                .fixedSize(horizontal: false, vertical: true)
                .help("Choose a sound output or input device")
            }
            .gridProbe("header", area: "panel")

            HStack(alignment: .top, spacing: Space.sm) {
                Group {
                    RoundControl(title: model.awake.label(at: now), symbol: "cup.and.saucer.fill",
                                 on: model.awake.isOn, busy: false, help: "Turn Keep Awake on or off") {
                        model.awake.toggle()
                    }
                    .contextMenu { DurationMenu(awake: model.awake) }
                    .accessibilityLabel("Keep Awake")
                    .accessibilityValue(model.awake.status(at: now))
                }
                ForEach(SystemToggle.allCases) { item in
                    RoundControl(title: item.label, symbol: item.symbol,
                                 on: model.toggles.values[item] ?? false,
                                 busy: model.toggles.busy.contains(item), help: item.title) {
                        model.toggles.toggle(item)
                    }
                    .contextMenu {
                        Button(item.title) { model.toggles.toggle(item) }
                            .disabled(model.toggles.busy.contains(item))
                    }
                }
            }
            .gridProbe("controls", area: "panel")

            HStack {
                Text(model.awake.status(at: now)).font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: Space.sm)
                Button {
                    NSApp.activate()
                    openSettings()
                } label: { Image(systemName: "gearshape") }
                .buttonStyle(.plain)
                .help("Open Settings (⌘,)")
                .accessibilityLabel("Open Settings")
                .keyboardShortcut(",")
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .keyboardShortcut("q")
            }
            .gridProbe("footer", area: "panel")
        }
        .padding(Space.margin)
        .frame(width: Layout.panelWidth)
        .gridArea("panel")
        .noInitialFocus()
        .onAppear { model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in model.refresh() }
    }
}

private struct RoundControl: View {
    let title: String
    let symbol: String
    let on: Bool
    let busy: Bool
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Space.sm) {
                ZStack {
                    Circle().fill(on ? Color.accentColor : Color(nsColor: .quaternarySystemFill))
                    if busy { ProgressView().controlSize(.small) }
                    else {
                        Image(systemName: symbol)
                            .font(.system(size: Layout.symbolSize, weight: .medium))
                            .foregroundStyle(on ? Color(nsColor: .selectedMenuItemTextColor) : .primary)
                    }
                }
                .frame(width: Layout.toggleSize, height: Layout.toggleSize)
                Text(title).font(.caption).monospacedDigit().lineLimit(1)
            }
            .frame(width: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .help(help)
        .accessibilityLabel(help)
        .accessibilityValue(busy ? "Changing" : (on ? "On" : "Off"))
    }
}

struct DurationMenu: View {
    let awake: KeepAwake
    var body: some View {
        ForEach(AwakeDuration.allCases) { choice in
            Button {
                let restarts = awake.isOn && awake.appPID == nil
                awake.duration = choice
                if !restarts { awake.start() }
            } label: {
                if awake.duration == choice { Label(choice.title, systemImage: "checkmark") }
                else { Text(choice.title) }
            }
        }
        Divider()
        Button("Turn Off") { awake.stop() }.disabled(!awake.isOn)
    }
}

struct SoundMenu: View {
    let model: AudioDevices
    var body: some View {
        Section("Output") {
            if model.outputs.isEmpty { Text("No output devices") }
            ForEach(model.outputs) { device in
                Button { model.select(device.id, isInput: false) } label: {
                    if model.output == device.id { Label(device.name, systemImage: "checkmark") }
                    else { Text(device.name) }
                }
            }
        }
        Section("Input") {
            if model.inputs.isEmpty { Text("No input devices") }
            ForEach(model.inputs) { device in
                Button { model.select(device.id, isInput: true) } label: {
                    if model.input == device.id { Label(device.name, systemImage: "checkmark") }
                    else { Text(device.name) }
                }
            }
        }
    }
}

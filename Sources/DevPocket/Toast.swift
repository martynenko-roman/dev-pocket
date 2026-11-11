import AppKit
import SwiftUI

final class Toast {
    static let shared = Toast()
    private var panel: NSPanel?
    private var dismiss: Task<Void, Never>?

    func show(_ text: String) {
        guard !AppMode.isTesting else { return }
        dismiss?.cancel()
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        guard let screen else { return }
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(rootView: ToastView(text: text))
        let visible = screen.visibleFrame
        panel.setFrame(NSRect(x: visible.midX - Layout.toastWidth / 2,
                              y: visible.maxY - Layout.toastHeight - Space.sm,
                              width: Layout.toastWidth, height: Layout.toastHeight), display: true)
        panel.orderFrontRegardless()
        dismiss = Task {
            try? await Task.sleep(for: Motion.toastLifetime)
            if !Task.isCancelled { panel.orderOut(nil) }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        return panel
    }
}

struct ToastView: View {
    let text: String
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        Text(text)
            .font(.callout.weight(.medium))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.xl)
            .padding(.vertical, Space.md)
            .background {
                if reduceTransparency {
                    Capsule().fill(Color(nsColor: .windowBackgroundColor))
                } else {
                    Capsule().fill(.clear).glassEffect(.regular, in: .capsule)
                }
            }
            .padding(Space.sm)
            .accessibilityLabel(text)
    }
}

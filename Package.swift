// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Toolbox",
    platforms: [.macOS(.v26)],
    targets: [
        // Rules and data logic with no SwiftUI, so tests run without the app.
        .target(name: "ToolboxKit"),
        .executableTarget(
            name: "Toolbox",
            dependencies: ["ToolboxKit"],
            // App code runs on the main thread unless you say otherwise.
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "ToolboxKitTests", dependencies: ["ToolboxKit"]),
    ]
)

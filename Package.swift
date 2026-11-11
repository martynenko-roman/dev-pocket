// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DevPocket",
    platforms: [.macOS(.v26)],
    targets: [
        // Rules and data logic with no SwiftUI, so tests run without the app.
        .target(name: "DevPocketKit"),
        .executableTarget(
            name: "DevPocket",
            dependencies: ["DevPocketKit"],
            // App code runs on the main thread unless you say otherwise.
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "DevPocketKitTests", dependencies: ["DevPocketKit"]),
    ]
)

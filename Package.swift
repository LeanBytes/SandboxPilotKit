// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SandboxPilotKit",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        // SandboxPilotKit is embedded into the macOS apps you want to control from
        // the SandboxPilot companion app. It is also linked by the companion itself,
        // which only needs the shared wire-protocol and model types.
        .library(
            name: "SandboxPilotKit",
            targets: ["SandboxPilotKit"]
        ),
    ],
    targets: [
        .target(
            name: "SandboxPilotKit"
        ),
        .testTarget(
            name: "SandboxPilotKitTests",
            dependencies: ["SandboxPilotKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

# SandboxPilotKit

The companion SDK for [SandboxPilot](https://github.com/leanbytes/SandboxPilot) — a macOS
control center inspired by a similar tool, but for regular sandboxed/un-sandboxed Mac apps.

Because SandboxPilot cannot reach into an arbitrary app the way a similar tool talks to the iOS
simulator, the app you want to control embeds **SandboxPilotKit**. The kit opens a loopback
connection to the companion and lets it remotely:

- switch **appearance** (light / dark),
- switch **language / localization** (and relaunch),
- **resize** and **focus** windows,
- read and patch **UserDefaults**.

It carries no logging functionality — that is a separate product.

## Installation

Swift Package Manager. Add the dependency and link `SandboxPilotKit` to your app target:

```swift
.package(url: "https://github.com/leanbytes/SandboxPilotKit.git", from: "1.0.0")
```

…or reference it locally during development:

```swift
.package(path: "../SandboxPilotKit")
```

## Usage

Start the kit once, early in your app's lifecycle:

```swift
import SandboxPilotKit

@main
struct MyApp: App {
    init() {
        SandboxPilot.start() // 127.0.0.1:8085 by default; DEBUG builds only
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

`SandboxPilot.start()` is a no-op in release builds, so shipping apps never open a port.

## Requirements

- macOS 26+
- Swift 6.2+

The controlling features rely on AppKit (`NSApp`, window numbers) and a non-sandboxed process
for the language-switch relaunch, so the kit is intended for development/test builds of your app.

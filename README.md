# SandboxPilotKit

The companion SDK for [SandboxPilot](https://github.com/LeanBytes/SandboxPilot) — a macOS
control center for your own Mac apps.

The app you want to control embeds **SandboxPilotKit**. The kit opens a loopback connection to
the companion and lets it remotely:

- switch **appearance** (System / Light / Dark),
- switch **language / localization** (and relaunch),
- force **right-to-left** layout,
- **resize**, **focus** and **screenshot** windows,
- read and patch **UserDefaults** (live).

It carries no logging functionality — that is a separate product.

## Installation

Swift Package Manager. Add the dependency and link `SandboxPilotKit` to your app target:

```swift
.package(url: "https://github.com/LeanBytes/SandboxPilotKit.git", from: "1.0.0")
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

## Sandboxed apps

The kit works inside the App Sandbox. Add the outgoing-network entitlement to the app you're
controlling:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Relaunching (used by language switching and the RTL toggle) goes through `NSWorkspace`, so it
works sandboxed as well as un-sandboxed.

## Requirements

- macOS 26+
- Swift 6.2+

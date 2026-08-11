//
//  AppearanceControl.swift
//  SandboxPilotKit
//
//  Switches the controlled app between light and dark appearance.
//

import AppKit

public enum Appearance: String, Codable, Sendable {
    case system
    case light
    case dark
}

struct AppearanceControl {
    /// Applies `appearance`, or reports that there is nothing to apply it to yet.
    ///
    /// `NSApp` is an implicitly unwrapped optional that really is nil early in
    /// launch — a SwiftUI `App`'s `init()` runs before AppKit creates the
    /// application object — so this cannot just assign to it. The caller decides
    /// whether "not yet" means give up or try again later.
    @MainActor
    @discardableResult
    func change(to appearance: Appearance) -> Bool {
        guard let app = NSApp else { return false }
        switch appearance {
        case .system:
            // Drop the override so the app follows the system appearance again.
            app.appearance = nil
        case .light:
            app.appearance = NSAppearance(named: .aqua)
        case .dark:
            app.appearance = NSAppearance(named: .darkAqua)
        }
        return true
    }
}

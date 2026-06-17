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
    @MainActor
    func change(to appearance: Appearance) {
        switch appearance {
        case .system:
            // Drop the override so the app follows the system appearance again.
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

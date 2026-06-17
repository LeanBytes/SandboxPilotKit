//
//  AppearanceControl.swift
//  SandboxPilotKit
//
//  Switches the controlled app between light and dark appearance.
//

import AppKit

public enum Appearance: String, Codable, Sendable {
    case light
    case dark
}

struct AppearanceControl {
    @MainActor
    func change(to appearance: Appearance) {
        switch appearance {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

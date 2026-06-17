//
//  SandboxPilotUI.swift
//  SandboxPilotKit
//
//  Main-actor window manipulation in the controlled app: resize a window by
//  its window number, or bring it to the front and make it key.
//

import AppKit
import Foundation
import SwiftUI

@MainActor
public final class SandboxPilotUI: ObservableObject {
    public static let shared = SandboxPilotUI()

    private init() {}

    func resize(windowNumber: Int, to frame: NSRect) {
        if let window = NSApp.windows.first(where: { $0.windowNumber == windowNumber }) {
            window.setFrame(frame, display: true)
        }
    }

    func makeKey(windowNumber: Int) {
        if let window = NSApp.windows.first(where: { $0.windowNumber == windowNumber }) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

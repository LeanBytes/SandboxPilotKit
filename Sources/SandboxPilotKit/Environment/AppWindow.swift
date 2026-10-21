//
//  AppWindow.swift
//  SandboxPilotKit
//
//  A snapshot of a single window in a controlled app, plus the request type
//  used to resize one.
//

import AppKit

public struct WindowResizeRequest: Hashable, Codable, Sendable {
    public static let schemaVersion = 1

    public let windowNumber: Int
    public let frame: CGRect

    public init(windowNumber: Int, frame: CGRect) {
        self.windowNumber = windowNumber
        self.frame = frame
    }
}

public struct AppWindow: Hashable, Codable, Sendable {
    public static let schemaVersion = 1

    public let windowNumber: Int
    public let title: String
    public let frame: CGRect
    /// The window's identifier as the Accessibility API reports it, which is
    /// also what XCUITests match. Unlike the title it is not translated, so a
    /// screenshot plan can name the window in every language. Nil when unset.
    public let identifier: String?

    public init(windowNumber: Int, title: String, frame: CGRect, identifier: String? = nil) {
        self.windowNumber = windowNumber
        self.title = title
        self.frame = frame
        self.identifier = identifier
    }
}

extension AppWindow {
    /// A snapshot of one of this app's windows.
    @MainActor
    init(_ window: NSWindow) {
        // The Accessibility API falls back to the window's `identifier` (which a
        // SwiftUI scene sets) when no accessibility identifier is set.
        // `accessibilityIdentifier()` itself does not, so fall back here too.
        let accessibilityIdentifier = window.accessibilityIdentifier()
        self.init(
            windowNumber: window.windowNumber,
            title: window.title,
            frame: window.frame.roundedToPoints,
            identifier: accessibilityIdentifier.isEmpty ? window.identifier?.rawValue : accessibilityIdentifier
        )
    }
}

extension CGRect {
    /// Rounded to whole points. Reported window frames carry sub-pixel layout
    /// jitter that would otherwise defeat change-detection (and looks noisy).
    var roundedToPoints: CGRect {
        CGRect(x: origin.x.rounded(), y: origin.y.rounded(), width: width.rounded(), height: height.rounded())
    }
}

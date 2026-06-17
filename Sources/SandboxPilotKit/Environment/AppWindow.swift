//
//  AppWindow.swift
//  SandboxPilotKit
//
//  A snapshot of a single window in a controlled app, plus the request type
//  used to resize one.
//

import Foundation

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

    public init(windowNumber: Int, title: String, frame: CGRect) {
        self.windowNumber = windowNumber
        self.title = title
        self.frame = frame
    }
}

extension CGRect {
    /// Rounded to whole points. Reported window frames carry sub-pixel layout
    /// jitter that would otherwise defeat change-detection (and looks noisy).
    var roundedToPoints: CGRect {
        CGRect(x: origin.x.rounded(), y: origin.y.rounded(), width: width.rounded(), height: height.rounded())
    }
}

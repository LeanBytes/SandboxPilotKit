//
//  SandboxPilot.swift
//  SandboxPilotKit
//
//  Public entry point embedded by apps that want to be controllable from the
//  SandboxPilot companion app. Active in DEBUG builds only, so release builds
//  never open a connection.
//

import AppKit
import Foundation

public enum SandboxPilot {

    /// Starts the connection to the SandboxPilot companion app and begins
    /// handling remote-control commands. No-op in release builds.
    public static func start(
        host: String = "127.0.0.1",
        port: UInt16 = 8085
    ) {
        #if DEBUG
        Task {
            await SandboxPilotCore.shared.start(host: host, port: port)
        }
        #endif
    }

    /// Stops the connection and tears down all background work. No-op in release builds.
    public static func stop() {
        #if DEBUG
        Task {
            await SandboxPilotCore.shared.stop()
        }
        #endif
    }

    /// Window controls usable from the host app if needed.
    @MainActor
    public static var ui: SandboxPilotUI { SandboxPilotUI.shared }
}

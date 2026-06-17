//
//  PilotMessage.swift
//  SandboxPilotKit
//
//  The wire protocol exchanged between a controlled app (client) and the
//  SandboxPilot companion app (server). Messages are JSON encoded and
//  separated by a newline (0x0A) on a loopback TCP connection.
//

/// Messages sent FROM a controlled app TO the SandboxPilot companion app.
public enum PilotClientMessage: Codable, Sendable {
    case ack(String)
    case error(String)

    case environment(AppEnvironment)
    case info(AppInfo)
    case windows([AppWindow])
    case defaults([PrefPatch])
}

/// Messages sent FROM the SandboxPilot companion app TO a controlled app.
/// These are the remote-control commands.
public enum PilotServerMessage: Codable, Sendable {
    case ack(String)
    case error(String)

    case windowAsKeyRequest(Int)
    case windowResizeRequest(WindowResizeRequest)
    case appearanceChangeRequest(Appearance)
    case userDefaultsPatch([PrefPatch])
    case languageChangeRequest(String)
    case requestDefaults
    /// Relaunch the app, optionally with extra launch arguments.
    case relaunchRequest([String])
}

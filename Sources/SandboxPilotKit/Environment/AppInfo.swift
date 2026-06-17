//
//  AppInfo.swift
//  SandboxPilotKit
//
//  Static metadata describing a controlled app: name, identifiers, version and
//  the list of localizations it ships with (used to drive language switching).
//

public struct AppInfo: Codable, Sendable {
    public static let schemaVersion = 1

    public let name: String
    public let bundleId: String?
    public let version: String
    public let build: String
    public let localizations: [String]

    public init(name: String, bundleId: String?, version: String, build: String, localizations: [String]) {
        self.name = name
        self.bundleId = bundleId
        self.version = version
        self.build = build
        self.localizations = localizations
    }
}

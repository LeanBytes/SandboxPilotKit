//
//  AppEnvironment.swift
//  SandboxPilotKit
//
//  The current, observable environment state of a controlled app.
//

public struct AppEnvironment: Codable, Equatable, Hashable, Sendable {
    public static let schema = 1

    public let language: String?
    public let appearance: String?

    public init(language: String?, appearance: String?) {
        self.language = language
        self.appearance = appearance
    }
}

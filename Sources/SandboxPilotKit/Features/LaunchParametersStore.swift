//
//  LaunchParametersStore.swift
//  SandboxPilotKit
//
//  A dedicated UserDefaults suite for the launch parameters SandboxPilot hands
//  to the controlled app. Keeping them out of the standard domain means
//  SandboxPilot never touches the app's real preferences: the host app reads
//  these only as a fallback for real command-line launch arguments, and a stale
//  value can never leak into a normal, non-SandboxPilot launch.
//

import Foundation

enum LaunchParametersStore {
    /// The suite lives in the app's own container preferences, so writing it is
    /// sandbox-safe.
    static let suiteName = "io.leanbytes.sandboxpilot.launch"

    /// The whole parameter set is stored under a single key, so replacing it is
    /// one write and there is nothing to clear key-by-key.
    private static let storageKey = "parameters"

    private static var suite: UserDefaults? { UserDefaults(suiteName: suiteName) }

    /// Replace the entire set of launch parameters.
    static func set(_ parameters: [String: String]) {
        suite?.set(parameters, forKey: storageKey)
    }

    static func value(_ name: String) -> String? {
        (suite?.dictionary(forKey: storageKey) as? [String: String])?[name]
    }

    static var all: [String: String] {
        (suite?.dictionary(forKey: storageKey) as? [String: String]) ?? [:]
    }
}

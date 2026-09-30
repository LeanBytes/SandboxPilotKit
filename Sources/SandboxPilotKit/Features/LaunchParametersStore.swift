//
//  LaunchParametersStore.swift
//  SandboxPilotKit
//
//  A dedicated UserDefaults suite for the launch parameters SandboxPilot hands
//  to the controlled app. Keeping them out of the standard domain means
//  SandboxPilot never touches the app's real preferences: the host app reads
//  these only as a fallback for real command-line launch arguments.
//
//  A set applies to one launch, like real launch arguments: the launch that
//  reads it also removes it. Left in place, it would reach every later launch
//  too — a plain relaunch, a run from Xcode — since nothing tells those apart
//  from the relaunch SandboxPilot asked for.
//

import Foundation

enum LaunchParametersStore {
    /// The suite lives in the app's own container preferences, so writing it is
    /// sandbox-safe.
    static let suiteName = "io.leanbytes.sandboxpilot.launch"

    /// The whole parameter set is stored under a single key, so replacing it is
    /// one write and there is nothing to clear key-by-key.
    private static let storageKey = "parameters"

    /// This launch's parameters, taken out of the suite by the first read.
    /// `SandboxPilot.start()` reads first thing, so a set SandboxPilot stores
    /// while the app runs is left for the next launch.
    private static let current = take(from: UserDefaults(suiteName: suiteName))

    /// Replace the set the next launch takes.
    static func set(
        _ parameters: [String: String],
        in suite: UserDefaults? = UserDefaults(suiteName: LaunchParametersStore.suiteName)
    ) {
        suite?.set(parameters, forKey: storageKey)
    }

    /// Reads the stored set and removes it, so no later launch finds it.
    static func take(from suite: UserDefaults?) -> [String: String] {
        let parameters = (suite?.dictionary(forKey: storageKey) as? [String: String]) ?? [:]
        suite?.removeObject(forKey: storageKey)
        return parameters
    }

    static func value(_ name: String) -> String? {
        current[name]
    }

    static var all: [String: String] {
        current
    }
}

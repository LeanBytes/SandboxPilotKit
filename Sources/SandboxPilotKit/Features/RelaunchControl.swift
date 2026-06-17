//
//  RelaunchControl.swift
//  SandboxPilotKit
//
//  Relaunches the controlled app, optionally with extra launch arguments
//  (which land in the app's argument UserDefaults domain). Used for language
//  switching, forcing layout direction, and general launch-argument testing.
//
//  Uses NSWorkspace rather than spawning a process, so it works inside the App
//  Sandbox as well as outside it.
//

import AppKit
import Foundation

struct RelaunchControl {
    @MainActor
    func relaunch(arguments: [String] = []) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.arguments = arguments

        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            if let error {
                print("SandboxPilotKit: error relaunching app:", error)
            }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}

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
                // terminate returns only when it did not quit: AppKit ignores it
                // while a window shows a sheet, without even asking the delegate,
                // and a delegate can cancel or defer it. The old instance would
                // then stay on screen and connected, next to the new one. This
                // relaunch was asked for, so quit regardless.
                exit(0)
            }
        }
    }
}

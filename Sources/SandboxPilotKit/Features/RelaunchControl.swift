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

        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { newInstance, error in
            if let error {
                print("SandboxPilotKit: error relaunching app:", error)
            }
            DispatchQueue.main.async {
                // The new instance has launched by now, but need not be active yet.
                // Quit while active, and macOS gives activation to the app that was
                // in front before this one. The new instance then has to take it
                // from that app, which macOS refuses while someone works on the Mac,
                // and its windows stay inactive. So hand activation over, and quit
                // once it has left this instance.
                guard let newInstance, NSApp.isActive else { quit() }
                NSApp.yieldActivation(to: newInstance)
                guard newInstance.activate(from: .current, options: []) else { quit() }
                NotificationCenter.default.addObserver(
                    forName: NSApplication.didResignActiveNotification, object: NSApp, queue: .main
                ) { _ in MainActor.assumeIsolated { quit() } }
                // A new instance that dies before it takes over would leave this one waiting.
                NSWorkspace.shared.notificationCenter.addObserver(
                    forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
                ) { note in
                    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                    if app?.processIdentifier == newInstance.processIdentifier {
                        MainActor.assumeIsolated { quit() }
                    }
                }
            }
        }
    }

    @MainActor
    private func quit() -> Never {
        NSApp.terminate(nil)
        // terminate returns only when it did not quit: AppKit ignores it
        // while a window shows a sheet, without even asking the delegate,
        // and a delegate can cancel or defer it. The old instance would
        // then stay on screen and connected, next to the new one. This
        // relaunch was asked for, so quit regardless.
        exit(0)
    }
}

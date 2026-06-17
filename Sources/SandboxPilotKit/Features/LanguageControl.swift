//
//  LanguageControl.swift
//  SandboxPilotKit
//
//  Changes the controlled app's language by overriding `AppleLanguages` and
//  relaunching the process so the new localization takes effect.
//

import Foundation

struct LanguageControl {
    func change(to language: String) {
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        restartApp()
    }

    private func restartApp() {
        let bundlePath = Bundle.main.bundlePath

        let command = """
        sleep 0.1; open "\(bundlePath)"
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", command]

        do {
            try task.run()
        } catch {
            print("SandboxPilotKit: error restarting app:", error)
        }

        exit(0)
    }
}

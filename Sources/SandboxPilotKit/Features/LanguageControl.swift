//
//  LanguageControl.swift
//  SandboxPilotKit
//
//  Changes the controlled app's language by overriding `AppleLanguages` and
//  relaunching the process so the new localization takes effect.
//

import Foundation

struct LanguageControl {
    @MainActor
    func change(to language: String) {
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        RelaunchControl().relaunch()
    }
}

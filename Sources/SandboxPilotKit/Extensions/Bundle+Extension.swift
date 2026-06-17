//
//  Bundle+Extension.swift
//  SandboxPilotKit
//
//  Convenience accessors for the Info.plist values used when reporting app
//  metadata to the companion.
//

import Foundation

extension Bundle {
    public var appName: String { getInfo("CFBundleName") }
    public var displayName: String { getInfo("CFBundleDisplayName") }
    public var developmentRegion: String { getInfo("CFBundleDevelopmentRegion") }
    public var identifier: String { getInfo("CFBundleIdentifier") }
    public var copyright: String { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

    public var appBuild: String { getInfo("CFBundleVersion") }
    public var appVersionLong: String { getInfo("CFBundleShortVersionString") }

    fileprivate func getInfo(_ key: String) -> String { infoDictionary?[key] as? String ?? "⚠️" }
}

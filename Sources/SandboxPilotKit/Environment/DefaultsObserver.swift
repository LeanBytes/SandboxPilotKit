//
//  DefaultsObserver.swift
//  SandboxPilotKit
//
//  Watches the controlled app's UserDefaults and notifies when they change, so
//  the companion can show a live view instead of a stale snapshot.
//

import Foundation

@MainActor
final class DefaultsObserver {
    static let shared = DefaultsObserver()

    var onChange: (() -> Void)?

    private init() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onChange?() }
        }
    }
}

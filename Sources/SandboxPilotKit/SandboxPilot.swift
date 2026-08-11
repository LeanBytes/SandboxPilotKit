//
//  SandboxPilot.swift
//  SandboxPilotKit
//
//  Public entry point embedded by apps that want to be controllable from the
//  SandboxPilot companion app. Active in DEBUG builds only, so release builds
//  never open a connection.
//

import AppKit
import Foundation

public enum SandboxPilot {

    /// Starts the connection to the SandboxPilot companion app and begins
    /// handling remote-control commands. No-op in release builds.
    ///
    /// Call it from the host app's initializer, on the main thread. Besides
    /// opening the connection it applies the appearance a screenshot run left
    /// for this launch (see `appearanceParameterKey`), which only works while
    /// the app has no windows yet.
    public static func start(
        host: String = "127.0.0.1",
        port: UInt16 = 8085
    ) {
        #if DEBUG
        applyPendingAppearance()
        Task {
            await SandboxPilotCore.shared.start(host: host, port: port)
        }
        #endif
    }

    /// Stops the connection and tears down all background work. No-op in release builds.
    public static func stop() {
        #if DEBUG
        Task {
            await SandboxPilotCore.shared.stop()
        }
        #endif
    }

    /// Window controls usable from the host app if needed.
    @MainActor
    public static var ui: SandboxPilotUI { SandboxPilotUI.shared }

    // MARK: Launch parameters

    /// A launch parameter SandboxPilot set for this app, or nil if none. The
    /// host app calls this as a *fallback* for real command-line launch
    /// arguments — read it only after checking the argument domain, so genuine
    /// CLI launches always win. Reads a dedicated suite (see
    /// `LaunchParametersStore`), so it works at the very start of launch without
    /// waiting for the connection, and never reflects the app's real prefs.
    public static func launchParameter(_ key: String) -> String? {
        LaunchParametersStore.value(key)
    }

    /// All launch parameters SandboxPilot set for this app. `appearanceParameterKey`
    /// is not among them: it is SandboxPilot's own channel into the Kit, not one
    /// of the host app's parameters.
    public static var launchParameters: [String: String] {
        LaunchParametersStore.all.filter { $0.key != appearanceParameterKey }
    }

    // MARK: Appearance

    /// The reserved launch parameter a screenshot run uses to hand the app its
    /// appearance *before it launches*, instead of overriding a running one.
    ///
    /// The difference is not cosmetic. AppKit resolves some colors once, when a
    /// control is set up, and never again. A search field focused at launch
    /// resolves its field editor's text color against the appearance of that
    /// moment; setting `NSApp.appearance` afterwards repaints the field but not
    /// the text, which then draws white on a light background. Launching
    /// straight into the target appearance leaves nothing to go stale.
    ///
    /// It is prefixed so it can never collide with a host app's own parameters,
    /// which are always parsed from `-Key value` arguments.
    public static let appearanceParameterKey = "__appearance"

    #if DEBUG
    /// Applies the appearance a screenshot run left for this launch, if any.
    ///
    /// Has to land ahead of the first window, and has to run on the main thread
    /// — `start()` is documented as an app-init call, so it does. A call from
    /// anywhere else is skipped rather than trapped: the run then falls back to
    /// the companion's live appearance change, which is what happened before
    /// this existed.
    private static func applyPendingAppearance() {
        guard Thread.isMainThread,
              let raw = LaunchParametersStore.value(appearanceParameterKey),
              let appearance = Appearance(rawValue: raw)
        else { return }

        // A SwiftUI App's init() runs before AppKit has created NSApp, so the
        // first attempt normally reports "nothing to apply it to yet".
        // willFinishLaunching is the next moment, and still ahead of any window.
        if MainActor.assumeIsolated({ AppearanceControl().change(to: appearance) }) { return }

        var token: (any NSObjectProtocol)?
        token = NotificationCenter.default.addObserver(
            forName: NSApplication.willFinishLaunchingNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { AppearanceControl().change(to: appearance) }
            token.map(NotificationCenter.default.removeObserver)
        }
    }
    #endif
}

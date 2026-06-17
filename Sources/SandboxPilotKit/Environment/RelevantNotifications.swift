//
//  RelevantNotifications.swift
//  SandboxPilotKit
//
//  Observes window lifecycle notifications in the controlled app so the
//  companion always has an up-to-date list of windows (numbers, titles, frames).
//  Main-actor isolated because it touches AppKit window state throughout.
//

import AppKit
import Foundation

@MainActor
final class RelevantNotifications: NSObject {
    static let shared = RelevantNotifications()

    var onAppWindowsResized: (([AppWindow]) -> Void)?

    private var lastWindows: [AppWindow] = []

    private override init() {
        super.init()
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(windowWillClose(_:)), name: NSWindow.willCloseNotification, object: nil)
        nc.addObserver(self, selector: #selector(windowDidUpdate(_:)), name: NSWindow.didUpdateNotification, object: nil)
    }

    @objc private func windowWillClose(_ note: Notification) {
        updateWindows(ignore: note.object as? NSWindow)
    }

    @objc private func windowDidUpdate(_ note: Notification) {
        updateWindows()
    }

    func updateWindows(ignore: NSWindow? = nil) {
        var result: [AppWindow] = []
        for window in NSApp.windows {
            // Only report on-screen, real windows (skip menus, panels we don't own, etc.).
            guard window.isVisible else { continue }
            if ignore == nil || window.windowNumber != ignore!.windowNumber {
                let appWindow = AppWindow(
                    windowNumber: window.windowNumber,
                    title: window.title,
                    frame: window.frame.roundedToPoints
                )
                result.append(appWindow)
            }
        }

        // `NSApp.windows` is returned in z-order, which reshuffles constantly;
        // sort by window number so the change-detection below is stable.
        result.sort { $0.windowNumber < $1.windowNumber }

        // `didUpdateNotification` fires constantly (on every redraw); only emit
        // when the window list actually changed.
        guard result != lastWindows else { return }
        lastWindows = result
        onAppWindowsResized?(result)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

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
            if ignore == nil || window.windowNumber != ignore!.windowNumber {
                let appWindow = AppWindow(
                    windowNumber: window.windowNumber,
                    title: window.title,
                    frame: window.frame
                )
                result.append(appWindow)
            }
        }
        onAppWindowsResized?(result)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

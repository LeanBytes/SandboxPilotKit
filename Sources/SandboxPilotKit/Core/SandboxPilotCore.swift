//
//  SandboxPilotCore.swift
//  SandboxPilotKit
//
//  The controlled-app side orchestrator. On start it connects to the companion,
//  performs the handshake (sending app info, environment, windows and the
//  current UserDefaults), then handles incoming control commands.
//

import AppKit
import Foundation

final actor SandboxPilotCore {
    static let shared = SandboxPilotCore()

    private var started = false

    private let net: NetworkService
    private var tasks: [Task<Void, Never>] = []

    init() {
        self.net = NetworkService()
    }

    // MARK: Lifecycle

    func start(host: String, port: UInt16) async {
        guard !started else { return }
        started = true

        // 1) Handle commands coming from the companion (server).
        tasks.append(Task { [net, weak self] in
            for await msg in await net.messages {
                await self?.handle(msg)
            }
        })

        // 2) Connect + handshake: collect the initial state and report it.
        tasks.append(Task { [weak self] in
            guard let self else { return }

            await self.net.connect(host: host, port: port)

            let env = await self.collectEnvironment()
            let info = await self.collectAppInfo()
            let windows = await self.collectWindows()

            await self.net.send(.ack("hello-from-app"))
            await self.net.send(.info(info))
            await self.net.send(.environment(env))
            await self.net.send(.windows(windows))
            await self.net.send(.defaults(self.snapshotUserDefaults()))
        })

        // Keep the window list fresh as windows open, close and update.
        await MainActor.run {
            RelevantNotifications.shared.onAppWindowsResized = { [weak self] windows in
                Task { [weak self] in await self?.net.send(.windows(windows)) }
            }
        }
    }

    func stop() async {
        for task in tasks { task.cancel() }
        tasks.removeAll()
        await MainActor.run { RelevantNotifications.shared.onAppWindowsResized = nil }
        started = false
        await net.close()
    }

    // MARK: Command handling

    /// Executes a control command requested by the companion.
    private func handle(_ message: PilotServerMessage) async {
        switch message {
        case .requestDefaults:
            await net.send(.defaults(snapshotUserDefaults()))

        case .languageChangeRequest(let lang):
            await MainActor.run { LanguageControl().change(to: lang) }

        case .appearanceChangeRequest(let appearance):
            await MainActor.run { AppearanceControl().change(to: appearance) }

        case .windowResizeRequest(let req):
            await MainActor.run { SandboxPilotUI.shared.resize(windowNumber: req.windowNumber, to: req.frame) }

        case .windowAsKeyRequest(let number):
            await MainActor.run { SandboxPilotUI.shared.makeKey(windowNumber: number) }

        case .userDefaultsPatch(let patches):
            applyUserDefaults(patches)
            // Report the resulting state back so the companion stays in sync.
            await net.send(.defaults(snapshotUserDefaults()))

        case .ack, .error:
            break
        }
    }

    // MARK: Collectors

    @MainActor
    private func collectEnvironment() -> AppEnvironment {
        let isDark = NSApp.appearance?.name == .darkAqua
        let appearance = isDark ? "dark" : "light"
        let locale = Locale.current.identifier
        return AppEnvironment(language: locale, appearance: appearance)
    }

    @MainActor
    private func collectAppInfo() -> AppInfo {
        AppInfo(
            name: Bundle.main.appName,
            bundleId: Bundle.main.bundleIdentifier,
            version: Bundle.main.appVersionLong,
            build: Bundle.main.appBuild,
            localizations: Bundle.main.localizations
        )
    }

    @MainActor
    private func collectWindows() -> [AppWindow] {
        NSApp.windows.map { window in
            AppWindow(windowNumber: window.windowNumber, title: window.title, frame: window.frame)
        }
    }

    // MARK: UserDefaults

    private func snapshotUserDefaults() -> [PrefPatch] {
        UserDefaults.standard.dictionaryRepresentation().map { key, value in
            PrefPatch(key: key, value: PrefPatch.Value.fromAny(value) ?? .null)
        }
    }

    private func applyUserDefaults(_ patches: [PrefPatch]) {
        let ud = UserDefaults.standard
        for patch in patches {
            switch patch.value {
            case .none, .null:
                ud.removeObject(forKey: patch.key)
            case .some(let value):
                if let any = value.toAny() {
                    ud.set(any, forKey: patch.key)
                } else {
                    ud.removeObject(forKey: patch.key)
                }
            }
        }
    }
}

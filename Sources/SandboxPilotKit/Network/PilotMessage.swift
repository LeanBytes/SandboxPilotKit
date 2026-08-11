//
//  PilotMessage.swift
//  SandboxPilotKit
//
//  The wire protocol exchanged between a controlled app (client) and the
//  SandboxPilot companion app (server). Messages are JSON encoded and
//  separated by a newline (0x0A) on a loopback TCP connection.
//

/// The on-screen frame of a control the app exposes by accessibility identifier,
/// resolved in-process by the kit and reported to SandboxPilot so it can aim input
/// at the real element. Coordinates are the global screen space, top-left origin
/// (the CGEvent space). All components nil when the identifier wasn't found.
public struct ElementFrame: Codable, Sendable {
    public let identifier: String
    public let x: Double?
    public let y: Double?
    public let width: Double?
    public let height: Double?
    public init(identifier: String, x: Double?, y: Double?, width: Double?, height: Double?) {
        self.identifier = identifier
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    public var found: Bool { x != nil && width != nil }
}

/// Something to do *to* one of the app's controls, named by accessibility
/// identifier and carried out in-process by the kit.
///
/// Doing it inside the target is what keeps this permission-free: a process
/// reading and driving its own accessibility tree needs no Accessibility grant,
/// where synthesizing input from outside would. It also keeps both sides
/// app-agnostic — which control, and what to do to it, come from whoever wrote
/// the plan; neither SandboxPilot nor the kit knows what any app's UI contains.
public struct ElementAction: Codable, Sendable {
    /// Deliberately small. Add a case when a plan needs one, not before.
    public enum Kind: String, Codable, Sendable {
        /// Make the control the focused element of its window (`AXFocused`).
        case focus
    }

    public let identifier: String
    public let kind: Kind

    public init(identifier: String, kind: Kind) {
        self.identifier = identifier
        self.kind = kind
    }
}

/// The outcome of an `elementActionRequest`. `failure` says why not, so a plan
/// that names a control the app doesn't expose fails legibly instead of just
/// producing a screenshot of the wrong thing.
public struct ElementActionResult: Codable, Sendable {
    public let identifier: String
    public let kind: ElementAction.Kind
    public let performed: Bool
    public let failure: String?

    public init(identifier: String, kind: ElementAction.Kind, performed: Bool, failure: String? = nil) {
        self.identifier = identifier
        self.kind = kind
        self.performed = performed
        self.failure = failure
    }
}

/// Messages sent FROM a controlled app TO the SandboxPilot companion app.
public enum PilotClientMessage: Codable, Sendable {
    case ack(String)
    case error(String)

    case environment(AppEnvironment)
    case info(AppInfo)
    case windows([AppWindow])
    case defaults([PrefPatch])
    /// The resolved frame for an `elementFrameRequest` (or a not-found reply).
    case elementFrame(ElementFrame)
    /// The outcome of an `elementActionRequest`.
    case elementActionResult(ElementActionResult)
}

/// Messages sent FROM the SandboxPilot companion app TO a controlled app.
/// These are the remote-control commands.
public enum PilotServerMessage: Codable, Sendable {
    case ack(String)
    case error(String)

    case windowAsKeyRequest(Int)
    case windowResizeRequest(WindowResizeRequest)
    case appearanceChangeRequest(Appearance)
    case userDefaultsPatch([PrefPatch])
    case languageChangeRequest(String)
    case requestDefaults
    /// Relaunch the app, optionally with extra launch arguments.
    case relaunchRequest([String])
    /// Ask the app to resolve one of its controls (by accessibility identifier) to a
    /// screen frame, in-process, and reply with `elementFrame`. Lets SandboxPilot aim
    /// at real controls without cross-process Accessibility (which the App Sandbox
    /// blocks) and without any SandboxPilot-specific code in the target — the app only
    /// needs to label its controls with `.accessibilityIdentifier(_:)`.
    case elementFrameRequest(String)
    /// Ask the app to act on one of its controls (by accessibility identifier)
    /// in-process, and reply with `elementActionResult`. Where launch parameters
    /// put the app into a *state*, this drives its *UI* — and doing it inside the
    /// target needs no Accessibility grant, unlike synthesizing input from outside.
    case elementActionRequest(ElementAction)
    /// Set the app's SandboxPilot launch parameters. They are written to a
    /// dedicated UserDefaults suite (never the standard domain), so the host app
    /// can read them as a fallback for real command-line launch arguments
    /// without SandboxPilot ever touching its real preferences. Sending this
    /// replaces the whole set, so nothing leaks between runs.
    case setLaunchParameters([String: String])
}

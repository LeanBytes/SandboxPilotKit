//
//  SandboxPilotKitTests.swift
//  SandboxPilotKit
//

import Foundation
import Testing
@testable import SandboxPilotKit

@Suite("Wire protocol")
struct WireProtocolTests {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Test("Server control messages round-trip through JSON")
    func serverMessagesRoundTrip() throws {
        let messages: [PilotServerMessage] = [
            .requestDefaults,
            .appearanceChangeRequest(.dark),
            .languageChangeRequest("de"),
            .windowAsKeyRequest(42),
            .windowResizeRequest(WindowResizeRequest(windowNumber: 7, frame: CGRect(x: 0, y: 0, width: 800, height: 500))),
            .userDefaultsPatch([PrefPatch(key: "k", value: .int(1))]),
        ]
        for message in messages {
            let data = try encoder.encode(message)
            _ = try decoder.decode(PilotServerMessage.self, from: data)
        }
    }

    @Test("Client status messages round-trip through JSON")
    func clientMessagesRoundTrip() throws {
        let info = AppInfo(name: "Demo", bundleId: "io.leanbytes.Demo", version: "1.0", build: "1", localizations: ["en", "de"])
        let env = AppEnvironment(language: "en_US", appearance: "dark")
        let window = AppWindow(windowNumber: 1, title: "Main", frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let messages: [PilotClientMessage] = [
            .ack("hello-from-app"),
            .info(info),
            .environment(env),
            .windows([window]),
            .defaults([PrefPatch(key: "flag", value: .bool(true))]),
        ]
        for message in messages {
            let data = try encoder.encode(message)
            _ = try decoder.decode(PilotClientMessage.self, from: data)
        }
    }
}

@Suite("PrefPatch.Value")
struct PrefPatchValueTests {

    @Test("fromAny classifies common UserDefaults scalars")
    func fromAnyScalars() {
        #expect(PrefPatch.Value.fromAny("text") == .string("text"))
        #expect(PrefPatch.Value.fromAny(true) == .bool(true))
        #expect(PrefPatch.Value.fromAny(42) == .int(42))
    }

    @Test("toAny restores property-list compatible values")
    func toAnyRestores() {
        #expect(PrefPatch.Value.string("text").toAny() as? String == "text")
        #expect(PrefPatch.Value.int(42).toAny() as? Int == 42)
        #expect(PrefPatch.Value.bool(true).toAny() as? Bool == true)
        #expect(PrefPatch.Value.null.toAny() == nil)
    }

    @Test("array and dictionary survive a fromAny/toAny round-trip")
    func collectionsRoundTrip() {
        let original: [String: Any] = ["a": 1, "b": "two"]
        let value = PrefPatch.Value.fromAny(original)
        let restored = value?.toAny() as? [String: Any]
        #expect(restored?["a"] as? Int == 1)
        #expect(restored?["b"] as? String == "two")
    }
}

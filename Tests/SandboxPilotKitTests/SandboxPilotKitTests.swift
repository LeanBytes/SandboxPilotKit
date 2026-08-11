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

@Suite("Launch parameters")
struct LaunchParameterTests {

    // The appearance a screenshot run hands down travels in the same suite as
    // the host app's own parameters, so a host iterating `launchParameters`
    // must not find SandboxPilot's reserved key among them.
    @Test("the reserved appearance key is hidden from launchParameters")
    func appearanceKeyIsReserved() {
        let saved = LaunchParametersStore.all
        defer { LaunchParametersStore.set(saved) }

        LaunchParametersStore.set([
            "ArchivePath": "/tmp/demo.zip",
            SandboxPilot.appearanceParameterKey: "light",
        ])

        #expect(SandboxPilot.launchParameters == ["ArchivePath": "/tmp/demo.zip"])
        #expect(SandboxPilot.launchParameter("ArchivePath") == "/tmp/demo.zip")
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

    // Regression: the integers 0 and 1 bridge to Bool, so a naive `as? Bool`
    // misclassifies them. fromAny must keep them as integers.
    @Test("0 and 1 are integers, not booleans")
    func zeroAndOneAreIntegers() {
        #expect(PrefPatch.Value.fromAny(0) == .int(0))
        #expect(PrefPatch.Value.fromAny(1) == .int(1))
        #expect(PrefPatch.Value.fromAny(true) == .bool(true))
        #expect(PrefPatch.Value.fromAny(false) == .bool(false))
    }

    // The values actually come out of UserDefaults as NSNumber/CFBoolean, so
    // verify classification through a real round-trip — including 0/0.0, which
    // is where the bug showed up.
    @Test("UserDefaults scalars classify by their true type")
    func userDefaultsScalarsClassify() {
        let suite = "io.leanbytes.sandboxpilot.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(false, forKey: "flagFalse")
        defaults.set(true, forKey: "flagTrue")
        defaults.set(0, forKey: "intZero")
        defaults.set(1, forKey: "intOne")
        defaults.set(7, forKey: "intSeven")
        defaults.set(0.0, forKey: "doubleZero")
        defaults.set(3.5, forKey: "doubleVal")
        defaults.set(Float(2.5), forKey: "floatVal")
        defaults.set("hi", forKey: "stringVal")

        func value(_ key: String) -> PrefPatch.Value? {
            defaults.object(forKey: key).flatMap { PrefPatch.Value.fromAny($0) }
        }

        #expect(value("flagFalse") == .bool(false))
        #expect(value("flagTrue") == .bool(true))
        #expect(value("intZero") == .int(0))
        #expect(value("intOne") == .int(1))
        #expect(value("intSeven") == .int(7))
        #expect(value("doubleZero") == .double(0))
        #expect(value("doubleVal") == .double(3.5))
        #expect(value("floatVal") == .double(2.5))
        #expect(value("stringVal") == .string("hi"))
    }
}

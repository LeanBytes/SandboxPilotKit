//
//  PrefPatch.swift
//  SandboxPilotKit
//
//  A serializable representation of a single UserDefaults key/value pair.
//  Used both to snapshot a controlled app's defaults and to patch them.
//

import Foundation

public struct PrefPatch: Codable, Identifiable, Sendable, Equatable {
    public enum Value: Codable, Equatable {
        case string(String)
        case int(Int)
        case bool(Bool)
        case double(Double)
        case data(Data)
        case date(Date)
        case array([Value])
        case dictionary([String: Value])
        case null
    }

    public var id = UUID()
    public var key: String
    public var value: Value? // nil or .null means remove

    public init(key: String, value: Value? = nil) {
        self.key = key
        self.value = value
    }

    public static func == (lhs: PrefPatch, rhs: PrefPatch) -> Bool {
        lhs.id == rhs.id
    }
}

extension PrefPatch.Value: Sendable {
    /// Best-effort conversion from an arbitrary `UserDefaults` value into a
    /// serializable `Value`.
    public static func fromAny(_ any: Any) -> PrefPatch.Value? {
        // UserDefaults stores scalars as NSNumber / CFBoolean, so disambiguate
        // those FIRST. `any as? Bool` succeeds for the integers 0 and 1, which
        // would otherwise misclassify those numbers as booleans.
        if let num = any as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return .bool(num.boolValue)
            }
            // objCType: f/d are floating point; everything else is an integer.
            let objCType = String(cString: num.objCType)
            if objCType == "f" || objCType == "d" {
                return .double(num.doubleValue)
            }
            return .int(num.intValue)
        }

        if let v = any as? String { return .string(v) }
        if let v = any as? Data   { return .data(v) }
        if let v = any as? Date   { return .date(v) }
        if any is NSNull          { return .null }

        // Arrays/Dictionaries — recurse
        if let arr = any as? [Any] {
            let mapped = arr.compactMap { PrefPatch.Value.fromAny($0) }
            return .array(mapped)
        }
        if let dict = any as? [String: Any] {
            var mapped: [String: PrefPatch.Value] = [:]
            for (k, v) in dict {
                if let mv = PrefPatch.Value.fromAny(v) { mapped[k] = mv }
            }
            return .dictionary(mapped)
        }

        // URLs are usually stored as Data/Bookmark; if stored as String this covers it.
        if let url = any as? URL {
            return .string(url.absoluteString)
        }

        // Unsupported type
        return nil
    }

    /// Converts back into a property-list-compatible value so it can be
    /// written to `UserDefaults`. Returns `nil` for `.null`.
    public func toAny() -> Any? {
        switch self {
        case .string(let s):     return s
        case .int(let i):        return i
        case .bool(let b):       return b
        case .double(let d):     return d
        case .data(let d):       return d
        case .date(let d):       return d
        case .null:              return nil
        case .array(let a):      return a.compactMap { $0.toAny() }
        case .dictionary(let d):
            var out: [String: Any] = [:]
            for (k, v) in d { if let av = v.toAny() { out[k] = av } }
            return out
        }
    }

    public var displayString: String {
        switch self {
        case .string(let s):  return s
        case .int(let i):     return String(i)
        case .bool(let b):    return b ? "true" : "false"
        case .double(let d):  return String(d)
        case .data(let d):    return "\(d.count) bytes"
        case .date(let d):    return "\(d)"
        case .null:           return "∅"

        case .array(let a):
            // Compact preview: [item1, item2, …]
            let parts = a.prefix(10).map { $0.displayString }
            return "[\(parts.joined(separator: ", "))\(a.count > 10 ? ", …" : "")]"

        case .dictionary(let d):
            // Compact preview: {k1: v1, k2: v2, …}
            let parts = d.keys.sorted().prefix(10).map { k in
                "\(k): \(d[k]!.displayString)"
            }
            return "{\(parts.joined(separator: ", "))\(d.count > 10 ? ", …" : "")}"
        }
    }
}

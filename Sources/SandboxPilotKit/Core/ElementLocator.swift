//
//  ElementLocator.swift
//  SandboxPilotKit
//
//  Resolves one of THIS app's controls (by accessibility identifier) to a screen
//  frame, in-process. SandboxPilot can't read another app's Accessibility tree from
//  its sandbox, but the kit runs *inside* the target, so it reads the app's own tree
//  — no cross-process access, no TCC grant, no sandbox concern. The app only has to
//  label its controls with `.accessibilityIdentifier(_:)` (ordinary accessibility);
//  it needs no SandboxPilot-specific code.
//
//  The AX read runs OFF the main thread on purpose: an app reading its own AX tree
//  from the main thread deadlocks, because the accessibility server services that
//  request on the very same runloop.
//

import AppKit
import ApplicationServices

enum ElementLocator {
    /// Screen frame (global, top-left origin — the CGEvent space) of this app's first
    /// element whose `AXIdentifier` equals `identifier`. Components are nil if absent.
    static func screenFrame(identifier: String) async -> ElementFrame {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let app = AXUIElementCreateApplication(getpid())
                if let el = find(in: app, identifier: identifier, depth: 0), let r = frame(of: el) {
                    continuation.resume(returning: ElementFrame(
                        identifier: identifier,
                        x: r.origin.x, y: r.origin.y, width: r.size.width, height: r.size.height))
                } else {
                    continuation.resume(returning: ElementFrame(
                        identifier: identifier, x: nil, y: nil, width: nil, height: nil))
                }
            }
        }
    }

    private static func find(in element: AXUIElement, identifier: String, depth: Int) -> AXUIElement? {
        if depth > 80 { return nil }
        if string(element, kAXIdentifierAttribute) == identifier { return element }
        for child in children(of: element) {
            if let hit = find(in: child, identifier: identifier, depth: depth + 1) { return hit }
        }
        return nil
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &ref) == .success,
              let arr = ref as? [AXUIElement] else { return [] }
        return arr
    }

    private static func string(_ element: AXUIElement, _ attr: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success else { return nil }
        return ref as? String
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posV = posRef, let sizeV = sizeRef,
              CFGetTypeID(posV) == AXValueGetTypeID(), CFGetTypeID(sizeV) == AXValueGetTypeID()
        else { return nil }
        var pos = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(posV as! AXValue, .cgPoint, &pos)
        AXValueGetValue(sizeV as! AXValue, .cgSize, &size)
        guard size.width > 0, size.height > 0 else { return nil }
        return CGRect(origin: pos, size: size)
    }
}

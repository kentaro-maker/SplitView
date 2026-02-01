import Foundation
import CoreGraphics
import AppKit

/// Manages global keyboard shortcuts for window snapping
class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Key codes for numpad keys 1-9
    private let numpadKeyCodeMap: [Int64: GridPosition] = [
        83: .bottomLeft,    // Numpad 1
        84: .bottomCenter,  // Numpad 2
        85: .bottomRight,   // Numpad 3
        86: .middleLeft,    // Numpad 4
        87: .center,        // Numpad 5 (full screen)
        88: .middleRight,   // Numpad 6
        89: .topLeft,       // Numpad 7
        91: .topCenter,     // Numpad 8
        92: .topRight       // Numpad 9
    ]

    // Also support regular number keys as fallback
    private let regularKeyCodeMap: [Int64: GridPosition] = [
        18: .bottomLeft,    // 1
        19: .bottomCenter,  // 2
        20: .bottomRight,   // 3
        21: .middleLeft,    // 4
        23: .center,        // 5
        22: .middleRight,   // 6
        26: .topLeft,       // 7
        28: .topCenter,     // 8
        25: .topRight       // 9
    ]

    private init() {}

    /// Start listening for keyboard shortcuts
    func start() {
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        // Create event tap
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else { return }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    /// Stop listening for keyboard shortcuts
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
    }

    /// Handle a keyboard event
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled events (re-enable the tap)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // Check modifiers
        let flags = event.flags
        let hasCtrl = flags.contains(.maskControl)
        let hasFn = flags.contains(.maskSecondaryFn)  // Globe/fn key
        let hasCmd = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasOption = flags.contains(.maskAlternate)

        // Get the key code
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Accept either:
        // 1. Ctrl + Globe (fn) + numpad/number
        // 2. Ctrl + Option + numpad/number (fallback)
        let validModifiers = (hasCtrl && hasFn && !hasCmd && !hasShift) ||
                            (hasCtrl && hasOption && !hasCmd && !hasShift)

        guard validModifiers else {
            return Unmanaged.passRetained(event)
        }

        // Check numpad keys first, then regular number keys
        let position: GridPosition?
        if let numpadPosition = numpadKeyCodeMap[keyCode] {
            position = numpadPosition
        } else if let regularPosition = regularKeyCodeMap[keyCode] {
            position = regularPosition
        } else {
            position = nil
        }

        guard let targetPosition = position else {
            return Unmanaged.passRetained(event)
        }

        // Move the window
        DispatchQueue.main.async {
            let success = WindowManager.shared.moveWindow(to: targetPosition)
            if !success {
                NSSound.beep()
            }
        }

        // Consume the event (don't pass it to other apps)
        return nil
    }

    deinit {
        stop()
    }
}

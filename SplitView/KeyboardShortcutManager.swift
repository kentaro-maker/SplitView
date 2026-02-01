import Foundation
import CoreGraphics
import AppKit

/// Manages global keyboard shortcuts for window snapping
class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Track currently held number keys (for combo detection)
    private var heldKeys: Set<Int> = []
    private var lastActionTime: Date = .distantPast

    // Key codes for numpad keys 1-9
    private let numpadKeyCodeToNumber: [Int64: Int] = [
        83: 1, 84: 2, 85: 3,
        86: 4, 87: 5, 88: 6,
        89: 7, 91: 8, 92: 9
    ]

    // Regular number keys
    private let regularKeyCodeToNumber: [Int64: Int] = [
        18: 1, 19: 2, 20: 3,
        21: 4, 23: 5, 22: 6,
        26: 7, 28: 8, 25: 9
    ]

    // Valid half-position combos (sorted key pairs)
    private let halfPositionCombos: [Set<Int>: HalfPosition] = [
        [7, 8]: .topLeftHalf,
        [8, 9]: .topRightHalf,
        [4, 5]: .middleLeftHalf,
        [5, 6]: .middleRightHalf,
        [1, 2]: .bottomLeftHalf,
        [2, 3]: .bottomRightHalf,
        [7, 4]: .leftTopHalf,
        [4, 1]: .leftBottomHalf,
        [8, 5]: .centerTopHalf,
        [5, 2]: .centerBottomHalf,
        [9, 6]: .rightTopHalf,
        [6, 3]: .rightBottomHalf
    ]

    // Number to GridPosition
    private let numberToPosition: [Int: GridPosition] = [
        1: .bottomLeft, 2: .bottomCenter, 3: .bottomRight,
        4: .middleLeft, 5: .center, 6: .middleRight,
        7: .topLeft, 8: .topCenter, 9: .topRight
    ]

    private init() {}

    /// Start listening for keyboard shortcuts
    func start() {
        guard eventTap == nil else { return }

        // Listen for both keyDown and keyUp
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

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
        // Re-enable tap if disabled
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Get number from key code
        let number = numpadKeyCodeToNumber[keyCode] ?? regularKeyCodeToNumber[keyCode]

        // Track key up/down for combo detection
        if let num = number {
            if type == .keyUp {
                heldKeys.remove(num)
                return Unmanaged.passRetained(event)
            }
            // keyDown - add to held keys
            heldKeys.insert(num)
        }

        // Only process keyDown
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        // Check modifiers
        let flags = event.flags
        let hasCtrl = flags.contains(.maskControl)
        let hasFn = flags.contains(.maskSecondaryFn)
        let hasCmd = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasOption = flags.contains(.maskAlternate)

        let validModifiers = (hasCtrl && hasFn && !hasCmd && !hasShift) ||
                            (hasCtrl && hasOption && !hasCmd && !hasShift)

        guard validModifiers, number != nil else {
            return Unmanaged.passRetained(event)
        }

        // Debounce: prevent double-triggering
        let now = Date()
        guard now.timeIntervalSince(lastActionTime) > 0.1 else {
            return nil
        }

        // Check for half-position combo (two keys held)
        if heldKeys.count >= 2 {
            if let halfPos = halfPositionCombos[heldKeys] {
                lastActionTime = now
                DispatchQueue.main.async {
                    let success = WindowManager.shared.moveWindowToHalf(halfPos)
                    if !success { NSSound.beep() }
                }
                return nil
            }
        }

        // Single key - regular grid position
        if let num = number, let position = numberToPosition[num] {
            lastActionTime = now
            DispatchQueue.main.async {
                let success = WindowManager.shared.moveWindow(to: position)
                if !success { NSSound.beep() }
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    deinit {
        stop()
    }
}

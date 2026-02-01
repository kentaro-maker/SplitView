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
    private var comboTriggered: Bool = false  // Track if combo was triggered during this key sequence
    private var lastFiveWasFullScreen: Bool = false  // Toggle state for key 5

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
        [6, 3]: .rightBottomHalf,
        // Corner quarters (2/3 × 2/3)
        [7, 5]: .topLeftQuarter,
        [9, 5]: .topRightQuarter,
        [1, 5]: .bottomLeftQuarter,
        [3, 5]: .bottomRightQuarter,
        // True halves (1/2 screen)
        [7, 1]: .leftHalf,
        [9, 3]: .rightHalf,
        [7, 9]: .topHalf,
        [1, 3]: .bottomHalf,
        // True corners (1/4 screen) - 3 key combos
        [1, 7, 9]: .topLeftCorner,
        [3, 7, 9]: .topRightCorner,
        [1, 3, 7]: .bottomLeftCorner,
        [1, 3, 9]: .bottomRightCorner
    ]

    // Number to GridPosition
    private let numberToPosition: [Int: GridPosition] = [
        1: .bottomLeft, 2: .bottomCenter, 3: .bottomRight,
        4: .middleLeft, 5: .center, 6: .middleRight,
        7: .topLeft, 8: .topCenter, 9: .topRight
    ]

    // Number to HalfPosition (when Option is pressed - single key)
    private let numberToHalfPosition: [Int: HalfPosition] = [
        1: .bottomLeftCorner,   // 1/2 × 1/2 bottom-left
        2: .bottomHalf,         // full × 1/2 bottom
        3: .bottomRightCorner,  // 1/2 × 1/2 bottom-right
        4: .leftHalf,           // 1/2 × full left
        // 5: full screen (handled separately)
        6: .rightHalf,          // 1/2 × full right
        7: .topLeftCorner,      // 1/2 × 1/2 top-left
        8: .topHalf,            // full × 1/2 top
        9: .topRightCorner      // 1/2 × 1/2 top-right
    ]

    // Third position combos (without Option - 1/3 width full height or full width 1/3 height)
    private let thirdPositionCombos: [Set<Int>: HalfPosition] = [
        // Vertical thirds (1/3 width × full height)
        [7, 1]: .leftThird,
        [7, 4]: .leftThird,
        [4, 1]: .leftThird,
        [7, 4, 1]: .leftThird,
        [8, 2]: .centerThird,
        [8, 5]: .centerThird,
        [5, 2]: .centerThird,
        [8, 5, 2]: .centerThird,
        [9, 3]: .rightThird,
        [9, 6]: .rightThird,
        [6, 3]: .rightThird,
        [9, 6, 3]: .rightThird,
        // Horizontal thirds (full width × 1/3 height)
        [7, 9]: .topThird,
        [7, 8]: .topThird,
        [8, 9]: .topThird,
        [7, 8, 9]: .topThird,
        [4, 6]: .middleThird,
        [4, 5]: .middleThird,
        [5, 6]: .middleThird,
        [4, 5, 6]: .middleThird,
        [1, 3]: .bottomThird,
        [1, 2]: .bottomThird,
        [2, 3]: .bottomThird,
        [1, 2, 3]: .bottomThird
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

        // Check modifiers first
        let flags = event.flags
        let hasCtrl = flags.contains(.maskControl)
        let hasFn = flags.contains(.maskSecondaryFn)
        let hasCmd = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasOption = flags.contains(.maskAlternate)

        // Check for valid modifier combinations
        // Normal mode: Ctrl + Option (no Shift) OR Ctrl + Fn (no Shift)
        // Half mode: Ctrl + Option + Shift OR Ctrl + Fn + Shift
        let baseModifiers = (hasCtrl && hasOption && !hasCmd) || (hasCtrl && hasFn && !hasCmd)
        let isHalfMode = baseModifiers && hasShift
        let isNormalMode = baseModifiers && !hasShift

        let validModifiers = isHalfMode || isNormalMode

        // Get number from key code
        let number = numpadKeyCodeToNumber[keyCode] ?? regularKeyCodeToNumber[keyCode]

        guard let num = number, validModifiers else {
            return Unmanaged.passRetained(event)
        }

        // Only handle keyDown
        guard type == .keyDown else {
            // Clean up held keys on keyUp
            if type == .keyUp {
                heldKeys.remove(num)
                if heldKeys.isEmpty {
                    comboTriggered = false
                }
            }
            return nil
        }

        // Debounce
        let now = Date()
        guard now.timeIntervalSince(lastActionTime) > 0.1 else {
            return nil
        }

        // Track held keys for multi-key combos
        heldKeys.insert(num)

        // Check for multi-key combo first (2+ keys held)
        if heldKeys.count >= 2 {
            // With Option: use half position combos (1/2 screen)
            // Without Option: use third position combos (1/3 full height/width)
            let comboDict = hasOption ? halfPositionCombos : thirdPositionCombos
            if let halfPos = comboDict[heldKeys] {
                comboTriggered = true
                lastActionTime = now
                DispatchQueue.main.async {
                    let success = WindowManager.shared.moveWindowToHalf(halfPos)
                    if !success { NSSound.beep() }
                }
                return nil
            }
            // If no match in primary dict, try the other one as fallback
            let fallbackDict = hasOption ? thirdPositionCombos : halfPositionCombos
            if let halfPos = fallbackDict[heldKeys] {
                comboTriggered = true
                lastActionTime = now
                DispatchQueue.main.async {
                    let success = WindowManager.shared.moveWindowToHalf(halfPos)
                    if !success { NSSound.beep() }
                }
                return nil
            }
        }

        // Single key - check if half mode (Option pressed)
        if hasOption {
            // Half mode
            if num == 5 {
                let halfPos: HalfPosition = lastFiveWasFullScreen ? .centerHalf : .fullScreen
                lastFiveWasFullScreen = !lastFiveWasFullScreen
                lastActionTime = now
                DispatchQueue.main.async {
                    let success = WindowManager.shared.moveWindowToHalf(halfPos)
                    if !success { NSSound.beep() }
                }
            } else if let halfPos = numberToHalfPosition[num] {
                lastActionTime = now
                DispatchQueue.main.async {
                    let success = WindowManager.shared.moveWindowToHalf(halfPos)
                    if !success { NSSound.beep() }
                }
            }
        } else {
            // Normal 1/3 mode
            if let position = numberToPosition[num] {
                lastActionTime = now
                DispatchQueue.main.async {
                    let success = WindowManager.shared.moveWindow(to: position)
                    if !success { NSSound.beep() }
                }
            }
        }

        return nil
    }

    deinit {
        stop()
    }
}

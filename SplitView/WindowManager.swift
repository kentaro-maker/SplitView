import Foundation
import AppKit
import ApplicationServices

/// Manages window positioning using Accessibility API
class WindowManager {
    static let shared = WindowManager()

    // Track the last active app (not ourselves)
    private var lastActiveApp: NSRunningApplication?
    private var lastActiveWindow: AXUIElement?

    private init() {
        // Observe app activation to track last active app
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

        // Don't track ourselves
        if app.bundleIdentifier != "com.splitview.app" {
            lastActiveApp = app

            // Also cache the window
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var window: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &window) == .success {
                lastActiveWindow = (window as! AXUIElement)
            }
        }
    }

    /// Check if the app has accessibility permissions
    var hasAccessibilityPermission: Bool {
        return AXIsProcessTrusted()
    }

    /// Request accessibility permissions from the user
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Get the frontmost window
    private func getFrontmostWindow() -> AXUIElement? {
        var app = NSWorkspace.shared.frontmostApplication

        // If frontmost is ourselves, use the last active app
        if app?.bundleIdentifier == "com.splitview.app" {
            app = lastActiveApp
        }

        guard let targetApp = app else { return nil }

        let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)

        // Try focused window first
        var window: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &window) == .success {
            return (window as! AXUIElement)
        }

        // Fallback to first window in window list
        var windows: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows) == .success,
           let windowList = windows as? [AXUIElement],
           let first = windowList.first {
            return first
        }

        // Last resort: use cached window
        if let cached = lastActiveWindow {
            return cached
        }

        return nil
    }

    /// Move and resize the frontmost window to the specified grid position
    func moveWindow(to position: GridPosition) -> Bool {
        guard hasAccessibilityPermission else {
            requestAccessibilityPermission()
            return false
        }

        guard let window = getFrontmostWindow() else { return false }

        // Get primary screen for coordinate conversion
        guard let primaryScreen = NSScreen.screens.first else { return false }
        guard let screen = NSScreen.main else { return false }

        let visible = screen.visibleFrame
        let primaryMaxY = primaryScreen.frame.maxY  // Top of primary screen in Cocoa coords

        let cellW = visible.width / 3
        let cellH = visible.height / 3

        // Column (0=left, 1=center, 2=right)
        let col: CGFloat
        switch position {
        case .bottomLeft, .middleLeft, .topLeft: col = 0
        case .bottomCenter, .center, .topCenter: col = 1
        case .bottomRight, .middleRight, .topRight: col = 2
        }

        // Row in Cocoa coords (0=bottom, 1=middle, 2=top)
        let row: CGFloat
        switch position {
        case .bottomLeft, .bottomCenter, .bottomRight: row = 0
        case .middleLeft, .center, .middleRight: row = 1
        case .topLeft, .topCenter, .topRight: row = 2
        }

        // Calculate in Cocoa coordinates first
        let cocoaX = visible.origin.x + col * cellW
        let cocoaY = visible.origin.y + row * cellH

        // Convert to AX coordinates: axY = primaryMaxY - cocoaY - height
        let axX = cocoaX
        let axY = primaryMaxY - cocoaY - cellH

        // Rectangle's 3-step approach: size → position → size
        // This handles macOS enforcing display-appropriate sizes when windows move
        var size = CGSize(width: cellW, height: cellH)
        var pos = CGPoint(x: axX, y: axY)

        guard let sizeValue = AXValueCreate(.cgSize, &size),
              let posValue = AXValueCreate(.cgPoint, &pos) else { return false }

        // Step 1: Set size first
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

        // Step 2: Set position
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)

        // Step 3: Set size again (in case position change affected allowed size)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

        return true
    }

    /// Move and resize the frontmost window to a half position (2 cells combined)
    func moveWindowToHalf(_ position: HalfPosition) -> Bool {
        guard hasAccessibilityPermission else {
            requestAccessibilityPermission()
            return false
        }

        guard let window = getFrontmostWindow() else { return false }

        guard let primaryScreen = NSScreen.screens.first else { return false }
        guard let screen = NSScreen.main else { return false }

        let visible = screen.visibleFrame
        let primaryMaxY = primaryScreen.frame.maxY

        let cellW = visible.width / 3
        let cellH = visible.height / 3

        // Calculate frame based on half position
        let cocoaX: CGFloat
        let cocoaY: CGFloat
        let width: CGFloat
        let height: CGFloat

        switch position {
        // Horizontal halves (2/3 width × 1/3 height)
        case .topLeftHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + 2 * cellH
            width = 2 * cellW
            height = cellH
        case .topRightHalf:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y + 2 * cellH
            width = 2 * cellW
            height = cellH
        case .middleLeftHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + cellH
            width = 2 * cellW
            height = cellH
        case .middleRightHalf:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y + cellH
            width = 2 * cellW
            height = cellH
        case .bottomLeftHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = 2 * cellW
            height = cellH
        case .bottomRightHalf:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y
            width = 2 * cellW
            height = cellH

        // Vertical halves (1/3 width × 2/3 height)
        case .leftTopHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + cellH
            width = cellW
            height = 2 * cellH
        case .leftBottomHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = cellW
            height = 2 * cellH
        case .centerTopHalf:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y + cellH
            width = cellW
            height = 2 * cellH
        case .centerBottomHalf:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y
            width = cellW
            height = 2 * cellH
        case .rightTopHalf:
            cocoaX = visible.origin.x + 2 * cellW
            cocoaY = visible.origin.y + cellH
            width = cellW
            height = 2 * cellH
        case .rightBottomHalf:
            cocoaX = visible.origin.x + 2 * cellW
            cocoaY = visible.origin.y
            width = cellW
            height = 2 * cellH

        // Corner quarters (2/3 width × 2/3 height)
        case .topLeftQuarter:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + cellH
            width = 2 * cellW
            height = 2 * cellH
        case .topRightQuarter:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y + cellH
            width = 2 * cellW
            height = 2 * cellH
        case .bottomLeftQuarter:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = 2 * cellW
            height = 2 * cellH
        case .bottomRightQuarter:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y
            width = 2 * cellW
            height = 2 * cellH

        // True halves (1/2 screen)
        case .leftHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = visible.width / 2
            height = visible.height
        case .rightHalf:
            cocoaX = visible.origin.x + visible.width / 2
            cocoaY = visible.origin.y
            width = visible.width / 2
            height = visible.height
        case .topHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + visible.height / 2
            width = visible.width
            height = visible.height / 2
        case .bottomHalf:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = visible.width
            height = visible.height / 2

        // True corners (1/4 screen - 1/2 × 1/2)
        case .topLeftCorner:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + visible.height / 2
            width = visible.width / 2
            height = visible.height / 2
        case .topRightCorner:
            cocoaX = visible.origin.x + visible.width / 2
            cocoaY = visible.origin.y + visible.height / 2
            width = visible.width / 2
            height = visible.height / 2
        case .bottomLeftCorner:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = visible.width / 2
            height = visible.height / 2
        case .bottomRightCorner:
            cocoaX = visible.origin.x + visible.width / 2
            cocoaY = visible.origin.y
            width = visible.width / 2
            height = visible.height / 2

        // Full screen and center half
        case .fullScreen:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = visible.width
            height = visible.height
        case .centerHalf:
            cocoaX = visible.origin.x + visible.width / 4
            cocoaY = visible.origin.y + visible.height / 4
            width = visible.width / 2
            height = visible.height / 2

        // Third columns (1/3 width × full height)
        case .leftThird:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = cellW
            height = visible.height
        case .centerThird:
            cocoaX = visible.origin.x + cellW
            cocoaY = visible.origin.y
            width = cellW
            height = visible.height
        case .rightThird:
            cocoaX = visible.origin.x + 2 * cellW
            cocoaY = visible.origin.y
            width = cellW
            height = visible.height

        // Third rows (full width × 1/3 height)
        case .topThird:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + 2 * cellH
            width = visible.width
            height = cellH
        case .middleThird:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y + cellH
            width = visible.width
            height = cellH
        case .bottomThird:
            cocoaX = visible.origin.x
            cocoaY = visible.origin.y
            width = visible.width
            height = cellH
        }

        // Convert to AX coordinates
        let axX = cocoaX
        let axY = primaryMaxY - cocoaY - height

        // Rectangle's 3-step approach
        var size = CGSize(width: width, height: height)
        var pos = CGPoint(x: axX, y: axY)

        guard let sizeValue = AXValueCreate(.cgSize, &size),
              let posValue = AXValueCreate(.cgPoint, &pos) else { return false }

        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

        return true
    }

    /// Open System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

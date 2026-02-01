import AppKit
import SwiftUI

/// Controls the menu bar icon and dropdown menu
class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var accessibilityMenuItem: NSMenuItem?

    override init() {
        super.init()
        setupStatusBar()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use a grid icon
            if let image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "SplitView") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "⊞"
            }
        }

        setupMenu()
    }

    private func setupMenu() {
        menu = NSMenu()
        menu?.delegate = self

        // Title
        let titleItem = NSMenuItem(title: "SplitView - Window Snapper", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu?.addItem(titleItem)

        menu?.addItem(NSMenuItem.separator())

        // Accessibility status (stored for dynamic updates)
        accessibilityMenuItem = NSMenuItem(title: "", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityMenuItem?.target = self
        updateAccessibilityStatus()
        menu?.addItem(accessibilityMenuItem!)

        menu?.addItem(NSMenuItem.separator())

        // Grid positions header
        let gridHeader = NSMenuItem(title: "Snap Window To:", action: nil, keyEquivalent: "")
        gridHeader.isEnabled = false
        menu?.addItem(gridHeader)

        // Add grid position items in visual order (top to bottom)
        let topRow: [GridPosition] = [.topLeft, .topCenter, .topRight]
        let midRow: [GridPosition] = [.middleLeft, .center, .middleRight]
        let bottomRow: [GridPosition] = [.bottomLeft, .bottomCenter, .bottomRight]

        for position in topRow {
            addGridMenuItem(for: position)
        }
        for position in midRow {
            addGridMenuItem(for: position)
        }
        for position in bottomRow {
            addGridMenuItem(for: position)
        }

        menu?.addItem(NSMenuItem.separator())

        // Accessibility preferences
        let prefsItem = NSMenuItem(title: "Open Accessibility Settings...", action: #selector(openAccessibilitySettings), keyEquivalent: ",")
        prefsItem.target = self
        menu?.addItem(prefsItem)

        menu?.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit SplitView", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func addGridMenuItem(for position: GridPosition) {
        let item = NSMenuItem(
            title: "  \(position.displayName)",
            action: #selector(snapToPosition(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.tag = position.rawValue

        // Add keyboard shortcut indicator
        let shortcutString = "  \(position.shortcutDescription)"
        let attributed = NSMutableAttributedString(string: "\(position.displayName)")
        attributed.append(NSAttributedString(
            string: shortcutString,
            attributes: [.foregroundColor: NSColor.secondaryLabelColor]
        ))
        item.attributedTitle = attributed

        menu?.addItem(item)
    }

    private func updateAccessibilityStatus() {
        guard let menuItem = accessibilityMenuItem else { return }
        if WindowManager.shared.hasAccessibilityPermission {
            menuItem.title = "✓ Accessibility: Enabled"
        } else {
            menuItem.title = "⚠ Accessibility: Not Enabled (Click to fix)"
        }
    }

    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh accessibility status every time menu opens
        updateAccessibilityStatus()
    }

    @objc private func snapToPosition(_ sender: NSMenuItem) {
        guard let position = GridPosition(rawValue: sender.tag) else { return }
        let success = WindowManager.shared.moveWindow(to: position)
        if !success {
            NSSound.beep()
        }
    }

    @objc private func openAccessibilitySettings() {
        WindowManager.shared.openAccessibilityPreferences()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

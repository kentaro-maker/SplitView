import SwiftUI
import AppKit

@main
struct SplitViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (we're a menu bar app)
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar
        statusBarController = StatusBarController()

        // Check and request accessibility permissions
        if !WindowManager.shared.hasAccessibilityPermission {
            showAccessibilityAlert()
        }

        // Start keyboard shortcuts
        KeyboardShortcutManager.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        KeyboardShortcutManager.shared.stop()
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "SplitView needs accessibility permission to move windows and listen for keyboard shortcuts.\n\nPlease grant permission in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            WindowManager.shared.requestAccessibilityPermission()
        }
    }
}

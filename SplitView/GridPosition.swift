import Foundation
import CoreGraphics

/// Represents the 9 positions in a 3x3 grid, mapped to numpad layout
enum GridPosition: Int, CaseIterable {
    case bottomLeft = 1
    case bottomCenter = 2
    case bottomRight = 3
    case middleLeft = 4
    case center = 5
    case middleRight = 6
    case topLeft = 7
    case topCenter = 8
    case topRight = 9

    /// Calculate the frame for this grid position on the given screen
    /// - Parameter visibleFrame: The visible frame of the screen (excludes menu bar and Dock)
    func frame(for visibleFrame: CGRect) -> CGRect {
        let cellWidth = visibleFrame.width / 3
        let cellHeight = visibleFrame.height / 3

        let column: CGFloat
        let row: CGFloat

        switch self {
        case .bottomLeft, .middleLeft, .topLeft:
            column = 0
        case .bottomCenter, .center, .topCenter:
            column = 1
        case .bottomRight, .middleRight, .topRight:
            column = 2
        }

        // Note: macOS coordinate system has origin at bottom-left
        // So row 0 = bottom, row 2 = top
        switch self {
        case .bottomLeft, .bottomCenter, .bottomRight:
            row = 0
        case .middleLeft, .center, .middleRight:
            row = 1
        case .topLeft, .topCenter, .topRight:
            row = 2
        }

        return CGRect(
            x: visibleFrame.origin.x + column * cellWidth,
            y: visibleFrame.origin.y + row * cellHeight,
            width: cellWidth,
            height: cellHeight
        )
    }

    /// Human-readable name for the position
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .middleLeft: return "Middle Left"
        case .center: return "Center"
        case .middleRight: return "Middle Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }

    /// Keyboard shortcut description
    var shortcutDescription: String {
        return "⌃⌥\(self.rawValue)"
    }
}

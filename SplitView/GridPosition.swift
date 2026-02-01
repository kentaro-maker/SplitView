import Foundation
import CoreGraphics

/// Represents half-size positions (2 cells combined)
enum HalfPosition: String, CaseIterable {
    // Horizontal halves (1/2 width × 1/3 height)
    case topLeftHalf = "78"      // 7+8
    case topRightHalf = "89"     // 8+9
    case middleLeftHalf = "45"   // 4+5
    case middleRightHalf = "56"  // 5+6
    case bottomLeftHalf = "12"   // 1+2
    case bottomRightHalf = "23"  // 2+3

    // Vertical halves (1/3 width × 2/3 height)
    case leftTopHalf = "74"      // 7+4
    case leftBottomHalf = "41"   // 4+1
    case centerTopHalf = "85"    // 8+5
    case centerBottomHalf = "52" // 5+2
    case rightTopHalf = "96"     // 9+6
    case rightBottomHalf = "63"  // 6+3

    // Corner quarters (2/3 width × 2/3 height)
    case topLeftQuarter = "75"      // 7+5
    case topRightQuarter = "95"     // 9+5
    case bottomLeftQuarter = "15"   // 1+5
    case bottomRightQuarter = "35"  // 3+5

    // True halves (1/2 screen)
    case leftHalf = "71"            // 7+1
    case rightHalf = "93"           // 9+3
    case topHalf = "79"             // 7+9
    case bottomHalf = "13"          // 1+3

    // Corners (1/2 × 1/2) - for half mode single key
    case topLeftCorner = "7c"
    case topRightCorner = "9c"
    case bottomLeftCorner = "1c"
    case bottomRightCorner = "3c"

    // Full screen and center
    case fullScreen = "5f"          // 5 first press
    case centerHalf = "5c"          // 5 second press (1/2 × 1/2 centered)

    // Third columns (1/3 width × full height)
    case leftThird = "71t"          // 7+1 without Option
    case centerThird = "82t"        // 8+2 without Option
    case rightThird = "93t"         // 9+3 without Option

    // Third rows (full width × 1/3 height)
    case topThird = "79t"           // 7+9 without Option
    case middleThird = "46t"        // 4+6 without Option
    case bottomThird = "13t"        // 1+3 without Option

    /// Human-readable name
    var displayName: String {
        switch self {
        case .topLeftHalf: return "Top Left Half"
        case .topRightHalf: return "Top Right Half"
        case .middleLeftHalf: return "Middle Left Half"
        case .middleRightHalf: return "Middle Right Half"
        case .bottomLeftHalf: return "Bottom Left Half"
        case .bottomRightHalf: return "Bottom Right Half"
        case .leftTopHalf: return "Left Top Half"
        case .leftBottomHalf: return "Left Bottom Half"
        case .centerTopHalf: return "Center Top Half"
        case .centerBottomHalf: return "Center Bottom Half"
        case .rightTopHalf: return "Right Top Half"
        case .rightBottomHalf: return "Right Bottom Half"
        case .topLeftQuarter: return "Top Left Quarter"
        case .topRightQuarter: return "Top Right Quarter"
        case .bottomLeftQuarter: return "Bottom Left Quarter"
        case .bottomRightQuarter: return "Bottom Right Quarter"
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .topLeftCorner: return "Top Left Corner"
        case .topRightCorner: return "Top Right Corner"
        case .bottomLeftCorner: return "Bottom Left Corner"
        case .bottomRightCorner: return "Bottom Right Corner"
        case .fullScreen: return "Full Screen"
        case .centerHalf: return "Center Half"
        case .leftThird: return "Left Third"
        case .centerThird: return "Center Third"
        case .rightThird: return "Right Third"
        case .topThird: return "Top Third"
        case .middleThird: return "Middle Third"
        case .bottomThird: return "Bottom Third"
        }
    }

    /// Check if this is a horizontal half (wide)
    var isHorizontal: Bool {
        switch self {
        case .topLeftHalf, .topRightHalf, .middleLeftHalf, .middleRightHalf, .bottomLeftHalf, .bottomRightHalf:
            return true
        default:
            return false
        }
    }

    /// Check if this is a corner quarter (2/3 × 2/3)
    var isQuarter: Bool {
        switch self {
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter:
            return true
        default:
            return false
        }
    }
}

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

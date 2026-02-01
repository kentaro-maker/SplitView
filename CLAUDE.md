# CLAUDE.md

This file helps Claude Code (AI coding assistant) understand this codebase.

## Build Commands

```bash
# Build the app
xcodebuild -project SplitView.xcodeproj -scheme SplitView -configuration Debug build

# Clean and rebuild
xcodebuild -project SplitView.xcodeproj -scheme SplitView clean build

# Open in Xcode
open SplitView.xcodeproj
```

## Architecture

SplitView is a macOS menu bar app that snaps windows to a 3x3 grid using keyboard shortcuts.

### Program Flow

```mermaid
sequenceDiagram
    participant User
    participant CGEvent as CGEvent Tap
    participant KSM as KeyboardShortcutManager
    participant WM as WindowManager
    participant AX as AXUIElement API

    User->>CGEvent: Press Ctrl+Option+7
    CGEvent->>KSM: keyDown event
    KSM->>KSM: Check modifiers (Ctrl+Option)
    KSM->>KSM: Map keyCode 89 → GridPosition.topLeft
    KSM->>WM: moveWindow(to: .topLeft)
    WM->>WM: getFrontmostWindow()
    Note over WM: If frontmost is self,<br/>use lastActiveApp
    WM->>WM: Calculate coordinates
    Note over WM: cocoaY → axY conversion:<br/>axY = maxY - cocoaY - height
    WM->>AX: setSize (step 1)
    WM->>AX: setPosition (step 2)
    WM->>AX: setSize (step 3)
    AX-->>User: Window snaps to position
```

### Component Diagram

```mermaid
graph TD
    A[SplitViewApp] --> B[StatusBarController]
    A --> C[KeyboardShortcutManager]
    A --> D[WindowManager]

    B --> E[NSStatusItem Menu]
    B --> D

    C --> F[CGEvent Tap]
    C --> G[GridPosition]
    C --> D

    D --> H[AXUIElement API]
    D --> I[NSScreen]

    G --> |"1-9 → positions"| D

    style A fill:#e1f5fe
    style D fill:#fff3e0
    style H fill:#fce4ec
```

### Core Components

- **SplitViewApp.swift**: App entry point with AppDelegate. Sets activation policy to `.accessory` (menu bar only, no dock icon). Initializes StatusBarController and KeyboardShortcutManager.

- **WindowManager.swift**: Handles window positioning using macOS Accessibility API (AXUIElement). Tracks last active app to handle shortcuts correctly when SplitView becomes frontmost. Uses CGDisplay API for coordinate calculations.

- **KeyboardShortcutManager.swift**: Registers global hotkeys via CGEvent tap. Requires accessibility permissions. Handles two modes:
  - **Normal mode** (Ctrl+Fn or Ctrl+Option): 1/3 grid positions
  - **Half mode** (add Option key): 1/2 screen positions
  - Multi-key combos for columns, rows, and advanced positions

- **GridPosition.swift**: Two enums:
  - `GridPosition`: 9 positions for 1/3 × 1/3 grid (numpad layout: 7=top-left, etc.)
  - `HalfPosition`: Extended positions including halves, thirds, corners, and full screen

- **StatusBarController.swift**: NSStatusItem menu bar icon and dropdown menu. Shows accessibility permission status, grid position shortcuts, and quit option. Implements NSMenuDelegate to refresh status on menu open.

### Shortcut Modes

| Shortcut | Single Key | Multi-Key |
|----------|------------|-----------|
| Ctrl+Fn+num | 1/3 × 1/3 grid | 1/3 column/row (full height/width) |
| Ctrl+Fn+Option+num | 1/2 corners/edges | 2/3 positions, 1/4 corners |

**Key detection logic** (in `handleEvent`):

| Step | Check | Action |
|------|-------|--------|
| 1 | `hasOption` | Determines Normal vs Half mode |
| 2 | `heldKeys.count >= 2` | Check combo dictionaries |
| 3 | Single key | Use `numberToPosition` or `numberToHalfPosition` |

**Combo dictionaries:**

| Dictionary | When | Result |
|------------|------|--------|
| `thirdPositionCombos` | Without Option | 1/3 columns (7+1), rows (7+9) |
| `halfPositionCombos` | With Option | 2/3 (7+8), 1/2 (7+1), 1/4 (1+7+9) |
| `numberToPosition` | Normal single key | 1/3 × 1/3 grid |
| `numberToHalfPosition` | Half single key | 1/2 positions |

### Coordinate Systems

macOS uses two coordinate systems:
- **Cocoa (NSScreen)**: Origin at bottom-left, Y increases upward
- **Accessibility API**: Origin at top-left, Y increases downward

**Conversion formula:**
```swift
axY = primaryScreen.frame.maxY - cocoaY - windowHeight
```

**Why this works:**
- `primaryScreen.frame.maxY` = top of primary screen in Cocoa coords (e.g., 1080)
- Subtracting `cocoaY` flips the Y axis
- Subtracting `windowHeight` because AX position is top-left corner of window

**Setting window frame (Rectangle's 3-step approach):**
```swift
// 1. Set size first
AXUIElementSetAttributeValue(window, kAXSizeAttribute, size)
// 2. Set position
AXUIElementSetAttributeValue(window, kAXPositionAttribute, position)
// 3. Set size again (position change may affect allowed size)
AXUIElementSetAttributeValue(window, kAXSizeAttribute, size)
```

This handles macOS enforcing display-appropriate sizes when windows move between positions.

### Permissions

App requires:
- **Accessibility**: For moving/resizing windows via AXUIElement
- Add app to System Settings → Privacy & Security → Accessibility

Info.plist includes `LSUIElement=true` (menu bar app) and `NSAccessibilityUsageDescription`.

## Development Notes

### Current State (2026-02-01)
- App is fully functional with two modes (Normal 1/3 and Half 1/2)
- Published to GitHub: https://github.com/kentaro-maker/SplitView
- Core concept: numpad position = screen position (intuitive)

### Key Design Decisions
- Trigger on keyDown (instant response, no lag)
- Option key toggles between 1/3 and 1/2 modes
- Multi-key combos for columns/rows (7+1 = left column)
- Key 5 with Option toggles full screen ↔ centered half

### Potential Future Ideas
- [ ] Preferences window for custom shortcuts
- [ ] Multiple monitor support improvements
- [ ] Animation when snapping windows
- [ ] Drag-to-edge snapping
- [ ] Keyboard shortcut hints overlay

### Known Issues
- None currently reported

### How to Continue Development
1. Read this file to understand the architecture
2. Check README.md for user-facing features
3. Main files to modify:
   - `KeyboardShortcutManager.swift` - shortcut logic
   - `WindowManager.swift` - window positioning
   - `GridPosition.swift` - position enums

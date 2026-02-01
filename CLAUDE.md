# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

The app has two modes controlled by the Option key:

```
┌─────────────────────────────────────────────────────────────┐
│ Normal Mode (Ctrl+Fn or Ctrl+Option, no extra Option)       │
├─────────────────────────────────────────────────────────────┤
│ Single key:  1/3 × 1/3 grid cell                            │
│ Combo 7+1:   Left third (1/3 width × full height)           │
│ Combo 8+2:   Center third (1/3 width × full height)         │
│ Combo 9+3:   Right third (1/3 width × full height)          │
│ Combo 7+9:   Top third (full width × 1/3 height)            │
│ Combo 4+6:   Middle third (full width × 1/3 height)         │
│ Combo 1+3:   Bottom third (full width × 1/3 height)         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Half Mode (Ctrl+Fn+Option)                                  │
├─────────────────────────────────────────────────────────────┤
│ Single key:  1/2 positions (corners, edges)                 │
│ Key 5:       Toggle full screen / centered half             │
│ Combos:      2/3 positions, 1/4 corners                     │
└─────────────────────────────────────────────────────────────┘
```

**Key detection logic** (in `handleEvent`):
1. Check if Option is pressed → determines mode
2. Check for multi-key combos first (2+ keys held)
3. Fall back to single-key action

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

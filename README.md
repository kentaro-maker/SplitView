# SplitView

A lightweight macOS menu bar app for window tiling with intuitive numpad shortcuts.

![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Numpad = Screen position** - Press 7 → top-left, Press 3 → bottom-right. Intuitive.
- **Two sizes** - Normal (1/3 screen) or add Option key for half (1/2 screen)
- **Lightweight** - Native Swift, menu bar app, no dock icon

## Keyboard Shortcuts

### Ctrl + Fn + number (Normal Mode)

**Single key → 1/3 × 1/3 grid:**
```
┌──────────┬──────────┬──────────┐
│    7     │    8     │    9     │
│ 1/3×1/3  │ 1/3×1/3  │ 1/3×1/3  │
│ top-left │ top-ctr  │ top-right│
├──────────┼──────────┼──────────┤
│    4     │    5     │    6     │
│ 1/3×1/3  │ 1/3×1/3  │ 1/3×1/3  │
│ mid-left │  center  │ mid-right│
├──────────┼──────────┼──────────┤
│    1     │    2     │    3     │
│ 1/3×1/3  │ 1/3×1/3  │ 1/3×1/3  │
│ bot-left │ bot-ctr  │ bot-right│
└──────────┴──────────┴──────────┘
```

**Multi-key → 1/3 columns & rows:**
```
┌──────────┬──────────┬──────────┐
│   7+1    │   8+2    │   9+3    │
│ 1/3×full │ 1/3×full │ 1/3×full │
│  left    │  center  │  right   │
│  column  │  column  │  column  │
└──────────┴──────────┴──────────┘

┌─────────────────────────────────┐
│             7+9                 │
│         full × 1/3              │
│          top row                │
├─────────────────────────────────┤
│             4+6                 │
│         full × 1/3              │
│        middle row               │
├─────────────────────────────────┤
│             1+3                 │
│         full × 1/3              │
│        bottom row               │
└─────────────────────────────────┘
```

### Ctrl + Fn + Option + number (Half Mode)

**Single key → 1/2 positions:**
```
┌──────────┬──────────┬──────────┐
│    7     │    8     │    9     │
│ 1/2×1/2  │ full×1/2 │ 1/2×1/2  │
│ corner   │   top    │  corner  │
├──────────┼──────────┼──────────┤
│    4     │    5     │    6     │
│ 1/2×full │ toggle:  │ 1/2×full │
│  left    │full/half │  right   │
├──────────┼──────────┼──────────┤
│    1     │    2     │    3     │
│ 1/2×1/2  │ full×1/2 │ 1/2×1/2  │
│ corner   │  bottom  │  corner  │
└──────────┴──────────┴──────────┘
```

**Multi-key → 2/3 positions:**
```
┌─────────────────────┬──────────┐
│        7+8          │   8+9    │
│      2/3×1/3        │ 2/3×1/3  │
│     top-left        │top-right │
├─────────────────────┼──────────┤
│        4+5          │   5+6    │
│      2/3×1/3        │ 2/3×1/3  │
│     mid-left        │mid-right │
├─────────────────────┼──────────┤
│        1+2          │   2+3    │
│      2/3×1/3        │ 2/3×1/3  │
│     bot-left        │bot-right │
└─────────────────────┴──────────┘

┌──────────┬──────────┐
│   7+4    │   7+1    │
│ 1/3×2/3  │ 1/2×full │
│ left-top │   left   │
├──────────┼──────────┤
│   4+1    │   9+3    │
│ 1/3×2/3  │ 1/2×full │
│ left-bot │  right   │
└──────────┴──────────┘
```

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/kentaro-maker/SplitView.git
   cd SplitView
   ```

2. Open in Xcode:
   ```bash
   open SplitView.xcodeproj
   ```

3. Build and run (`Cmd + R`)

4. Grant **Accessibility permission** when prompted:
   - System Settings → Privacy & Security → Accessibility
   - Enable SplitView

### Using xcodebuild

```bash
xcodebuild -project SplitView.xcodeproj -scheme SplitView -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/SplitView-*/Build/Products/Release/`

## Usage

1. Launch SplitView - grid icon appears in menu bar
2. Focus any window
3. Press `Ctrl + Fn + [1-9]` → window snaps to that position
4. Add `Option` for half-size positions

## Requirements

- macOS 12.0 (Monterey) or later
- Accessibility permission (required for window management)

## How It Works

SplitView uses macOS Accessibility API (`AXUIElement`) to move and resize windows. See [CLAUDE.md](CLAUDE.md) for technical details including:
- Coordinate system conversion (Cocoa ↔ Accessibility)
- Program flow diagrams
- Architecture overview

## Troubleshooting

### "No window found" error
- Make sure you click on a window before pressing the shortcut
- The target app must have a visible window

### Windows not snapping correctly
- Toggle Accessibility permission off/on in System Settings
- Restart the app after granting permission

### Shortcuts not working
- Check that no other app uses the same shortcuts
- Verify SplitView is running (grid icon in menu bar)

## License

MIT License - see [LICENSE](LICENSE)

## Acknowledgments

- Inspired by [Rectangle](https://github.com/rxhanson/Rectangle)
- Coordinate conversion based on [Swindler](https://github.com/tmandry/Swindler) research

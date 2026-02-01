# SplitView

A lightweight macOS menu bar app that snaps windows to a 3×3 grid using keyboard shortcuts.

![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **3×3 Grid Snapping** - Divide your screen into 9 equal sections (1/3 × 1/3)
- **Half-Screen Tiling** - Add Option key for 1/2 screen positions
- **Numpad Layout** - Intuitive keyboard shortcuts matching numpad positions
- **Menu Bar App** - Runs quietly in your menu bar, no dock icon
- **Lightweight** - Native Swift, no dependencies

## Keyboard Shortcuts

### Ctrl + Fn + number (Normal Mode)

| Keys | Result | Size |
|------|--------|------|
| **Single Key** |||
| 7 | Top-left | 1/3 × 1/3 |
| 8 | Top-center | 1/3 × 1/3 |
| 9 | Top-right | 1/3 × 1/3 |
| 4 | Middle-left | 1/3 × 1/3 |
| 5 | Center | 1/3 × 1/3 |
| 6 | Middle-right | 1/3 × 1/3 |
| 1 | Bottom-left | 1/3 × 1/3 |
| 2 | Bottom-center | 1/3 × 1/3 |
| 3 | Bottom-right | 1/3 × 1/3 |
| **Multi-Key** |||
| 7+1 | Left column | 1/3 × full |
| 8+2 | Center column | 1/3 × full |
| 9+3 | Right column | 1/3 × full |
| 7+9 | Top row | full × 1/3 |
| 4+6 | Middle row | full × 1/3 |
| 1+3 | Bottom row | full × 1/3 |

### Ctrl + Fn + Option + number (Half Mode)

| Keys | Result | Size |
|------|--------|------|
| **Single Key** |||
| 7 | Top-left corner | 1/2 × 1/2 |
| 8 | Top half | full × 1/2 |
| 9 | Top-right corner | 1/2 × 1/2 |
| 4 | Left half | 1/2 × full |
| 5 | Toggle: full ↔ center | full / 1/2 × 1/2 |
| 6 | Right half | 1/2 × full |
| 1 | Bottom-left corner | 1/2 × 1/2 |
| 2 | Bottom half | full × 1/2 |
| 3 | Bottom-right corner | 1/2 × 1/2 |
| **Multi-Key** |||
| 7+8 | Top-left | 2/3 × 1/3 |
| 8+9 | Top-right | 2/3 × 1/3 |
| 4+5 | Middle-left | 2/3 × 1/3 |
| 5+6 | Middle-right | 2/3 × 1/3 |
| 1+2 | Bottom-left | 2/3 × 1/3 |
| 2+3 | Bottom-right | 2/3 × 1/3 |
| 7+4 | Left-top | 1/3 × 2/3 |
| 4+1 | Left-bottom | 1/3 × 2/3 |
| 9+6 | Right-top | 1/3 × 2/3 |
| 6+3 | Right-bottom | 1/3 × 2/3 |
| 7+1 | Left half | 1/2 × full |
| 9+3 | Right half | 1/2 × full |
| 7+9 | Top half | full × 1/2 |
| 1+3 | Bottom half | full × 1/2 |
| 1+7+9 | Top-left corner | 1/4 screen |
| 3+7+9 | Top-right corner | 1/4 screen |
| 1+3+7 | Bottom-left corner | 1/4 screen |
| 1+3+9 | Bottom-right corner | 1/4 screen |

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SplitView.git
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

1. Launch SplitView - a grid icon appears in your menu bar
2. Click on any window you want to move
3. Press `Ctrl + Option + [1-9]` to snap to that grid position

### Menu Bar Options

Click the grid icon in the menu bar to:
- See all available shortcuts
- Check accessibility permission status
- Manually snap windows by clicking positions
- Quit the app

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

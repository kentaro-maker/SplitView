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

Use `Ctrl + Fn + [1-9]` or `Ctrl + Option + [1-9]` with numpad layout.

### Normal Mode (1/3 × 1/3 Grid)

`Ctrl + Fn + number` or `Ctrl + Option + number`:

```
┌─────────┬─────────┬─────────┐
│    7    │    8    │    9    │
│Top-Left │Top-Centr│Top-Right│
├─────────┼─────────┼─────────┤
│    4    │    5    │    6    │
│Mid-Left │ Center  │Mid-Right│
├─────────┼─────────┼─────────┤
│    1    │    2    │    3    │
│Bot-Left │Bot-Centr│Bot-Right│
└─────────┴─────────┴─────────┘
```

### Half Mode (1/2 Screen Positions)

Add **Option** key: `Ctrl + Fn + Option + number`:

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

**Note:** Key 5 in half mode toggles between full screen and centered half (1/2 × 1/2).

### Multi-Key Combos (Advanced)

Hold two adjacent keys for 2/3 positions:

| Keys | Position |
|------|----------|
| 7+8, 8+9 | Top 2/3 width |
| 4+5, 5+6 | Middle 2/3 width |
| 1+2, 2+3 | Bottom 2/3 width |
| 7+4, 4+1 | Left 2/3 height |
| 8+5, 5+2 | Center 2/3 height |
| 9+6, 6+3 | Right 2/3 height |
| 7+1, 9+3 | Left/Right half (full height) |
| 7+9, 1+3 | Top/Bottom half (full width) |

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

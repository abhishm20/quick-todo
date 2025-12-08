# QuickTodo

> A lightning-fast menubar todo app for macOS

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

<p align="center">
  <img src="docs/screenshot.png" alt="QuickTodo Screenshot" width="400">
</p>

## Features

- **Instant Access** - Global hotkey (⌘+Shift+T) opens your todos from anywhere
- **Full Keyboard Navigation** - Navigate, toggle, and delete without touching your mouse
- **Lightweight** - Native SwiftUI app, ~3MB bundle, ~20MB RAM
- **Distraction-Free** - Minimal UI that stays out of your way
- **Persistent** - Todos saved automatically to local JSON file

## Installation

### Download

Download the latest release from the [Releases](https://github.com/yourusername/QuickTodo/releases) page.

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/QuickTodo.git
   cd QuickTodo
   ```

2. Open in Xcode:
   ```bash
   open QuickTodo.xcodeproj
   ```

3. Build and run (⌘+R)

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building from source)

## Usage

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `⌘ + Shift + T` | Open/close QuickTodo |
| `↑` / `↓` | Navigate between items |
| `Space` or `Enter` | Toggle completion |
| `Delete` | Remove item (with animation) |
| `Escape` | Close popover |
| `Tab` | Move to next item |

### Quick Add

1. Press `⌘ + Shift + T` to open QuickTodo
2. Start typing immediately (input is auto-focused)
3. Press `Enter` to add the todo
4. Press `↓` to navigate to your list

### Workflow Tips

- **Quick capture**: The input field is always focused when you open the app
- **Batch complete**: Use arrow keys + Space to quickly check off multiple items
- **Clean delete**: Deleted items show strikethrough for 1.5s before removal

## Data Storage

Todos are stored as JSON at:
```
~/Library/Application Support/QuickTodo/todos.json
```

You can back up or sync this file using your preferred method (iCloud, Dropbox, git, etc.).

## Configuration

### Changing the Hotkey

Currently, the hotkey is set to `⌘ + Shift + T`. Custom hotkey configuration via preferences is planned for a future release.

To modify the default hotkey, edit `HotkeyManager.swift`:
```swift
static let `default` = KeyCombo(
    keyCode: UInt32(kVK_ANSI_T),  // Change key
    modifiers: UInt32(cmdKey | shiftKey)  // Change modifiers
)
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork and clone the repository
2. Open `QuickTodo.xcodeproj` in Xcode
3. Build and run

### Code Style

- Follow Swift API Design Guidelines
- Use `// MARK:` comments to organize code
- Add doc comments (`///`) for public APIs

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for technical details.

### Project Structure

```
QuickTodo/
├── QuickTodoApp.swift      # App entry, menubar setup
├── Models/
│   └── Todo.swift          # Todo data model
├── Views/
│   ├── ContentView.swift   # Main popover view
│   └── TodoRowView.swift   # Individual todo row
└── Services/
    ├── TodoStore.swift     # Data persistence
    └── HotkeyManager.swift # Global shortcuts
```

## Roadmap

- [ ] Custom hotkey preferences UI
- [ ] Multiple todo lists
- [ ] iCloud sync
- [ ] Due dates and reminders
- [ ] Dark/light mode toggle

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with SwiftUI and AppKit
- Inspired by the need for a fast, keyboard-driven todo app

---

<p align="center">
  Made with ☕ by the open source community
</p>

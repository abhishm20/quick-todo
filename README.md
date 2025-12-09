# QuickTodo

A lightning-fast menubar todo app for macOS.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Instant Access** - Global hotkey (default: ⌘⇧T) opens your todos from anywhere
- **Full Keyboard Navigation** - Navigate, toggle, and delete without touching your mouse
- **Multi-Select** - Use Shift+Arrow to select multiple items for batch deletion
- **Configurable** - Change hotkey and data location via Settings
- **Lightweight** - Native SwiftUI app, minimal resource usage
- **Persistent** - Todos saved automatically to local JSON file

## Installation

### Download

Download the latest DMG from the [Releases](https://github.com/abhishm20/quick-todo/releases) page.

**Important:** Since the app is not notarized with Apple, macOS may show "damaged" or "unidentified developer" warnings. To fix this, run in Terminal after mounting the DMG:

```bash
xattr -cr /Volumes/QuickTodo/QuickTodo.app
```

Or after copying to Applications:

```bash
xattr -cr /Applications/QuickTodo.app
```

### Build from Source

```bash
git clone https://github.com/abhishm20/quick-todo.git
cd quick-todo
open QuickTodo.xcodeproj
```

Then build and run with ⌘R in Xcode.

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for building from source)

## Usage

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `⌘⇧T` | Open/close QuickTodo (configurable) |
| `↑` / `↓` | Navigate between items |
| `Shift + ↑/↓` | Multi-select items |
| `Space` or `Enter` | Toggle completion |
| `Delete` or `Backspace` | Remove selected item(s) |
| `Escape` | Close popover |

### Quick Add

1. Press your hotkey to open QuickTodo
2. Start typing (input is auto-focused)
3. Press Enter to add
4. Use arrow keys to navigate your list

## Settings

Click the gear icon to access Settings:

- **Global Shortcut** - Click "Record" and press your preferred key combination
- **Data Location** - Change where todos.json is stored
- **Quit** - Exit the app

## Data Storage

Todos are stored as JSON at:
```
~/Library/Application Support/QuickTodo/todos.json
```

You can change this location in Settings, or sync the file via iCloud/Dropbox/git.

## Project Structure

```
quick-todo/
├── QuickTodo/                # Source files
│   ├── QuickTodoApp.swift    # App entry, menubar setup
│   ├── Models/
│   │   └── Todo.swift        # Todo data model
│   ├── Views/
│   │   ├── ContentView.swift # Main popover view
│   │   ├── TodoRowView.swift # Individual todo row
│   │   └── SettingsView.swift# Settings panel
│   └── Services/
│       ├── TodoStore.swift   # Data persistence
│       ├── HotkeyManager.swift # Global shortcuts
│       └── KeyboardHandler.swift # Keyboard navigation
├── QuickTodo.xcodeproj/
└── scripts/
```

## Contributing

Contributions welcome! Fork the repo and submit a PR.

## License

MIT License - see [LICENSE](LICENSE) for details.

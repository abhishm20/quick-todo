# QuickTodo - Claude Code Guidelines

## Project Overview

QuickTodo is a lightweight menubar todo app for macOS built with SwiftUI. It runs as a menubar-only application (no dock icon) and provides quick access via a global keyboard shortcut.

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI + AppKit (for menubar/popover)
- **Persistence**: JSON file storage
- **Global Hotkey**: Carbon APIs

## Key Files

- `QuickTodo/QuickTodoApp.swift` - App entry point and AppDelegate
- `QuickTodo/Views/ContentView.swift` - Main popover UI
- `QuickTodo/Views/SettingsView.swift` - Settings panel
- `QuickTodo/Services/TodoStore.swift` - Data persistence
- `QuickTodo/Services/HotkeyManager.swift` - Global shortcut handling

## Build Commands

```bash
# Build debug
xcodebuild -scheme QuickTodo -configuration Debug build

# Build release
xcodebuild -scheme QuickTodo -configuration Release build

# Build DMG (requires create-dmg)
./scripts/build-dmg.sh
```

## Versioning & Tagging

This project follows [Semantic Versioning](https://semver.org/). Current version: **v0.1.2**

### When to Bump Versions

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fixes, minor improvements | **PATCH** (0.0.X) | v0.1.2 → v0.1.3 |
| New features, backwards compatible | **MINOR** (0.X.0) | v0.1.3 → v0.2.0 |
| Breaking changes | **MAJOR** (X.0.0) | v0.2.0 → v1.0.0 |

### Tagging Process

After committing changes, always create and push a semver tag:

```bash
# Check current version
git tag --sort=-v:refname | head -1

# Create new tag (increment appropriately)
git tag vX.Y.Z

# Push with tags
git push origin main --tags
```

### Commit Message Guidelines

- Keep messages concise and descriptive
- Focus on what changed and why
- Do not include AI attribution in commits

## Code Style

- Follow Swift API Design Guidelines
- Use MARK comments to organize code sections
- Keep views modular with extracted subviews
- Use `@EnvironmentObject` for shared state

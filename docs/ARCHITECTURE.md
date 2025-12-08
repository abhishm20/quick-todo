# QuickTodo Architecture

This document describes the technical architecture of QuickTodo, a lightweight menubar todo app for macOS.

## Overview

QuickTodo is a native macOS application built with SwiftUI and AppKit. It runs as a menubar-only app (no dock icon) and uses a popover to display the todo list.

```
┌─────────────────────────────────────────────────────────┐
│                      macOS Menubar                       │
│  ┌──────┐                                               │
│  │  ☑️  │ ← NSStatusItem (menubar icon)                 │
│  └──┬───┘                                               │
│     │                                                    │
│     ▼                                                    │
│  ┌──────────────────────┐                               │
│  │     NSPopover        │                               │
│  │  ┌────────────────┐  │                               │
│  │  │  ContentView   │  │ ← SwiftUI View                │
│  │  │  (SwiftUI)     │  │                               │
│  │  └────────────────┘  │                               │
│  └──────────────────────┘                               │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
QuickTodo/
├── QuickTodoApp.swift          # App entry point, AppDelegate
├── Models/
│   └── Todo.swift              # Data model
├── Views/
│   ├── ContentView.swift       # Main popover content
│   └── TodoRowView.swift       # Individual todo row
└── Services/
    ├── TodoStore.swift         # Data management
    └── HotkeyManager.swift     # Global shortcuts
```

## Core Components

### 1. QuickTodoApp.swift

**Responsibilities:**
- App entry point using SwiftUI App lifecycle
- Bridges to AppDelegate for AppKit functionality

**Key Elements:**
- `@main` attribute for entry point
- `@NSApplicationDelegateAdaptor` for AppDelegate access

### 2. AppDelegate

**Responsibilities:**
- Creates and manages `NSStatusItem` (menubar icon)
- Creates and manages `NSPopover` (todo list container)
- Registers global hotkey
- Handles click events and popover toggling

**Lifecycle:**
```
applicationDidFinishLaunching
    ├── setupStatusItem()    → Creates menubar icon
    ├── setupPopover()       → Creates popover with SwiftUI content
    ├── setupHotkey()        → Registers global shortcut
    └── setupEventMonitor()  → Monitors for outside clicks
```

### 3. Todo Model

**Definition:**
```swift
struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var isDeleting: Bool  // Transient, not persisted
}
```

**Design Decisions:**
- `Identifiable` for SwiftUI list performance
- `Codable` for JSON persistence
- `isDeleting` excluded from `CodingKeys` (animation state only)

### 4. TodoStore

**Responsibilities:**
- Manages todo CRUD operations
- Persists data to JSON file
- Provides ObservableObject for SwiftUI binding

**Data Flow:**
```
User Action → TodoStore Method → @Published todos → SwiftUI Update
                    │
                    └── save() → JSON File
```

**File Location:**
```
~/Library/Application Support/QuickTodo/todos.json
```

**Thread Safety:**
- Uses `@MainActor` isolation
- All mutations happen on main thread

### 5. HotkeyManager

**Responsibilities:**
- Registers global keyboard shortcuts
- Triggers popover toggle on hotkey press

**Implementation:**
- Uses Carbon APIs (`RegisterEventHotKey`)
- Default: ⌘ + Shift + T
- Stores custom shortcuts in UserDefaults

**Event Flow:**
```
Key Press → Carbon Event Handler → HotkeyManager → AppDelegate.togglePopover()
```

### 6. ContentView

**Responsibilities:**
- Main popover content
- New todo input field
- Todo list display
- Keyboard navigation handling

**State Management:**
```swift
@EnvironmentObject var todoStore: TodoStore  // Shared data
@State var newTodoText: String               // Input field
@State var focusedIndex: Int                 // Navigation
@FocusState var isInputFocused: Bool         // Focus control
```

**Keyboard Handling:**
```
↑/↓    → Navigate focus
Enter  → Add todo (from input) or toggle (from list)
Space  → Toggle completion
Delete → Mark for deletion
Escape → Close popover
```

### 7. TodoRowView

**Responsibilities:**
- Display individual todo item
- Handle checkbox toggle
- Handle text editing
- Show deletion animation

**Visual States:**
- Normal: Primary text color
- Completed: Muted text, strikethrough
- Focused: Accent background highlight
- Deleting: Red strikethrough, fading out

## Data Flow

### Adding a Todo

```
1. User types in input field
2. User presses Enter
3. ContentView.addTodo() called
4. TodoStore.addTodo() creates Todo
5. @Published todos updated
6. SwiftUI re-renders list
7. TodoStore.save() writes JSON
```

### Toggling Completion

```
1. User presses Space on focused todo
2. ContentView.handleKeyPress() detects Space
3. TodoStore.toggleTodo(id:) called
4. Todo.isCompleted flipped
5. @Published triggers UI update
6. TodoStore.save() persists change
```

### Deleting a Todo

```
1. User presses Delete on focused todo
2. ContentView.handleKeyPress() detects Delete
3. TodoStore.deleteTodo(id:) called
4. Todo.isDeleting = true (triggers strikethrough)
5. After 1.5s delay:
   - withAnimation removes todo from array
   - SwiftUI animates removal
6. TodoStore.save() persists change
```

## Performance Considerations

### Memory
- Minimal footprint (~20MB)
- No persistent background processes
- Popover content deallocated when closed (if memory pressure)

### Storage
- Single JSON file
- Atomic writes prevent corruption
- No database overhead

### Startup
- Immediate menubar icon display
- Async data loading doesn't block UI
- Hotkey registration is synchronous

## Extension Points

### Adding New Features

**Multiple Lists:**
- Add `listId` to Todo model
- Create `List` model
- Update TodoStore to filter by list

**Cloud Sync:**
- Abstract storage in TodoStore
- Add CloudKit or custom sync service
- Handle conflict resolution

**Custom Themes:**
- Extract colors to theme configuration
- Add theme preference to UserDefaults
- Apply via environment values

### Accessibility

Current support:
- VoiceOver labels on checkboxes
- Keyboard-only navigation
- System accent color usage

Future improvements:
- Full VoiceOver announcement of changes
- Reduce motion option
- High contrast mode

## Dependencies

**Required:**
- SwiftUI (UI framework)
- AppKit (menubar, popover)
- Carbon (global hotkeys)

**No external dependencies** - keeps the app lightweight and reduces maintenance burden.

## Build Configuration

**Info.plist Keys:**
- `LSUIElement = true` - No dock icon
- `LSMinimumSystemVersion` - macOS 13.0
- `LSApplicationCategoryType` - Productivity

**Entitlements:**
- May require Accessibility permission for global hotkeys
- No sandbox restrictions needed for basic functionality

---

## Questions?

Open an issue for architecture-related questions or suggestions.

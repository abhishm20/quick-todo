//
//  ContentView.swift
//  QuickTodo
//
//  Main popover content view
//

import SwiftUI
import AppKit
import Carbon

// MARK: - Content View

/// The main view displayed in the menubar popover.
///
/// Contains the new todo input field at the top and the scrollable
/// list of todos below. Handles keyboard navigation and focus management.
struct ContentView: View {

    // MARK: - Properties

    @EnvironmentObject private var todoStore: TodoStore
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var keyboardHandler = KeyboardHandler()

    /// Text for new todo input
    @State private var newTodoText = ""

    /// Whether settings sheet is shown
    @State private var showSettings = false

    /// Whether the input field should be focused
    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // New todo input
            newTodoInputView

            Divider()

            // Todo list
            if todoStore.todos.isEmpty {
                emptyStateView
            } else {
                todoListView
            }
        }
        .frame(width: 320, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            setupKeyboardHandler()
            keyboardHandler.startMonitoring()
            isInputFocused = true
        }
        .onDisappear {
            keyboardHandler.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusNewTodoField)) { _ in
            keyboardHandler.resetFocus()
            isInputFocused = true
        }
        .onChange(of: keyboardHandler.focusedIndex) { _, newIndex in
            isInputFocused = (newIndex == -1)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(todoStore)
                .environmentObject(hotkeyManager)
        }
    }

    // MARK: - Subviews

    /// App header with title and settings
    private var headerView: some View {
        HStack {
            Text("QuickTodo")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            Text(formatKeyCombo(hotkeyManager.keyCombo))
                .font(.caption)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// Text field for adding new todos
    private var newTodoInputView: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 16))

            TextField("Add a todo...", text: $newTodoText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isInputFocused)
                .onSubmit(addTodo)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(keyboardHandler.focusedIndex == -1 ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    /// Empty state when no todos exist
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No todos yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Type above and press Enter")
                .font(.caption)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Scrollable list of todos
    private var todoListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(todoStore.todos.enumerated()), id: \.element.id) { index, todo in
                        TodoRowView(
                            todo: binding(for: todo),
                            isFocused: keyboardHandler.focusedIndex == index,
                            isSelected: keyboardHandler.selectedIndices.contains(index),
                            onToggle: { todoStore.toggleTodo(id: todo.id) },
                            onDelete: { todoStore.deleteTodo(id: todo.id) },
                            onTextChange: { newText in
                                todoStore.updateTodo(id: todo.id, text: newText)
                            }
                        )
                        .id(todo.id)
                    }
                }
            }
            .onChange(of: keyboardHandler.focusedIndex) { _, newIndex in
                if newIndex >= 0 && newIndex < todoStore.todos.count {
                    withAnimation {
                        proxy.scrollTo(todoStore.todos[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Setup

    /// Configures the keyboard handler callbacks
    private func setupKeyboardHandler() {
        keyboardHandler.getTodosCount = { [todoStore] in
            todoStore.todos.count
        }

        keyboardHandler.onToggle = { [todoStore] index in
            guard index >= 0 && index < todoStore.todos.count else { return }
            todoStore.toggleTodo(id: todoStore.todos[index].id)
        }

        keyboardHandler.onDelete = { [todoStore] indices in
            let idsToDelete = indices.compactMap { index -> UUID? in
                guard index >= 0 && index < todoStore.todos.count else { return nil }
                return todoStore.todos[index].id
            }
            for id in idsToDelete {
                todoStore.deleteTodo(id: id)
            }
        }

        keyboardHandler.onClose = {
            NSApp.keyWindow?.close()
        }
    }

    // MARK: - Helpers

    /// Creates a binding for a todo item
    private func binding(for todo: Todo) -> Binding<Todo> {
        guard let index = todoStore.todos.firstIndex(where: { $0.id == todo.id }) else {
            return .constant(todo)
        }
        return $todoStore.todos[index]
    }

    /// Adds a new todo from the input field
    private func addTodo() {
        let text = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        todoStore.addTodo(text: text)
        newTodoText = ""
    }

    /// Formats a KeyCombo as a human-readable string
    private func formatKeyCombo(_ combo: HotkeyManager.KeyCombo) -> String {
        var result = ""

        // Modifiers
        if combo.modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if combo.modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if combo.modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if combo.modifiers & UInt32(cmdKey) != 0 { result += "⌘" }

        // Key
        result += keyCodeToString(combo.keyCode)

        return result
    }

    /// Converts a key code to its string representation
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "↩", 48: "⇥", 51: "⌫", 53: "⎋",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
            97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
            103: "F11", 111: "F12",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]

        return keyMap[keyCode] ?? "?"
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}

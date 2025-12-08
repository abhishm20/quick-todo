//
//  TodoStore.swift
//  QuickTodo
//
//  Manages todo persistence and state
//

import Foundation
import SwiftUI

// MARK: - Todo Store

/// Manages todo data persistence and provides an observable interface for SwiftUI.
///
/// Todos are persisted as JSON to:
/// `~/Library/Application Support/QuickTodo/todos.json`
///
/// Changes are automatically saved after each modification.
///
/// ## Usage
/// ```swift
/// @StateObject private var store = TodoStore()
/// // or as environment object
/// .environmentObject(TodoStore())
/// ```
@MainActor
final class TodoStore: ObservableObject {

    // MARK: - Properties

    /// The list of todos (automatically saved on change)
    @Published var todos: [Todo] = [] {
        didSet {
            save()
        }
    }

    /// File URL for todo persistence
    private var fileURL: URL

    /// UserDefaults key for custom storage path
    private static let storagePathKey = "customStoragePath"

    /// Default storage directory
    private static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("QuickTodo", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("todos.json")
    }

    /// Current file URL (read-only access for UI)
    var currentFileURL: URL {
        fileURL
    }

    // MARK: - Initialization

    /// Creates a new TodoStore and loads existing todos from disk.
    init() {
        // Load custom path or use default
        if let customPath = UserDefaults.standard.string(forKey: Self.storagePathKey) {
            self.fileURL = URL(fileURLWithPath: customPath)
        } else {
            self.fileURL = Self.defaultFileURL
        }

        // Load existing todos
        load()
    }

    // MARK: - Public Methods

    /// Adds a new todo with the given text.
    ///
    /// - Parameter text: The todo text content
    /// - Returns: The created todo
    @discardableResult
    func addTodo(text: String) -> Todo {
        let todo = Todo(text: text)
        todos.insert(todo, at: 0)
        return todo
    }

    /// Toggles the completion state of a todo.
    ///
    /// - Parameter id: The todo's unique identifier
    func toggleTodo(id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isCompleted.toggle()
    }

    /// Updates the text of a todo.
    ///
    /// - Parameters:
    ///   - id: The todo's unique identifier
    ///   - text: The new text content
    func updateTodo(id: UUID, text: String) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].text = text
    }

    /// Marks a todo for deletion and removes it after animation delay.
    ///
    /// The todo will show strikethrough styling for 1.5 seconds before removal.
    ///
    /// - Parameter id: The todo's unique identifier
    func deleteTodo(id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }

        // Mark as deleting (triggers strikethrough animation)
        todos[index].isDeleting = true

        // Remove after animation delay
        let todoId = id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            withAnimation(.easeOut(duration: 0.3)) {
                self.todos.removeAll { $0.id == todoId }
            }
        }
    }

    /// Immediately removes a todo without animation.
    ///
    /// - Parameter id: The todo's unique identifier
    func removeTodo(id: UUID) {
        todos.removeAll { $0.id == id }
    }

    /// Updates the storage path for todos.
    ///
    /// This will:
    /// 1. Save current todos to the new location
    /// 2. Update the stored path preference
    ///
    /// - Parameter url: The new file URL for storage
    func updateStoragePath(_ url: URL) {
        // Save current todos to new location
        let oldURL = fileURL
        fileURL = url

        // Save to new location
        save()

        // Store preference
        UserDefaults.standard.set(url.path, forKey: Self.storagePathKey)

        // Optionally: keep old file or delete it
        // For safety, we keep the old file
        print("QuickTodo: Moved storage from \(oldURL.path) to \(url.path)")
    }

    /// Resets storage path to the default location.
    func resetToDefaultPath() {
        let newURL = Self.defaultFileURL

        // If already at default, do nothing
        guard fileURL != newURL else { return }

        // Save to default location
        fileURL = newURL
        save()

        // Clear preference
        UserDefaults.standard.removeObject(forKey: Self.storagePathKey)

        print("QuickTodo: Reset storage to default: \(newURL.path)")
    }

    // MARK: - Private Methods

    /// Loads todos from the JSON file.
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            todos = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Todo].self, from: data)
            todos = decoded
        } catch {
            print("QuickTodo: Failed to load todos: \(error)")
            todos = []
        }
    }

    /// Saves todos to the JSON file.
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(todos)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("QuickTodo: Failed to save todos: \(error)")
        }
    }
}

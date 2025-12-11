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

    /// The list of todos
    @Published var todos: [Todo] = [] {
        didSet {
            scheduleSave()
        }
    }

    /// Last save error (nil if save succeeded)
    @Published private(set) var saveError: Error?

    /// File URL for todo persistence
    private var fileURL: URL

    /// Task for debounced saving
    private var saveTask: Task<Void, Never>?

    /// Debounce interval for saves (500ms)
    private static let saveDebounceNanoseconds: UInt64 = 500_000_000

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

        // Prevent double deletion
        guard !todos[index].isDeleting else { return }

        // Mark as deleting (triggers strikethrough animation)
        todos[index].isDeleting = true

        // Remove after animation delay
        let todoId = id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            withAnimation(.easeOut(duration: 0.3)) {
                // Only remove if still exists and still marked for deletion
                if let idx = self.todos.firstIndex(where: { $0.id == todoId && $0.isDeleting }) {
                    self.todos.remove(at: idx)
                }
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
        let oldURL = fileURL
        fileURL = url

        // Save to new location immediately (bypass debounce)
        Task {
            await saveImmediately()
        }

        // Store preference
        UserDefaults.standard.set(url.path, forKey: Self.storagePathKey)

        // For safety, we keep the old file
        print("QuickTodo: Moved storage from \(oldURL.path) to \(url.path)")
    }

    /// Resets storage path to the default location.
    func resetToDefaultPath() {
        let newURL = Self.defaultFileURL

        // If already at default, do nothing
        guard fileURL != newURL else { return }

        fileURL = newURL

        // Save to default location immediately (bypass debounce)
        Task {
            await saveImmediately()
        }

        // Clear preference
        UserDefaults.standard.removeObject(forKey: Self.storagePathKey)

        print("QuickTodo: Reset storage to default: \(newURL.path)")
    }

    // MARK: - Private Methods

    /// Loads todos from the JSON file.
    private func load() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            todos = []
            return
        }

        // Perform file I/O synchronously during init (acceptable for small files)
        // For larger datasets, consider async loading with a loading state
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Todo].self, from: data)
            todos = decoded
        } catch {
            print("QuickTodo: Failed to load todos: \(error)")
            todos = []
        }
    }

    /// Schedules a debounced save operation.
    ///
    /// Multiple rapid changes will be batched into a single save
    /// after the debounce interval (500ms) has passed.
    private func scheduleSave() {
        // Cancel any pending save
        saveTask?.cancel()

        // Schedule a new save after debounce interval
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.saveDebounceNanoseconds)
            } catch {
                // Task was cancelled, don't save
                return
            }

            guard !Task.isCancelled else { return }
            await self?.performSave()
        }
    }

    /// Performs the actual save to disk.
    ///
    /// Runs on a background thread to avoid blocking the UI.
    private func performSave() async {
        let todosToSave = todos
        let url = fileURL

        // Perform file I/O on background thread
        do {
            try await Task.detached(priority: .utility) {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(todosToSave)
                try data.write(to: url, options: .atomic)
            }.value

            // Clear any previous error on success
            saveError = nil
        } catch {
            print("QuickTodo: Failed to save todos: \(error)")
            saveError = error
        }
    }

    /// Forces an immediate save, bypassing debounce.
    ///
    /// Use this when you need to ensure data is persisted immediately,
    /// such as before changing storage paths.
    func saveImmediately() async {
        saveTask?.cancel()
        await performSave()
    }
}

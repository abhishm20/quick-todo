//
//  Todo.swift
//  QuickTodo
//
//  Data model for todo items
//

import Foundation

// MARK: - Todo Model

/// Represents a single todo item.
///
/// Todos are uniquely identified by their `id` and can be serialized
/// to JSON for persistence. The `isDeleting` flag is used for
/// the deletion animation (strikethrough before removal).
///
/// ## Example
/// ```swift
/// let todo = Todo(text: "Buy groceries")
/// ```
struct Todo: Identifiable, Codable, Equatable {

    // MARK: - Properties

    /// Unique identifier for the todo
    let id: UUID

    /// The todo text content
    var text: String

    /// Whether the todo has been completed
    var isCompleted: Bool

    /// Transient flag for deletion animation (not persisted)
    var isDeleting: Bool

    // MARK: - Coding Keys

    /// Custom coding keys to exclude `isDeleting` from persistence
    private enum CodingKeys: String, CodingKey {
        case id, text, isCompleted
    }

    // MARK: - Initialization

    /// Creates a new todo item.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - text: The todo text content
    ///   - isCompleted: Whether the todo is completed (defaults to false)
    ///   - isDeleting: Whether the todo is being deleted (defaults to false)
    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        isDeleting: Bool = false
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.isDeleting = isDeleting
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        isDeleting = false // Always false when loading
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isCompleted, forKey: .isCompleted)
        // isDeleting is not encoded
    }
}

// MARK: - Convenience Extensions

extension Todo {
    /// Creates a new empty todo for the input field
    static var empty: Todo {
        Todo(text: "")
    }
}

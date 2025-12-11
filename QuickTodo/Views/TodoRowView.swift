//
//  TodoRowView.swift
//  QuickTodo
//
//  Individual todo item row
//

import SwiftUI

// MARK: - Todo Row Actions

/// Consolidates all callback actions for a todo row.
///
/// Using a struct instead of multiple closure parameters improves readability
/// and makes the TodoRowView initializer more concise.
struct TodoRowActions {
    /// Action when checkbox is toggled
    var onToggle: () -> Void = {}

    /// Action when todo should be deleted
    var onDelete: () -> Void = {}

    /// Action when text changes
    var onTextChange: (String) -> Void = { _ in }

    /// Callback when edit mode should start
    var onStartEdit: () -> Void = {}

    /// Callback when edit mode ends
    var onEndEdit: () -> Void = {}
}

// MARK: - Todo Row View

/// Displays a single todo item with checkbox and text.
///
/// Features:
/// - Toggle checkbox on click or keyboard
/// - Editable text field
/// - Strikethrough animation when deleting
/// - Visual feedback when focused
struct TodoRowView: View {

    // MARK: - Properties

    /// The todo item to display
    @Binding var todo: Todo

    /// Whether this row is currently focused
    let isFocused: Bool

    /// Whether this row is selected (multi-select)
    var isSelected: Bool = false

    /// Whether this row is in edit mode (controlled by parent)
    var isEditMode: Bool = false

    /// All callback actions for this row
    var actions: TodoRowActions = TodoRowActions()

    /// Local text state for editing
    @State private var editedText: String = ""

    /// Whether the text field is being edited
    @FocusState private var isEditing: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            checkboxView

            // Text
            textView

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundView)
        .contentShape(Rectangle())
        .onAppear {
            editedText = todo.text
        }
        .onChange(of: todo.text) { _, newValue in
            if editedText != newValue {
                editedText = newValue
            }
        }
        .opacity(todo.isDeleting ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: todo.isDeleting)
    }

    // MARK: - Subviews

    /// Checkbox toggle button
    private var checkboxView: some View {
        Button(action: actions.onToggle) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(todo.isCompleted ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(todo.isCompleted ? "Completed" : "Not completed")
    }

    /// Todo text display/edit field
    private var textView: some View {
        Group {
            if isEditMode {
                TextField("", text: $editedText)
                    .textFieldStyle(.plain)
                    .focused($isEditing)
                    .onSubmit {
                        actions.onTextChange(editedText)
                        actions.onEndEdit()
                    }
                    .onChange(of: isEditing) { _, editing in
                        if !editing {
                            actions.onTextChange(editedText)
                            actions.onEndEdit()
                        }
                    }
                    .onAppear {
                        isEditing = true
                    }
            } else {
                Text(todo.text)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        actions.onStartEdit()
                    }
            }
        }
        .font(.body)
        .foregroundColor(textColor)
        .strikethrough(todo.isCompleted || todo.isDeleting, color: strikethroughColor)
    }

    /// Background highlight for focused/selected state
    private var backgroundView: some View {
        Group {
            if isFocused {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
            } else if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.08))
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Computed Properties

    /// Text color based on completion/deletion state
    private var textColor: Color {
        if todo.isDeleting {
            return .red.opacity(0.7)
        } else if todo.isCompleted {
            return .secondary
        } else {
            return .primary
        }
    }

    /// Strikethrough color based on state
    private var strikethroughColor: Color {
        todo.isDeleting ? .red : .secondary
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TodoRowView(
            todo: .constant(Todo(text: "Normal todo")),
            isFocused: false
        )

        TodoRowView(
            todo: .constant(Todo(text: "Selected todo")),
            isFocused: false,
            isSelected: true
        )

        TodoRowView(
            todo: .constant(Todo(text: "Focused todo")),
            isFocused: true,
            isSelected: true
        )

        TodoRowView(
            todo: .constant(Todo(text: "Completed todo", isCompleted: true)),
            isFocused: false
        )

        TodoRowView(
            todo: .constant(Todo(text: "This is a very long todo item that should wrap to multiple lines when displayed in the todo list view")),
            isFocused: false
        )
    }
    .frame(width: 320)
    .padding()
}

//
//  TodoRowView.swift
//  QuickTodo
//
//  Individual todo item row
//

import SwiftUI

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

    /// Action when checkbox is toggled
    let onToggle: () -> Void

    /// Action when todo should be deleted
    let onDelete: () -> Void

    /// Action when text changes
    let onTextChange: (String) -> Void

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
        Button(action: onToggle) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(todo.isCompleted ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(todo.isCompleted ? "Completed" : "Not completed")
    }

    /// Todo text display/edit field
    private var textView: some View {
        TextField("", text: $editedText)
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundColor(textColor)
            .strikethrough(todo.isCompleted || todo.isDeleting, color: strikethroughColor)
            .focused($isEditing)
            .onSubmit {
                onTextChange(editedText)
            }
            .onChange(of: isEditing) { _, editing in
                if !editing {
                    onTextChange(editedText)
                }
            }
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
            isFocused: false,
            isSelected: false,
            onToggle: {},
            onDelete: {},
            onTextChange: { _ in }
        )

        TodoRowView(
            todo: .constant(Todo(text: "Selected todo")),
            isFocused: false,
            isSelected: true,
            onToggle: {},
            onDelete: {},
            onTextChange: { _ in }
        )

        TodoRowView(
            todo: .constant(Todo(text: "Focused todo")),
            isFocused: true,
            isSelected: true,
            onToggle: {},
            onDelete: {},
            onTextChange: { _ in }
        )

        TodoRowView(
            todo: .constant(Todo(text: "Completed todo", isCompleted: true)),
            isFocused: false,
            isSelected: false,
            onToggle: {},
            onDelete: {},
            onTextChange: { _ in }
        )
    }
    .frame(width: 320)
    .padding()
}
